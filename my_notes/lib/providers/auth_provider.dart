import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_notes/services/firebase_services.dart';
import 'package:my_notes/services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final LocalStorageService _localStorage = LocalStorageService();
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StreamSubscription<User?>? _authSub;

  AuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((User? authUser) {
      _user = authUser;
      // Her auth değişiminde yüklemeyi kapatıp UI'ı bilgilendiriyoruz
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
    try {
      await _firebaseServices.signInWithEmailAndPassword(
        email,
        password,
      );
      // _user güncellemesini stream yapacak
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
    try {
      await _firebaseServices.signUpWithEmailAndPassword(
        email,
        password,
      );
      // _user güncellemesini stream yapacak
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
    try {
      await _firebaseServices.signOut();
      await _localStorage.clearAllNotes();
      // _user güncellemesini stream yapacak
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  void clearErrorMessage() {
    _errorMessage = "";
    notifyListeners();
  }
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Geçersiz e‑posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı devre dışı.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E‑posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e‑posta zaten kullanımda.';
      case 'weak-password':
        return 'Şifre yeterince güçlü değil.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izinli değil.';
      case 'network-request-failed':
        return 'Ağ hatası. Lütfen bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'requires-recent-login':
        return 'Bu işlem için yakın zamanda tekrar giriş yapmanız gerekir.';
      default:
        return e.message ?? 'Bir hata oluştu.';
    }
  }
  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
