import 'package:flutter/material.dart';
import 'package:my_notes/models/note_model.dart';
import 'package:my_notes/services/api_services.dart';
import 'package:my_notes/services/connectivity_service.dart';
import 'package:my_notes/services/firebase_services.dart';
// import 'package:my_notes/services/connectivity_service.dart';
// import 'package:my_notes/services/firebase_services.dart';
import 'package:my_notes/services/local_storage_service.dart';

class NotesProvider extends ChangeNotifier {
   final ConnectivityService _connectivityService;
   final FirebaseServices _firebaseServices;
  final LocalStorageService _localStorageService;
   final ApiServices _apiServices;
  List<NoteModel> _notes = [];
  List<NoteModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = "";
  String _errorMessage = "";
  bool _isSyncing = false;
  String _syncStatus = "";

  NotesProvider({
     ConnectivityService? connectivityService,
     FirebaseServices? firebaseServices,
    LocalStorageService? localStorageService,
    ApiServices? apiServices,
  }) :  _connectivityService = connectivityService ?? ConnectivityService.instance,
        _firebaseServices = firebaseServices ?? FirebaseServices(),
        _apiServices = apiServices ?? ApiServices(),
       _localStorageService = localStorageService ?? LocalStorageService() {
    // Constructor'da anlık olarak notları çek ve internet varsa toplu senkronizasyon yap
    _initializeAndSync();
    _setupConnectivityListener();
  }

