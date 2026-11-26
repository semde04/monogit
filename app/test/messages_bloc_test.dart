import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/messages/presentation/bloc/messages_bloc.dart';

import 'fakes/fake_repositories.dart';

void main() {
  blocTest<MessagesBloc, MessagesState>(
    'charge l’historique de la conversation',
    build: () => MessagesBloc(FakeMessageRepository()),
    act: (bloc) => bloc.add(const MessagesRequested('c1')),
    verify: (bloc) {
      expect(bloc.state.messages, [testMessage]);
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.claimId, 'c1');
    },
  );

  blocTest<MessagesBloc, MessagesState>(
    'signale une erreur si la conversation est inaccessible',
    build: () =>
        MessagesBloc(FakeMessageRepository(messagesResult: const Err(failure))),
    act: (bloc) => bloc.add(const MessagesRequested('c1')),
    verify: (bloc) => expect(bloc.state.failure, failure),
  );

  blocTest<MessagesBloc, MessagesState>(
    'ignore un message vide',
    build: () => MessagesBloc(FakeMessageRepository()),
    act: (bloc) => bloc.add(const MessageSent('c1', '   ')),
    verify: (bloc) {
      expect(bloc.state.sending, isFalse);
      expect(bloc.state.messages, isEmpty);
    },
  );

  blocTest<MessagesBloc, MessagesState>(
    'affiche l’erreur après un envoi refusé',
    build: () =>
        MessagesBloc(FakeMessageRepository(sentResult: const Err(failure))),
    act: (bloc) => bloc.add(const MessageSent('c1', 'Bonjour')),
    verify: (bloc) {
      expect(bloc.state.sending, isFalse);
      expect(bloc.state.failure, failure);
    },
  );
}
