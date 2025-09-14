import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_notes/models/note_model.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NoteModel> _notes = [];
  List<NoteModel> get notes => _notes;

  // Basit retry mekanizması
  Future<T> _retryOperation<T>(Future<T> Function() operation, String operationName) async {
    int maxRetries = 3;
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final errorString = e.toString().toLowerCase();
        
        // Retry edilebilir hatalar
        if (errorString.contains('unavailable') || 
            errorString.contains('timeout') || 
            errorString.contains('deadline_exceeded') ||
            errorString.contains('internal') ||
            errorString.contains('network')) {
          
          if (attempt < maxRetries) {
            final delay = Duration(seconds: attempt * 2); // 2, 4, 6 saniye
            debugPrint("$operationName failed (attempt $attempt/$maxRetries), retrying in ${delay.inSeconds}s: $e");
            await Future.delayed(delay);
            continue;
          }
        }
        
        // Retry edilemeyen hatalar veya son deneme
        debugPrint("$operationName failed after $attempt attempts: $e");
        rethrow;
      }
    }
    
    throw Exception("$operationName failed after $maxRetries attempts");
  }

  Future<User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint("Error getting current user: ${e.toString()}");
      throw Exception(e);
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } catch (e) {
      debugPrint("Error signing in with email and password: ${e.toString()}");
      throw Exception(e);
    }
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } catch (e) {
      debugPrint("Error signing up with email and password: ${e.toString()}");
      throw Exception(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: ${e.toString()}");
      throw Exception(e);
    }
  }

  Future<void> addNote(NoteModel note) async {
    return _retryOperation(() async {
      // Kullanıcının giriş yapmış olduğunu kontrol et
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final now = DateTime.now().toUtc();
      final data = {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'isPinned': note.isPinned,
        'userId': user.uid,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Firebase'de benzersiz bir ID oluştur
      final docRef = _firestore.collection('notes').doc(note.id.toString());
      await docRef.set(data);
      
      debugPrint("Note successfully added to Firebase with ID: ${note.id}");
    }, 'addNote');
  }

  Future<void> updateNote(NoteModel note) async {
    return _retryOperation(() async {
      // Kullanıcının giriş yapmış olduğunu kontrol et
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final now = DateTime.now().toUtc();
      final data = {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'isPinned': note.isPinned,
        'userId': user.uid,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Firebase ID'sini kullan
      String docId = note.id.toString();
      
      await _firestore.collection('notes').doc(docId).update(data);
      debugPrint("Note successfully updated in Firebase with ID: $docId");
    }, 'updateNote');
  }

  Future<void> deleteNote(int id) async {
    return _retryOperation(() async {
      // Kullanıcının giriş yapmış olduğunu kontrol et
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await _firestore.collection('notes').doc(id.toString()).delete();
      debugPrint("Note successfully deleted from Firebase with ID: $id");
    }, 'deleteNote');
  }

  Future<List<NoteModel>> getNotes() async {
    return _retryOperation(() async {
      final notes = await _firestore
          .collection('notes')
          .get()
          .then(
            (snapshot) => snapshot.docs
                .map((doc) => NoteModel.fromJson(doc.data()))
                .toList(),
          );
      
      // Notları sırala: önce pinli olanlar, sonra pinli olmayanlar
      notes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      _notes = notes;
      debugPrint("Successfully fetched ${notes.length} notes from Firebase");
      return notes;
    }, 'getNotes');
  }

  Future<void> togglePinNote(int id) async {
    return _retryOperation(() async {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final docRef = _firestore.collection('notes').doc(id.toString());
      final doc = await docRef.get();
      
      if (doc.exists) {
        final currentData = doc.data()!;
        final newPinStatus = !(currentData['isPinned'] ?? false);
        
        await docRef.update({
          'isPinned': newPinStatus,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
        
        debugPrint("Note pin durumu Firebase'de değiştirildi: $newPinStatus");
      }
    }, 'togglePinNote');
  }

  Future<void> pinNote(int id) async {
    return _retryOperation(() async {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await _firestore.collection('notes').doc(id.toString()).update({
        'isPinned': true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      
      debugPrint("Note Firebase'de pinlendi");
    }, 'pinNote');
  }

  Future<void> unpinNote(int id) async {
    return _retryOperation(() async {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      await _firestore.collection('notes').doc(id.toString()).update({
        'isPinned': false,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      
      debugPrint("Note Firebase'de unpinlendi");
    }, 'unpinNote');
  }

  Future<Stream<List<NoteModel>>> getNoteById(String id) async {
    try {
      return _firestore
          .collection('notes')
          .where('id', isEqualTo: id)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => NoteModel.fromJson(doc.data()))
                .toList(),
          );
    } catch (e) {
      debugPrint("Error getting note by id: ${e.toString()}");
      throw Exception(e);
    }
  }
}
