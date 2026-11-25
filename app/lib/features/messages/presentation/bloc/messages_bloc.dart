import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';

sealed class MessagesEvent extends Equatable {
  const MessagesEvent();
  @override
  List<Object?> get props => [];
}

final class MessagesRequested extends MessagesEvent {
  const MessagesRequested(this.claimId);
  final String claimId;
  @override
  List<Object?> get props => [claimId];
}

final class MessageSent extends MessagesEvent {
  const MessageSent(this.claimId, this.text);
  final String claimId, text;
  @override
  List<Object?> get props => [claimId, text];
}

class MessagesState extends Equatable {
  const MessagesState({
    this.claimId,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.failure,
  });
  final String? claimId;
  final List<ChatMessage> messages;
  final bool loading, sending;
  final Failure? failure;
  MessagesState copyWith({
    String? claimId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    Failure? failure,
    bool clearFailure = false,
  }) => MessagesState(
    claimId: claimId ?? this.claimId,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    failure: clearFailure ? null : failure ?? this.failure,
  );
  @override
  List<Object?> get props => [claimId, messages, loading, sending, failure];
}

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  MessagesBloc(MessageRepository repository)
    : _getMessages = GetMessages(repository),
      _sendMessage = SendMessage(repository),
      super(const MessagesState()) {
    on<MessagesRequested>(_load);
    on<MessageSent>(_send);
  }
  final GetMessages _getMessages;
  final SendMessage _sendMessage;
  Future<void> _load(
    MessagesRequested event,
    Emitter<MessagesState> emit,
  ) async {
    emit(
      state.copyWith(claimId: event.claimId, loading: true, clearFailure: true),
    );
    final result = await _getMessages(event.claimId);
    result.fold(
      (messages) => emit(state.copyWith(messages: messages, loading: false)),
      (failure) => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _send(MessageSent event, Emitter<MessagesState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    emit(state.copyWith(sending: true, clearFailure: true));
    final result = await _sendMessage(event.claimId, text);
    await result.fold<Future<void>>(
      (_) async {
        final refreshed = await _getMessages(event.claimId);
        refreshed.fold(
          (messages) =>
              emit(state.copyWith(messages: messages, sending: false)),
          (failure) => emit(state.copyWith(sending: false, failure: failure)),
        );
      },
      (failure) async => emit(state.copyWith(sending: false, failure: failure)),
    );
  }
}
