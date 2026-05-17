import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_model.dart';
import '../../../core/utils/mock_database.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Persisted auth state — restored from SharedPreferences on startup.
final authStateProvider = StateProvider<UserModel?>((ref) {
  return MockDatabase.instance.getUser();
});

final currentUserModelProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider);
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserModelProvider)?.role;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    ref: ref,
  );
});

// ─── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  const AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required Ref ref,
  })  : _auth = auth,
        _firestore = firestore,
        _ref = ref;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Ref _ref;

  Future<UserModel> signIn(String email, String password) async {
    // 1. Try Firebase Auth first
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user;
      try {
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get()
            .timeout(const Duration(seconds: 3));

        if (doc.exists) {
          user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        } else {
          final isOwner = _isOwnerEmail(email);
          user = UserModel(
            id: credential.user!.uid,
            email: email,
            name: credential.user!.displayName ?? email.split('@').first,
            role: isOwner ? UserRole.owner : UserRole.customer,
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(user.id)
              .set(user.toJson())
              .timeout(const Duration(seconds: 2));
        }
      } catch (_) {
        final isOwner = _isOwnerEmail(email);
        user = UserModel(
          id: credential.user!.uid,
          email: email,
          name: credential.user!.displayName ?? email.split('@').first,
          role: isOwner ? UserRole.owner : UserRole.customer,
          createdAt: DateTime.now(),
        );
      }

      _ref.read(authStateProvider.notifier).state = user;
      await MockDatabase.instance.saveUser(user);
      return user;
    } catch (_) {}

    // 2. Try local SignedUp users database (offline/mock mode)
    final users = MockDatabase.instance.getSignedUpUsers();
    if (users.containsKey(email.toLowerCase().trim())) {
      final user = users[email.toLowerCase().trim()]!;
      _ref.read(authStateProvider.notifier).state = user;
      await MockDatabase.instance.saveUser(user);
      return user;
    }

    // 3. Demo accounts fallback
    if (email.trim() == 'muneeb@itu.com' || email.trim() == 'owner@nomnom.com') {
      final user = UserModel(
        id: 'demo_owner_1',
        email: email.trim(),
        name: 'Muneeb Ahmed',
        role: UserRole.owner,
        phone: '+92 321 9876543',
        createdAt: DateTime(2024),
      );
      _ref.read(authStateProvider.notifier).state = user;
      await MockDatabase.instance.saveUser(user);
      return user;
    }

    if (email.trim() == 'subhani@itu.com' || email.trim() == 'customer@nomnom.com') {
      final user = UserModel(
        id: 'demo_customer_1',
        email: email.trim(),
        name: 'Ali Subhani',
        role: UserRole.customer,
        phone: '+92 300 1234567',
        addresses: ['House 12, Block C, DHA Lahore'],
        createdAt: DateTime(2024),
      );
      _ref.read(authStateProvider.notifier).state = user;
      await MockDatabase.instance.saveUser(user);
      return user;
    }

    throw Exception('Account not found. Please sign up first.');
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final trimmedEmail = email.toLowerCase().trim();

    // Try Firebase Auth
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = UserModel(
        id: credential.user!.uid,
        email: trimmedEmail,
        name: name.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection('users')
            .doc(user.id)
            .set(user.toJson())
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      _ref.read(authStateProvider.notifier).state = user;
      await MockDatabase.instance.saveUser(user);
      return user;
    } catch (_) {}

    // Offline fallback — save to local DB
    // Check if already registered
    final existingUsers = MockDatabase.instance.getSignedUpUsers();
    if (existingUsers.containsKey(trimmedEmail)) {
      throw Exception('Email already registered. Please sign in.');
    }

    final user = UserModel(
      id: 'local_${trimmedEmail.hashCode.abs()}',
      email: trimmedEmail,
      name: name.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await MockDatabase.instance.saveUser(user);
    _ref.read(authStateProvider.notifier).state = user;
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    // Update local state immediately
    _ref.read(authStateProvider.notifier).state = user;
    await MockDatabase.instance.saveUser(user);

    // Try Firestore in background
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson())
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _ref.read(authStateProvider.notifier).state = null;
    await MockDatabase.instance.clearUser();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {}
  }

  bool _isOwnerEmail(String email) {
    final lower = email.toLowerCase();
    return lower.contains('muneeb') ||
        lower.contains('owner') ||
        lower.contains('restaurant') ||
        lower.contains('admin');
  }
}
