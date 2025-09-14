import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_notes/models/note_model.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/services/firebase_services.dart';

class ApiServices {
  // Environment variable'dan URL al, yoksa default kullan
  static const String baseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:8000');
  final List<NoteModel> _notes = [];
  final AuthProvider _authProvider = AuthProvider();
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<NoteModel> get notes => _notes;

  Future<List<NoteModel>> getNotes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notes'),headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'
        });
      if (response.statusCode == 200) {
        final List<dynamic> notes = jsonDecode(response.body) as List<dynamic>;
        final backendNotes = notes
            .map((note) => NoteModel.fromJson(note as Map<String, dynamic>))
            .toList();
        
        debugPrint('Backend\'den ${backendNotes.length} not getirildi');
        return backendNotes;
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      debugPrint('Error getting notes: $e');
      throw Exception(e);
    }
  }

  Future<NoteModel> addNote(NoteModel note) async {
    try {
      // Sadece title, content ve isPinned gönder, backend otomatik tarih ekler
      final payload = {
        'title': note.title,
        'content': note.content,
        'isPinned': note.isPinned,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final noteData = jsonDecode(response.body);
        return NoteModel.fromJson(noteData);
      } else {
        throw Exception('Failed to add note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding note: $e');
      throw Exception(e);
    }
  }

  Future<NoteModel> updateNote(NoteModel note) async {
    try {
      // Sadece değiştirilecek field'ları gönder
      final payload = {
        'title': note.title,
        'content': note.content,
        'isPinned': note.isPinned,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final noteData = jsonDecode(response.body);
        return NoteModel.fromJson(noteData);
      } else {
        throw Exception('Failed to update note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      throw Exception(e);
    }
  }

  Future<NoteModel> deleteNote(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/notes/$id'), headers: {'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'});
      if (response.statusCode == 200) {
        final note = jsonDecode(response.body);
        return NoteModel.fromJson(note);
      } else {
        throw Exception('Failed to delete note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
      throw Exception(e);
    }
  }

  /// Sadece Firebase'de bulunan notları getirir
  Future<List<NoteModel>> getNotesFromFirebaseOnly() async {
    try {
      final firebaseNotes = await _firebaseServices.getNotes();
      debugPrint('Firebase\'den ${firebaseNotes.length} not getirildi');
      return firebaseNotes;
    } catch (e) {
      debugPrint('Error getting notes from Firebase: $e');
      throw Exception(e);
    }
  }

  /// Pin durumunu değiştirir
  Future<void> togglePinNote(int id) async {
    try {
      // Önce mevcut notu al
      final response = await http.get(
        Uri.parse('$baseUrl/notes/$id'),
        headers: {'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'}
      );
      if (response.statusCode == 200) {
        final noteData = jsonDecode(response.body);
        final currentNote = NoteModel.fromJson(noteData);
        
        // Pin durumunu tersine çevir
        final newPinStatus = !currentNote.isPinned;
        
        // Sadece isPinned alanını güncelle
        final payload = {
          'isPinned': newPinStatus,
        };
        
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/notes/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'
          },
          body: jsonEncode(payload),
        );
        
        if (updateResponse.statusCode == 200) {
          debugPrint('Backend\'de pin durumu değiştirildi: $newPinStatus');
        } else {
          throw Exception('Failed to toggle pin: ${updateResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to get note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      throw Exception(e);
    }
  }

  /// Backend'den gelen notları Firebase'e senkronize eder
  Future<void> syncBackendNotesToFirebase() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes'),
        headers: {'Authorization': 'Bearer ${_authProvider.user?.getIdToken()}'}
      );
      if (response.statusCode == 200) {
        final List<dynamic> notes = jsonDecode(response.body) as List<dynamic>;
        final backendNotes = notes
            .map((note) => NoteModel.fromJson(note as Map<String, dynamic>))
            .toList();
        
        // Her backend notunu Firebase'e ekle
        for (final note in backendNotes) {
          try {
            await _firebaseServices.addNote(note);
            debugPrint('Not Firebase\'e senkronize edildi: ${note.title}');
          } catch (e) {
            debugPrint('Not Firebase\'e eklenirken hata: ${note.title} - $e');
          }
        }
        
        debugPrint('${backendNotes.length} not Firebase\'e senkronize edildi');
      }
    } catch (e) {
      debugPrint('Error syncing notes to Firebase: $e');
      throw Exception(e);
    }
  }
}

