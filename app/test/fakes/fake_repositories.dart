import 'package:lostfound_app/core/error/failures.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/auth/domain/entities/app_user.dart';
import 'package:lostfound_app/features/auth/domain/entities/auth_session.dart';
import 'package:lostfound_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lostfound_app/features/claims/domain/entities/claim.dart';
import 'package:lostfound_app/features/claims/domain/repositories/claim_repository.dart';
import 'package:lostfound_app/features/items/domain/entities/item.dart';
import 'package:lostfound_app/features/items/domain/repositories/item_repository.dart';
import 'package:lostfound_app/features/messages/domain/entities/chat_message.dart';
import 'package:lostfound_app/features/messages/domain/repositories/message_repository.dart';
import 'package:lostfound_app/features/moderation/domain/entities/admin_overview.dart';
import 'package:lostfound_app/features/moderation/domain/repositories/moderation_repository.dart';

const testUser = AppUser(id: 'u1', name: 'Ada', email: 'ada@univ.fr');
const testSession = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  user: testUser,
);
const failure = ServerFailure('Erreur serveur', code: 'SERVER_ERROR');

final testItem = Item(
  id: 'i1',
  title: 'Sac',
  description: 'Trouvé en amphi',
  category: 'BAGS',
  location: 'Amphi C',
  type: 'FOUND',
  ownerId: 'u1',
  createdAt: DateTime(2026),
);

final testClaim = Claim(
  id: 'c1',
  itemId: 'i1',
  itemTitle: 'Sac',
  claimantId: 'u2',
  claimantName: 'Bob',
  status: 'pending',
  createdAt: DateTime(2026),
);

final testMessage = ChatMessage(
  id: 'm1',
  senderId: 'u2',
  senderName: 'Bob',
  text: 'Bonjour',
  createdAt: DateTime(2026),
);

final testOverview = AdminOverview(
  userCount: 1,
  itemCount: 1,
  claimCount: 1,
  pendingClaimCount: 1,
  users: const [
    AdminUserSummary(
      id: 'u1',
      name: 'Ada',
      email: 'ada@univ.fr',
      matricule: 'A1',
      role: 'user',
    ),
  ],
  items: [
    AdminItemSummary(
      id: 'i1',
      title: 'Sac',
      description: 'Trouvé en amphi',
      location: 'Amphi C',
      type: 'FOUND',
      ownerName: 'Ada',
      ownerMatricule: 'A1',
      isRemoved: false,
    ),
  ],
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.currentResult,
    this.loginResult,
    this.registerResult,
  });

  Result<AppUser>? currentResult;
  Result<AuthSession>? loginResult;
  Result<AuthSession>? registerResult;
  int logoutCalls = 0;

  @override
  Future<Result<AppUser>> currentUser() async =>
      currentResult ?? const Ok<AppUser>(testUser);

  @override
  Future<Result<AuthSession>> login(String email, String password) async =>
      loginResult ?? const Ok<AuthSession>(testSession);

  @override
  Future<Result<AuthSession>> register(
    String name,
    String email,
    String matricule,
    String password,
  ) async => registerResult ?? const Ok<AuthSession>(testSession);

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class FakeItemRepository implements ItemRepository {
  FakeItemRepository({
    this.itemsResult,
    this.itemResult,
    this.closeResult,
    this.createResult,
    this.cached = const [],
  });

  Result<List<Item>>? itemsResult;
  Result<Item>? itemResult;
  Result<Item>? closeResult;
  Result<Item>? createResult;
  List<Item> cached;

  @override
  Future<List<Item>> cachedItems() async => cached;

  @override
  Future<Result<List<Item>>> getItems({
    String? search,
    String? category,
    String? type,
  }) async => itemsResult ?? Ok<List<Item>>([testItem]);

  @override
  Future<Result<Item>> getItem(String id) async =>
      itemResult ?? Ok<Item>(testItem);

  @override
  Future<Result<Item>> createItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type,
    String? proofQuestion,
    String? imageData,
  }) async => createResult ?? Ok<Item>(testItem);

  @override
  Future<Result<Item>> closeItem(String id) async =>
      closeResult ?? Ok<Item>(testItem.copyWith(isClosed: true));
}

class FakeClaimRepository implements ClaimRepository {
  FakeClaimRepository({
    this.claimsResult,
    this.createdResult,
    this.statusResult,
    this.confirmResult,
  });

  Result<List<Claim>>? claimsResult;
  Result<Claim>? createdResult;
  Result<Claim>? statusResult;
  Result<Claim>? confirmResult;

  @override
  Future<Result<List<Claim>>> getClaims() async =>
      claimsResult ?? Ok<List<Claim>>([testClaim]);

  @override
  Future<Result<Claim>> createClaim(String itemId, String proofAnswer) async =>
      createdResult ?? Ok<Claim>(testClaim);

  @override
  Future<Result<Claim>> updateStatus(String claimId, String status) async =>
      statusResult ?? Ok<Claim>(testClaim.copyWith(status: status));

  @override
  Future<Result<Claim>> confirmReturn(String claimId) async =>
      confirmResult ?? Ok<Claim>(testClaim.copyWith(status: 'returned'));
}

class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository({this.messagesResult, this.sentResult});

  Result<List<ChatMessage>>? messagesResult;
  Result<ChatMessage>? sentResult;

  @override
  Future<Result<List<ChatMessage>>> getMessages(String claimId) async =>
      messagesResult ?? Ok<List<ChatMessage>>([testMessage]);

  @override
  Future<Result<ChatMessage>> send(String claimId, String text) async =>
      sentResult ?? Ok<ChatMessage>(testMessage);
}

class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({this.overviewResult, this.moderationResult});

  Result<AdminOverview>? overviewResult;
  Result<void>? moderationResult;

  @override
  Future<Result<AdminOverview>> getOverview() async =>
      overviewResult ?? Ok<AdminOverview>(testOverview);

  @override
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  }) async => moderationResult ?? const Ok<void>(null);
}
