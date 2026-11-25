import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../network/token_store.dart';
import '../notifications/push_notification_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/claims/data/datasources/claim_remote_data_source.dart';
import '../../features/claims/data/repositories/claim_repository_impl.dart';
import '../../features/claims/domain/repositories/claim_repository.dart';
import '../../features/claims/presentation/bloc/claims_bloc.dart';
import '../../features/items/data/datasources/item_remote_data_source.dart';
import '../../features/items/data/repositories/item_repository_impl.dart';
import '../../features/items/domain/repositories/item_repository.dart';
import '../../features/items/presentation/bloc/items_bloc.dart';
import '../../features/messages/data/datasources/message_remote_data_source.dart';
import '../../features/messages/data/repositories/message_repository_impl.dart';
import '../../features/messages/domain/repositories/message_repository.dart';
import '../../features/messages/presentation/bloc/messages_bloc.dart';
import '../../features/moderation/data/datasources/moderation_remote_data_source.dart';
import '../../features/moderation/data/repositories/moderation_repository_impl.dart';
import '../../features/moderation/domain/repositories/moderation_repository.dart';
import '../../features/moderation/presentation/bloc/moderation_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  const secureStorage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  getIt.registerSingleton<TokenStore>(TokenStore(secureStorage));
  getIt.registerSingleton<Dio>(createDioClient(getIt<TokenStore>()));
  getIt.registerLazySingleton(() => PushNotificationService(getIt<Dio>()));

  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(getIt()));

  getIt.registerLazySingleton(() => ItemRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<ItemRepository>(
    () => ItemRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerFactory(() => ItemsBloc(getIt()));

  getIt.registerLazySingleton(() => ClaimRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<ClaimRepository>(
    () => ClaimRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => ClaimsBloc(getIt()));

  getIt.registerLazySingleton(() => MessageRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => MessagesBloc(getIt()));

  getIt.registerLazySingleton(() => ModerationRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<ModerationRepository>(
    () => ModerationRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => ModerationBloc(getIt()));
}
