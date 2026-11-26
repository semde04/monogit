import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/messages_bloc.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.claimId});
  final String claimId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MessagesBloc>()..add(MessagesRequested(claimId)),
    child: _ChatView(claimId: claimId),
  );
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.claimId});
  final String claimId;
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  String? _lastError;
  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<MessagesBloc>().add(MessagesRequested(widget.claimId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conversation privée'),
          Text(
            'Échange lié à une réclamation',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: BlocConsumer<MessagesBloc, MessagesState>(
            listenWhen: (a, b) =>
                a.failure != b.failure && b.failure != null ||
                a.messages.length != b.messages.length,
            listener: (context, state) {
              final message = state.failure?.message;
              if (message != null && message != _lastError) {
                _lastError = message;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              }
              if (message == null) _lastError = null;
              if (state.messages.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final nearBottom =
                      !_scroll.hasClients ||
                      _scroll.position.pixels >=
                          _scroll.position.maxScrollExtent - 120;
                  if (nearBottom && _scroll.hasClients) {
                    _scroll.animateTo(
                      _scroll.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
            builder: (context, state) {
              if (state.loading && state.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.messages.isEmpty) {
                return const Center(
                  child: Text('Démarrez la conversation avec un message.'),
                );
              }
              final currentUser = context.read<AuthBloc>().state.user?.id;
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  final mine = message.senderId == currentUser;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .78,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xff236b5d) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                message.senderName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff236b5d),
                                ),
                              ),
                            ),
                          Text(
                            message.text,
                            style: TextStyle(
                              color: mine ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 10,
                              color: mine ? Colors.white70 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message…',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<MessagesBloc, MessagesState>(
                  builder: (context, state) => IconButton.filled(
                    onPressed: state.sending
                        ? null
                        : () {
                            final text = _text.text;
                            if (text.trim().isNotEmpty) {
                              context.read<MessagesBloc>().add(
                                MessageSent(widget.claimId, text),
                              );
                              _text.clear();
                            }
                          },
                    icon: state.sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