  // Uygulama başlangıcında sadece local verileri yükle
  Future<void> _initializeAndSync() async {
    try {
      // Local storage'dan notları yükle
      await _localStorageService.refreshNotes();
      _notes = _localStorageService.notes;
      
      debugPrint("Local veriler yüklendi. Toplam not sayısı: ${_notes.length}");
      
      _sortNotes();
      notifyListeners();
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Tüm local verileri Firebase'e toplu olarak gönder
  Future<void> _bulkSyncToFirebase() async {
    _isSyncing = true;
    _syncStatus = "Firebase'e gönderme başlatılıyor...";
    notifyListeners();
    
    try {
      debugPrint("Toplu senkronizasyon başlatılıyor... Local not sayısı: ${_notes.length}");
      _syncStatus = "Local veriler Firebase'e gönderiliyor...";
      notifyListeners();
      
      int sentCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      
      // Firebase'den mevcut notları al
      List<NoteModel> firebaseNotes = [];
      try {
        await _firebaseServices.getNotes();
        firebaseNotes = _firebaseServices.notes;
        debugPrint("Firebase'de ${firebaseNotes.length} not bulundu");
      } catch (e) {
        debugPrint("Firebase'den notlar alınamadı, tüm local notlar gönderilecek: $e");
      }
      
      for (int i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        
        // Firebase'de bu not var mı kontrol et
        bool existsInFirebase = firebaseNotes.any((firebaseNote) => 
          firebaseNote.title == note.title && 
          firebaseNote.content == note.content &&
          firebaseNote.createdAt.difference(note.createdAt).inSeconds.abs() < 5
        );
        
        if (existsInFirebase) {
          skippedCount++;
          debugPrint("Not zaten Firebase'de mevcut, atlanıyor: ${note.title}");
          continue;
        }
        
        try {
          _syncStatus = "Gönderiliyor: ${note.title} (${i + 1}/${_notes.length})";
          notifyListeners();
          
          await _firebaseServices.addNote(note);
          sentCount++;
         
          // Kısa bir bekleme ekle (Firebase rate limit'i için)
          await Future.delayed(Duration(milliseconds: 100));
          
        } catch (e) {
          errorCount++;
          debugPrint("Not gönderilemedi: ${note.title} - Hata: $e");
        }
      }
      
      debugPrint("Local veriler Firebase'e gönderme tamamlandı. Başarılı: $sentCount, Hata: $errorCount, Atlanan: $skippedCount");
      
      _syncStatus = "Gönderme tamamlandı! Başarılı: $sentCount, Hata: $errorCount, Atlanan: $skippedCount";
      
      // 5 saniye sonra senkronizasyon durumunu temizle
      Future.delayed(Duration(seconds: 5), () {
        _syncStatus = "";
        notifyListeners();
      });
      
    } catch (e) {
      debugPrint("Firebase'e gönderme hatası: $e");
      _syncStatus = "Gönderme hatası: ${e.toString()}";
      throw Exception("Firebase'e gönderme başarısız: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Bağlantı durumu değişikliklerini dinle
  void _setupConnectivityListener() {
    _connectivityService.initialize(onConnectivityChanged: _onConnectivityChanged).then((_) {
      // İlk bağlantı kontrolü yapıldıktan sonra dinleyiciyi kur
      debugPrint("Bağlantı dinleyicisi kuruldu");
    });
  }

  // İnternet bağlantısı geldiğinde local verileri Firebase'e gönder
  Future<void> _onConnectivityChanged(bool isConnected) async {
    debugPrint("Bağlantı durumu değişti: $isConnected");
    
    if (isConnected) {
      debugPrint("İnternet bağlantısı tespit edildi - Senkronizasyon başlatılıyor...");
      
      // Senkronizasyon başladığını bildir
      _isSyncing = true;
      _syncStatus = "İnternet bağlantısı tespit edildi - Senkronizasyon başlatılıyor...";
      notifyListeners();
      
      // Önce Firebase'den güncel verileri çek
      try {
        _syncStatus = "Firebase'den güncel veriler çekiliyor...";
        notifyListeners();
        
        debugPrint("Firebase'den güncel veriler çekiliyor...");
        await _firebaseServices.getNotes();
        List<NoteModel> firebaseNotes = _firebaseServices.notes;
        debugPrint("Firebase'den ${firebaseNotes.length} not çekildi");
        
        debugPrint("API'den güncel veriler çekiliyor...");
        List<NoteModel> apiNotes = await _apiServices.getNotes();
        debugPrint("API'den ${apiNotes.length} not çekildi");
        
        // Firebase ve API verilerini birleştir
        List<NoteModel> allNotes = [...firebaseNotes, ...apiNotes];
        
        // Duplikatları kaldır (aynı ID'ye sahip notları)
        Map<int, NoteModel> uniqueNotes = {};
        for (var note in allNotes) {
          uniqueNotes[note.id] = note;
        }
        List<NoteModel> mergedNotes = uniqueNotes.values.toList();
        
        debugPrint("Toplam ${mergedNotes.length} benzersiz not birleştirildi");
        
        // Local verileri güncelle
        _syncStatus = "Local veriler güncelleniyor...";
        notifyListeners();
        
        await _localStorageService.addNotes(mergedNotes);
        await _localStorageService.refreshNotes();
        _notes = _localStorageService.notes;
        _sortNotes();
        notifyListeners();
        
        debugPrint("Local veriler Firebase verileri ile güncellendi");
      } catch (e) {
        debugPrint("Firebase'den veri çekme hatası: $e");
        _errorMessage = "Firebase'den veri çekme hatası: ${e.toString()}";
        notifyListeners();
      }
      
      // Eğer local'de Firebase'de olmayan veriler varsa onları gönder
      if (_notes.isNotEmpty) {
        debugPrint("Local veriler Firebase'e gönderiliyor...");
        try {
          await _bulkSyncToFirebase();
          debugPrint("Local veriler başarıyla Firebase'e gönderildi");
        } catch (e) {
          debugPrint("Firebase'e gönderme hatası: $e");
          _errorMessage = "Firebase'e gönderme başarısız: ${e.toString()}";
          notifyListeners();
        }
      } else {
        _isSyncing = false;
        _syncStatus = "Senkronizasyon tamamlandı - Veri güncel";
        notifyListeners();
      }
    } else {
      debugPrint("İnternet bağlantısı kesildi - Sadece local veriler kullanılacak");
      _syncStatus = "İnternet bağlantısı kesildi - Offline mod";
      notifyListeners();
      
      // 3 saniye sonra mesajı temizle
      Future.delayed(Duration(seconds: 3), () {
        if (!_connectivityService.isConnected) {
          _syncStatus = "";
          notifyListeners();
        }
      });
    }
  }

  // Manuel olarak local verileri Firebase'e gönder
  Future<void> sendLocalDataToFirebase() async {
    if (!_connectivityService.isConnected) {
      _errorMessage = "İnternet bağlantısı bulunmuyor";
      _syncStatus = "İnternet bağlantısı yok";
      notifyListeners();
      return;
    }

    if (_notes.isEmpty) {
      _errorMessage = "Gönderilecek local veri bulunmuyor";
      _syncStatus = "Local veri yok";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      await _bulkSyncToFirebase();
      debugPrint("Local veriler başarıyla Firebase'e gönderildi");
    } catch (e) {
      _errorMessage = "Firebase'e gönderme hatası: ${e.toString()}";
      debugPrint("Firebase'e gönderme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Senkronizasyon durumunu temizle
  void clearSyncStatus() {
    _syncStatus = "";
    notifyListeners();
  }

  // Veritabanını temizle
  Future<void> clearDatabase() async {
    try {
      debugPrint("NotesProvider: Veritabanı temizleniyor...");
      await _localStorageService.clearDatabase();
      _notes = _localStorageService.notes;
      debugPrint("NotesProvider: Veritabanı temizlendi. Toplam not: ${_notes.length}");
      notifyListeners();
    } catch (e) {
      debugPrint("NotesProvider: Veritabanı temizleme hatası: $e");
    }
  }
  List<NoteModel> get notes => _notes;
  List<NoteModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSyncing => _isSyncing;
  String get searchQuery => _searchQuery;
  String get syncStatus => _syncStatus;
  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }
  String get errorMessage => _errorMessage;
  
  void clearErrorMessage() {
    _errorMessage = "";
    notifyListeners();
  }
  
  static get connectivityService => null;
  Future<void> fetchNotes() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Firebase'den yükleniyor...");
        await _firebaseServices.getNotes();
        _notes = _firebaseServices.notes;
        debugPrint("Firebase'den yükleme tamamlandı");
        // Firebase'den gelen notları local storage'a senkronize et
        await _localStorageService.addNotes(_notes);
        await _localStorageService.refreshNotes();
        _notes = _localStorageService.notes;
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'dan yükleniyor");
        await _localStorageService.refreshNotes();
        _notes = _localStorageService.notes;
      }
     
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
     
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not yükleme hatası: $e");
      // Format hatası varsa veritabanını temizle
      if (e.toString().contains('FormatException') || e.toString().contains('Unexpected extension byte')) {
        debugPrint("Format hatası tespit edildi, veritabanı temizleniyor...");
        await clearDatabase();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  Future<void> addNote(NoteModel note) async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();
   
    try {
     if (_connectivityService.isConnected) {
      await _localStorageService.addNote(note);
      _notes = _localStorageService.notes;
      debugPrint("İnternet bağlantısı var - Firebase'e kaydediliyor...");
      await _firebaseServices.addNote(note);
      _notes = _firebaseServices.notes;    
      debugPrint("Firebase'e kayıt tamamlandı");
      await _apiServices.addNote(note); // API'ye de ekle
      _notes = _apiServices.notes;
      debugPrint("API'ye kayıt tamamlandı");
      // Local verileri güncelle
      await _localStorageService.refreshNotes();
      _notes = _localStorageService.notes;
     
    } else {
      debugPrint("İnternet bağlantısı yok - Sadece local storage'a kaydediliyor");
       await _localStorageService.addNote(note);
      _notes = _localStorageService.notes;
      debugPrint("Not başarıyla eklendi. Toplam not sayısı: ${_notes.length}");
    }
     
     // Notları sırala (pinli olanlar en üstte)
     _sortNotes();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not ekleme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> updateNote(NoteModel note) async {
    _errorMessage = "";
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Tüm platformlarda güncelleniyor...");
        
        // Firebase'de güncelle (hata verirse devam et)
        try {
          await _firebaseServices.updateNote(note);
          debugPrint("Firebase'de güncelleme tamamlandı");
        } catch (e) {
          debugPrint("Firebase'de not bulunamadı veya güncellenemedi: $e");
        }
        
        // API'de güncelle (hata verirse devam et)
        try {
          await _apiServices.updateNote(note);
          debugPrint("API'de güncelleme tamamlandı");
        } catch (e) {
          debugPrint("API'de not bulunamadı veya güncellenemedi: $e");
        }
        
        // Local'de güncelle (bu her zaman çalışmalı)
        await _localStorageService.updateNote(note);
        _notes = _localStorageService.notes;
        debugPrint("Local storage'da güncellendi");
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'da güncelleniyor");
        await _localStorageService.updateNote(note);
        _notes = _localStorageService.notes;
      }
      
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
      debugPrint("Not başarıyla güncellendi");
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not güncelleme hatası: $e");
      notifyListeners();
    }
  }
  Future<void> deleteNote(int id) async {
    _errorMessage = "";
    notifyListeners(); // İşlem başında ekranı güncelle
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Tüm platformlardan siliniyor...");
        
        // Firebase'den sil (hata verirse devam et)
        try {
          await _firebaseServices.deleteNote(id);
          debugPrint("Firebase'den silme tamamlandı");
        } catch (e) {
          debugPrint("Firebase'de not bulunamadı veya silinemedi: $e");
        }
        
        // API'den sil (hata verirse devam et)
        try {
          await _apiServices.deleteNote(id);
          debugPrint("API'den silme tamamlandı");
        } catch (e) {
          debugPrint("API'de not bulunamadı veya silinemedi: $e");
        }
        
        // Local'den sil (bu her zaman çalışmalı)
        await _localStorageService.deleteNote(id);
        _notes = _localStorageService.notes;
        debugPrint("Local storage'dan silindi");
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'dan siliniyor");
        await _localStorageService.deleteNote(id);
        _notes = _localStorageService.notes;
      }
     
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
      debugPrint("Not başarıyla silindi");
      notifyListeners(); // İşlem tamamlandığında ekranı güncelle
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not silme hatası: $e");
      _notes = _localStorageService.notes;
      _sortNotes();
      notifyListeners(); // Hata durumunda da ekranı güncelle
      rethrow;
    }
  }

  // Arama işlemleri
  Future<void> searchNotes(String query) async {
    _searchQuery = query;
    await _localStorageService.searchNotes(query);
    _searchResults = _localStorageService.searchResults;
    _isSearching = _localStorageService.isSearching;
    notifyListeners();
  }
  Future<void> clearSearch() async {
    await _localStorageService.clearSearch();
    _searchResults.clear();
    _isSearching = false;
    _searchQuery = "";
    notifyListeners();
  }

  // Pinleme işlemleri
  Future<void> togglePinNote(int id) async {
    _errorMessage = "";
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Tüm platformlarda pin durumu değiştiriliyor...");
        
        // Firebase'de pin durumu değiştir (hata verirse devam et)
        try {
          await _firebaseServices.togglePinNote(id);
          debugPrint("Firebase'de pin durumu değiştirildi");
        } catch (e) {
          debugPrint("Firebase'de not bulunamadı veya pin durumu değiştirilemedi: $e");
        }
        
        // API'de pin durumu değiştir (hata verirse devam et)
        try {
          await _apiServices.togglePinNote(id);
          debugPrint("API'de pin durumu değiştirildi");
        } catch (e) {
          debugPrint("API'de not bulunamadı veya pin durumu değiştirilemedi: $e");
        }
        
        // Local'de pin durumu değiştir (bu her zaman çalışmalı)
        await _localStorageService.togglePinNote(id);
        _notes = _localStorageService.notes;
        debugPrint("Local storage'da pin durumu değiştirildi");
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'da pin durumu değiştiriliyor");
        await _localStorageService.togglePinNote(id);
        _notes = _localStorageService.notes;
      }
     
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
      debugPrint("Pin durumu başarıyla değiştirildi");
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Pin durumu değiştirme hatası: $e");
      _notes = _localStorageService.notes;
      _sortNotes();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> pinNote(int id) async {
    _errorMessage = "";
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Firebase'de pinleniyor...");
        await _firebaseServices.pinNote(id);
        debugPrint("Firebase'de pinlendi");
        await _localStorageService.pinNote(id);
        _notes = _localStorageService.notes;
        debugPrint("Local storage'da da pinlendi");
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'da pinleniyor");
        await _localStorageService.pinNote(id);
        _notes = _localStorageService.notes;
      }
     
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
      debugPrint("Not başarıyla pinlendi");
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not pinleme hatası: $e");
      _notes = _localStorageService.notes;
      _sortNotes();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unpinNote(int id) async {
    _errorMessage = "";
   
    try {
      if (_connectivityService.isConnected) {
        debugPrint("İnternet bağlantısı var - Firebase'de unpinleniyor...");
        await _firebaseServices.unpinNote(id);
        debugPrint("Firebase'de unpinlendi");
        await _localStorageService.unpinNote(id);
        _notes = _localStorageService.notes;
        debugPrint("Local storage'da da unpinlendi");
      } else {
        debugPrint("İnternet bağlantısı yok - Sadece local storage'da unpinleniyor");
        await _localStorageService.unpinNote(id);
        _notes = _localStorageService.notes;
      }
     
      // Notları sırala (pinli olanlar en üstte)
      _sortNotes();
      debugPrint("Not başarıyla unpinlendi");
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Not unpinleme hatası: $e");
      _notes = _localStorageService.notes;
      _sortNotes();
      notifyListeners();
      rethrow;
    }
  }

}
