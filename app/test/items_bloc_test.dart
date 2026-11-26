import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/items/presentation/bloc/items_bloc.dart';

import 'fakes/fake_repositories.dart';

void main() {
  blocTest<ItemsBloc, ItemsState>(
    'affiche le cache puis la liste réseau',
    build: () => ItemsBloc(FakeItemRepository(cached: [testItem])),
    act: (bloc) => bloc.add(const ItemsRequested()),
    verify: (bloc) {
      expect(bloc.state.items, [testItem]);
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.failure, isNull);
    },
  );

  blocTest<ItemsBloc, ItemsState>(
    'expose une erreur quand la liste échoue',
    build: () => ItemsBloc(FakeItemRepository(itemsResult: const Err(failure))),
    act: (bloc) => bloc.add(const ItemsRequested()),
    verify: (bloc) {
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.failure, failure);
    },
  );

  blocTest<ItemsBloc, ItemsState>(
    'annule la clôture optimiste si le serveur refuse',
    build: () => ItemsBloc(
      FakeItemRepository(cached: [testItem], closeResult: const Err(failure)),
    ),
    act: (bloc) {
      bloc.add(const ItemsRequested());
      bloc.add(const ItemClosed('i1'));
    },
    verify: (bloc) {
      expect(bloc.state.items.single.isClosed, isFalse);
      expect(bloc.state.failure, failure);
    },
  );

  blocTest<ItemsBloc, ItemsState>(
    'la recherche est débouncée avant de recharger',
    build: () => ItemsBloc(FakeItemRepository()),
    act: (bloc) => bloc.add(const ItemSearchChanged('sac')),
    wait: const Duration(milliseconds: 600),
    verify: (bloc) {
      expect(bloc.state.search, 'sac');
      expect(bloc.state.loading, isFalse);
    },
  );
}
