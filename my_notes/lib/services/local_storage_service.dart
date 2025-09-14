
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:my_notes/models/note_model.dart';
import 'package:path_provider/path_provider.dart';



class LocalStorageService {
  static late Isar _isar;
  List<NoteModel> _notes = [];
  List<NoteModel> _searchResults = [];


  List<NoteModel> get notes => _notes;
  List<NoteModel> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;
 
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([NoteModelSchema], directory: dir.path);
  }

  Future<void> addNote(NoteModel note) async {
    debugPrint("LocalStorageService: Not ekleniyor - ${note.title} (ID: ${note.id})");
    await _isar.writeTxn(() async {
      // ID'yi 0 yap ki Isar yeni ID atsın
      note.id = Isar.autoIncrement;
      await _isar.noteModels.put(note);
    });
    await _getNotes();
    debugPrint("LocalStorageService: Not eklendi. Yeni ID: ${note.id}, Toplam not sayısı: ${_notes.length}");
  }

  Future<void> addNotes(List<NoteModel> notes) async {
    await _isar.writeTxn(() async {
      for (final note in notes) {
        await _isar.noteModels.put(note);
      }
    });
    await _getNotes();
  }

  Future<void> _getNotes() async {
    _notes = await _isar.noteModels.where().findAll();
    _sortNotes();
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      // Önce pinli notlar, sonra pinli olmayanlar
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Aynı pin durumundaysa, oluşturulma tarihine göre sırala (yeniden eskiye)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> refreshNotes() async {
    debugPrint("LocalStorageService: Notlar yenileniyor...");
    await _getNotes();
    debugPrint("LocalStorageService: Notlar yenilendi. Toplam: ${_notes.length}");
  }



  Future<void> updateNote(NoteModel note) async {
    final existingNote = await _isar.noteModels
        .where()
        .filter()
        .idEqualTo(note.id)
        .findFirst();
    if (existingNote != null) {
      existingNote.title = note.title;
      existingNote.content = note.content;
      existingNote.isPinned = note.isPinned;
      existingNote.updatedAt = note.updatedAt;
    }
    await _isar.writeTxn(() async {
      await _isar.noteModels.put(note);
    });
    await _getNotes();
  }

  Future<void> togglePinNote(int id) async {
    final existingNote = await _isar.noteModels.get(id);
    if (existingNote != null) {
      existingNote.isPinned = !existingNote.isPinned;
      existingNote.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.noteModels.put(existingNote);
      });
      await _getNotes();
      debugPrint("Note pin durumu değiştirildi: ${existingNote.isPinned}");
    }
  }

  Future<void> pinNote(int id) async {
    final existingNote = await _isar.noteModels.get(id);
    if (existingNote != null && !existingNote.isPinned) {
      existingNote.isPinned = true;
      existingNote.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.noteModels.put(existingNote);
      });
      await _getNotes();
      debugPrint("Note pinlendi");
    }
  }

  Future<void> unpinNote(int id) async {
    final existingNote = await _isar.noteModels.get(id);
    if (existingNote != null && existingNote.isPinned) {
      existingNote.isPinned = false;
      existingNote.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.noteModels.put(existingNote);
      });
      await _getNotes();
      debugPrint("Note unpinlendi");
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final existingNote = await _isar.noteModels.get(id);
      if (existingNote != null) {
        await _isar.writeTxn(() async {
          await _isar.noteModels.delete(id);
        });
      }
      await _getNotes();
    } catch (e) {
      
      
      rethrow;
    }
  }


  Future<void> searchNotes(String query) async {
    if (query.trim().isEmpty) {
      _isSearching = false;
      _searchResults.clear();
      return;
    }

    _isSearching = true;

    // Hem başlıkta hem içerikte arama yap (büyük/küçük harf duyarsız)
    final lowerQuery = query.toLowerCase();

    final allNotes = await _isar.noteModels.where().findAll();
    _searchResults = allNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();

    // Arama sonuçlarını da sırala
    _sortSearchResults();
  }

  void _sortSearchResults() {
    _searchResults.sort((a, b) {
      // Önce pinli notlar, sonra pinli olmayanlar
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Aynı pin durumundaysa, oluşturulma tarihine göre sırala (yeniden eskiye)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // void _sortSearchResults() {
  //   _searchResults.sort((a, b) {
  //     if (_sortOrder == SortOrder.newestFirst) {
  //       return b.createdAt.compareTo(a.createdAt); // Yeniden eskiye
  //     } else {
  //       return a.createdAt.compareTo(b.createdAt); // Eskiden yeniye
  //     }
  //   });
  // }

  Future<void> clearSearch() async {
    _isSearching = false;
    _searchResults.clear();
  }

  // Sıralama düzenini değiştir
  // Future<void> toggleSortOrder() async {
  //   _sortOrder = _sortOrder == SortOrder.newestFirst
  //       ? SortOrder.oldestFirst
  //       : SortOrder.newestFirst;

  //   // Mevcut notları yeniden sırala
  //   _sortNotes();

  //   // Eğer arama yapılıyorsa, arama sonuçlarını da yeniden sırala
  //   if (_isSearching) {
  //     _sortSearchResults();
  //   }
  // }

  // Belirli bir sıralama düzeni ayarla
  // Future<void> setSortOrder(SortOrder order) async {
  //   if (_sortOrder != order) {
  //     _sortOrder = order;
  //     _sortNotes();

  //     if (_isSearching) {
  //       _sortSearchResults();
  //     }
  //   }
  // }

  Future<void> clearAllNotes() async {
    await _isar.writeTxn(() async {
      await _isar.noteModels.clear();
    });
    await _getNotes();
  }

  // Veritabanını tamamen temizle ve yeniden oluştur
  Future<void> clearDatabase() async {
    try {
      debugPrint("LocalStorageService: Veritabanı temizleniyor...");
      await _isar.writeTxn(() async {
        await _isar.noteModels.clear();
      });
      await _getNotes();
      debugPrint("LocalStorageService: Veritabanı temizlendi");
    } catch (e) {
      debugPrint("LocalStorageService: Veritabanı temizleme hatası: $e");
      // Eğer temizleme başarısız olursa, veritabanını yeniden oluştur
      await _recreateDatabase();
    }
  }

  // Veritabanını yeniden oluştur
  Future<void> _recreateDatabase() async {
    try {
      debugPrint("LocalStorageService: Veritabanı yeniden oluşturuluyor...");
      await _isar.close();
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([NoteModelSchema], directory: dir.path);
      _notes = [];
      debugPrint("LocalStorageService: Veritabanı yeniden oluşturuldu");
    } catch (e) {
      debugPrint("LocalStorageService: Veritabanı yeniden oluşturma hatası: $e");
    }
  }

}
