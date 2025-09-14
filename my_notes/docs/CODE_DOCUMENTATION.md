# 📚 My Notes - Kod Dokümantasyonu

Bu dokümantasyon, My Notes projesindeki tüm sınıflar, metodlar ve fonksiyonların detaylı açıklamalarını içerir.

## 📁 Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/
│   └── note_model.dart         # Not veri modeli
├── services/
│   ├── api_services.dart       # Backend API servisleri
│   ├── firebase_services.dart  # Firebase servisleri
│   └── local_storage_service.dart # Local storage servisleri
├── providers/
│   └── notes_provider.dart     # State management
├── pages/
│   ├── notes_page.dart         # Ana notlar sayfası
│   └── create_note.dart        # Not oluşturma sayfası
└── widgets/
    └── note_item.dart          # Not widget'ı
```

---

## 🏗️ Models

### 📝 NoteModel (`lib/models/note_model.dart`)

Not verilerini temsil eden ana model sınıfı.

#### **Özellikler:**
```dart
Id id = Isar.autoIncrement;     // Benzersiz ID (Isar otomatik artırır)
String title;                   // Not başlığı
String content;                 // Not içeriği
bool isPinned;                  // Sabitlenmiş mi?
String userId;                  // Kullanıcı ID'si
DateTime createdAt;             // Oluşturulma tarihi
DateTime? updatedAt;            // Güncellenme tarihi (opsiyonel)
```

#### **Metodlar:**

**`NoteModel({...})`** - Constructor
- Not nesnesi oluşturur
- Tüm gerekli parametreleri alır

**`NoteModel.fromJson(Map<String, dynamic> json)`** - JSON'dan Not Oluşturma
- Backend'den gelen JSON verisini NoteModel'e çevirir
- `content` alanını hem `content` hem `description` olarak okuyabilir
- Tarih formatlarını parse eder

**`Map<String, dynamic> toJson()`** - Not'u JSON'a Çevirme
- NoteModel'i JSON formatına çevirir
- API'ye gönderim için kullanılır
- Tarihleri ISO8601 formatına çevirir

**`NoteModel copyWith({...})`** - Not Kopyalama
- Mevcut notun kopyasını oluşturur
- Belirtilen alanları günceller, diğerlerini korur
- Immutable güncellemeler için kullanılır

---

## 🔧 Services

### 🌐 ApiServices (`lib/services/api_services.dart`)

Backend API ile iletişim kuran servis sınıfı.

#### **Özellikler:**
```dart
static const String baseUrl = 'http://localhost:8000';  // API base URL
List<NoteModel> _notes = [];                            // Notlar listesi
final FirebaseServices _firebaseServices;               // Firebase servisi
```

#### **Metodlar:**

**`Future<List<NoteModel>> getNotes()`** - API'den Notları Getirme
- Backend'den tüm notları çeker
- HTTP GET isteği yapar
- JSON'u NoteModel listesine çevirir
- Hata durumunda exception fırlatır

**`Future<NoteModel> addNote(NoteModel note)`** - API'ye Not Ekleme
- Yeni notu backend'e gönderir
- HTTP POST isteği yapar
- Sadece `title`, `content`, `isPinned` gönderir
- Backend otomatik tarih ekler
- Eklenen notu döndürür

**`Future<NoteModel> updateNote(NoteModel note)`** - API'de Not Güncelleme
- Mevcut notu günceller
- HTTP PUT isteği yapar
- Tüm alanları günceller
- Güncellenmiş notu döndürür

**`Future<NoteModel> deleteNote(int id)`** - API'den Not Silme
- Belirtilen ID'ye sahip notu siler
- HTTP DELETE isteği yapar
- Silinen notu döndürür

**`Future<List<NoteModel>> getNotesFromFirebaseOnly()`** - Sadece Firebase'den Getirme
- Firebase'den notları çeker
- API kontrolü yapmaz
- Firebase servisini kullanır

**`Future<void> togglePinNote(int id)`** - API'de Pin Durumu Değiştirme
- Önce mevcut notu alır
- Pin durumunu tersine çevirir
- Sadece `isPinned` alanını günceller
- Verimli güncelleme için optimize edilmiş

**`Future<void> syncBackendNotesToFirebase()`** - Backend'i Firebase'e Senkronize Etme
- Backend'deki tüm notları alır
- Her notu Firebase'e ekler
- Toplu senkronizasyon yapar
- Hata durumlarını yönetir

---

### 🔥 FirebaseServices (`lib/services/firebase_services.dart`)

Firebase Firestore ile iletişim kuran servis sınıfı.

#### **Özellikler:**
```dart
final FirebaseAuth _auth = FirebaseAuth.instance;        // Firebase Auth
final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore
List<NoteModel> _notes = [];                             // Notlar listesi
```

#### **Metodlar:**

**`Future<T> _retryOperation<T>(...)`** - Retry Mekanizması
- Hata durumunda 3 kez tekrar dener
- Network hatalarını yakalar
- 2, 4, 6 saniye aralıklarla bekler
- Tüm Firebase işlemlerinde kullanılır

**`Future<User?> getCurrentUser()`** - Mevcut Kullanıcıyı Getirme
- Firebase'de giriş yapmış kullanıcıyı döndürür
- Kullanıcı yoksa null döndürür

**`Future<User?> signInWithEmailAndPassword(String email, String password)`** - Email/Şifre ile Giriş
- Firebase Authentication ile giriş yapar
- Başarılı girişte User nesnesi döndürür

**`Future<User?> signUpWithEmailAndPassword(String email, String password)`** - Email/Şifre ile Kayıt
- Yeni kullanıcı oluşturur
- Firebase Authentication kullanır

**`Future<void> signOut()`** - Çıkış Yapma
- Kullanıcıyı Firebase'den çıkarır

**`Future<void> addNote(NoteModel note)`** - Firebase'e Not Ekleme
- Kullanıcı giriş kontrolü yapar
- Notu Firestore'a ekler
- UTC tarih kullanır
- Retry mekanizması ile korunur

**`Future<void> updateNote(NoteModel note)`** - Firebase'de Not Güncelleme
- Mevcut notu günceller
- `updatedAt` alanını günceller
- Kullanıcı kontrolü yapar

**`Future<void> deleteNote(int id)`** - Firebase'den Not Silme
- Belirtilen ID'ye sahip notu siler
- Kullanıcı kontrolü yapar

**`Future<List<NoteModel>> getNotes()`** - Firebase'den Notları Getirme
- Tüm notları Firestore'dan çeker
- Pinli notları üstte sıralar
- Tarihe göre sıralama yapar
- Retry mekanizması ile korunur

**`Future<void> togglePinNote(int id)`** - Firebase'de Pin Durumu Değiştirme
- Mevcut pin durumunu alır
- Tersine çevirir
- Sadece pin alanını günceller

**`Future<void> pinNote(int id)`** - Firebase'de Not Sabitleme
- Notu pinler (`isPinned: true`)
- Kullanıcı kontrolü yapar

**`Future<void> unpinNote(int id)`** - Firebase'de Not Sabitlemeyi Kaldırma
- Notu unpinler (`isPinned: false`)
- Kullanıcı kontrolü yapar

**`Future<Stream<List<NoteModel>>> getNoteById(String id)`** - ID'ye Göre Not Getirme
- Belirli ID'ye sahip notu stream olarak döndürür
- Gerçek zamanlı güncellemeler için kullanılır

---

### 💾 LocalStorageService (`lib/services/local_storage_service.dart`)

Isar veritabanı ile local storage işlemlerini yöneten servis.

#### **Özellikler:**
```dart
static late Isar _isar;                    // Isar veritabanı instance
List<NoteModel> _notes = [];               // Notlar listesi
List<NoteModel> _searchResults = [];       // Arama sonuçları
bool _isSearching = false;                 // Arama durumu
```

#### **Metodlar:**

**`Future<void> init()`** - Veritabanını Başlatma
- Isar veritabanını açar
- Uygulama dokümanları dizininde oluşturur

**`Future<void> addNote(NoteModel note)`** - Local'e Not Ekleme
- Notu Isar veritabanına ekler
- Otomatik ID atar
- Notları yeniden sıralar

**`Future<void> addNotes(List<NoteModel> notes)`** - Toplu Not Ekleme
- Birden fazla notu aynı anda ekler
- Senkronizasyon için kullanılır

**`Future<void> _getNotes()`** - Private Not Getirme
- Tüm notları veritabanından çeker
- Sıralama yapar

**`void _sortNotes()`** - Notları Sıralama
- Pinli notları üstte gösterir
- Tarihe göre sıralar (yeniden eskiye)

**`Future<void> refreshNotes()`** - Notları Yenileme
- Veritabanından notları yeniden çeker
- UI güncellemesi için kullanılır

**`Future<void> updateNote(NoteModel note)`** - Local'de Not Güncelleme
- Mevcut notu bulur ve günceller
- Tüm alanları günceller

**`Future<void> togglePinNote(int id)`** - Local'de Pin Durumu Değiştirme
- Pin durumunu tersine çevirir
- `updatedAt` alanını günceller

**`Future<void> pinNote(int id)`** - Local'de Not Sabitleme
- Notu pinler
- Sadece pinli olmayan notları pinler

**`Future<void> unpinNote(int id)`** - Local'de Not Sabitlemeyi Kaldırma
- Notu unpinler
- Sadece pinli notları unpinler

**`Future<void> deleteNote(int id)`** - Local'den Not Silme
- Belirtilen ID'ye sahip notu siler
- Hata yönetimi yapar

**`Future<void> searchNotes(String query)`** - Not Arama
- Başlık ve içerikte arama yapar
- Büyük/küçük harf duyarsız
- Arama sonuçlarını sıralar

**`void _sortSearchResults()`** - Arama Sonuçlarını Sıralama
- Arama sonuçlarını pin ve tarihe göre sıralar

**`Future<void> clearSearch()`** - Aramayı Temizleme
- Arama durumunu sıfırlar
- Arama sonuçlarını temizler

**`Future<void> clearAllNotes()`** - Tüm Notları Silme
- Veritabanındaki tüm notları siler
- Temizlik işlemleri için kullanılır

**`Future<void> clearDatabase()`** - Veritabanını Temizleme
- Veritabanını tamamen temizler
- Hata durumunda yeniden oluşturur

**`Future<void> _recreateDatabase()`** - Veritabanını Yeniden Oluşturma
- Veritabanını kapatır ve yeniden açar
- Hata durumlarında kullanılır

---

## 🎯 Providers

### 📋 NotesProvider (`lib/providers/notes_provider.dart`)

Uygulamanın state management'ını yöneten ana provider sınıfı.

#### **Özellikler:**
```dart
final ConnectivityService _connectivityService;    // Bağlantı servisi
final FirebaseServices _firebaseServices;          // Firebase servisi
final LocalStorageService _localStorageService;    // Local storage servisi
final ApiServices _apiServices;                    // API servisi
List<NoteModel> _notes = [];                       // Notlar listesi
List<NoteModel> _searchResults = [];               // Arama sonuçları
bool _isLoading = false;                           // Yükleme durumu
bool _isSearching = false;                         // Arama durumu
String _searchQuery = "";                          // Arama sorgusu
String _errorMessage = "";                         // Hata mesajı
bool _isSyncing = false;                           // Senkronizasyon durumu
String _syncStatus = "";                           // Senkronizasyon mesajı
```

#### **Constructor:**
**`NotesProvider({...})`** - Provider Başlatma
- Tüm servisleri initialize eder
- Bağlantı dinleyicisini kurar
- İlk senkronizasyonu başlatır

#### **Private Metodlar:**

**`Future<void> _initializeAndSync()`** - İlk Yükleme ve Senkronizasyon
- Local verileri yükler
- Hata yönetimi yapar

**`Future<void> _bulkSyncToFirebase()`** - Toplu Firebase Senkronizasyonu
- Local verileri Firebase'e toplu gönderir
- Duplikat kontrolü yapar
- Progress gösterir
- Rate limiting uygular

**`void _setupConnectivityListener()`** - Bağlantı Dinleyicisi Kurma
- İnternet bağlantısı değişikliklerini dinler
- Otomatik senkronizasyon başlatır

**`Future<void> _onConnectivityChanged(bool isConnected)`** - Bağlantı Değişikliği
- İnternet geldiğinde senkronizasyon yapar
- Firebase ve API verilerini birleştirir
- Duplikatları kaldırır
- Local verileri günceller

**`void _sortNotes()`** - Notları Sıralama
- Pinli notları üstte gösterir
- Tarihe göre sıralar

#### **Public Metodlar:**

**`Future<void> sendLocalDataToFirebase()`** - Manuel Firebase Gönderimi
- Kullanıcı tarafından tetiklenen senkronizasyon
- Bağlantı kontrolü yapar
- Local veri kontrolü yapar

**`void clearSyncStatus()`** - Senkronizasyon Durumunu Temizleme
- Senkronizasyon mesajını temizler

**`Future<void> clearDatabase()`** - Veritabanını Temizleme
- Local veritabanını temizler
- UI'ı günceller

**`Future<void> fetchNotes()`** - Notları Getirme
- İnternet varsa Firebase'den çeker
- Yoksa local'den çeker
- Senkronizasyon yapar

**`Future<void> addNote(NoteModel note)`** - Not Ekleme
- İnternet varsa: Local → Firebase → API
- Yoksa: Sadece Local
- Sıralama yapar

**`Future<void> updateNote(NoteModel note)`** - Not Güncelleme
- İnternet varsa: Firebase → API → Local
- Yoksa: Sadece Local
- Sıralama yapar

**`Future<void> deleteNote(int id)`** - Not Silme
- İnternet varsa: Firebase → API → Local
- Yoksa: Sadece Local
- Hata yönetimi yapar

**`Future<void> searchNotes(String query)`** - Not Arama
- Local storage'da arama yapar
- Sonuçları günceller

**`Future<void> clearSearch()`** - Aramayı Temizleme
- Arama durumunu sıfırlar
- Sonuçları temizler

**`Future<void> togglePinNote(int id)`** - Pin Durumu Değiştirme
- İnternet varsa: Firebase → Local → API
- Yoksa: Sadece Local
- Sıralama yapar

**`Future<void> pinNote(int id)`** - Not Sabitleme
- Notu pinler
- Tüm platformlarda senkronize eder

**`Future<void> unpinNote(int id)`** - Not Sabitlemeyi Kaldırma
- Notu unpinler
- Tüm platformlarda senkronize eder

#### **Getter'lar:**
- `List<NoteModel> get notes` - Notlar listesi
- `List<NoteModel> get searchResults` - Arama sonuçları
- `bool get isLoading` - Yükleme durumu
- `bool get isSearching` - Arama durumu
- `bool get isSyncing` - Senkronizasyon durumu
- `String get searchQuery` - Arama sorgusu
- `String get syncStatus` - Senkronizasyon mesajı
- `String get errorMessage` - Hata mesajı

---

## 📱 Pages

### 📋 NotesPage (`lib/pages/notes_page.dart`)

Ana notlar sayfası widget'ı.

#### **State:**
```dart
class _NotesPageState extends State<NotesPage>
```

#### **Metodlar:**

**`@override void initState()`** - Sayfa Başlatma
- Sayfa yüklendiğinde notları çeker
- `fetchNotes()` metodunu çağırır

**`@override Widget build(BuildContext context)`** - UI Oluşturma
- AppBar ile notlar başlığı
- Çıkış butonu
- Arama butonu
- Hata mesajları gösterimi
- Senkronizasyon durumu gösterimi
- Notlar listesi
- FloatingActionButton ile not ekleme

#### **UI Bileşenleri:**
- **AppBar**: Başlık, çıkış, arama butonları
- **Error Messages**: Hata mesajları gösterimi
- **Sync Status**: Senkronizasyon durumu
- **Empty State**: Not yoksa mesaj
- **Loading**: Yükleme göstergesi
- **Notes List**: Notların listesi
- **FAB**: Yeni not ekleme butonu

---

### ✏️ CreateNote (`lib/pages/create_note.dart`)

Not oluşturma sayfası widget'ı.

#### **State:**
```dart
class _CreateNoteState extends State<CreateNote>
```

#### **Controllers:**
```dart
final TextEditingController _titleController;    // Başlık input controller
final TextEditingController _contentController;  // İçerik input controller
```

#### **Metodlar:**

**`@override void dispose()`** - Kaynak Temizleme
- Controller'ları dispose eder
- Memory leak'i önler

**`void _addNote(dynamic authProvider, dynamic notesProvider)`** - Not Ekleme
- Form validasyonu yapar
- NoteModel oluşturur
- Provider'a not ekletir
- Başarı/hata mesajları gösterir
- Sayfayı kapatır

**`@override Widget build(BuildContext context)`** - UI Oluşturma
- AppBar ile başlık
- Hata mesajları gösterimi
- Form alanları (başlık, içerik)
- Kaydet butonu

#### **UI Bileşenleri:**
- **AppBar**: "Create Note" başlığı
- **Error Messages**: Hata mesajları
- **Title Input**: Başlık girişi
- **Content Input**: İçerik girişi (çok satırlı)
- **Create Button**: Not oluşturma butonu

---

## 🧩 Widgets

### 📝 NoteItem (`lib/widgets/note_item.dart`)

Tek bir notu gösteren widget.

#### **Properties:**
```dart
final Size size;                    // Ekran boyutu
final NoteModel note;               // Gösterilecek not
final NotesProvider notesProvider;  // Provider referansı
```

#### **Metodlar:**

**`String _formatDate(DateTime date)`** - Tarih Formatlama
- Türkçe tarih formatı
- "Bugün", "Dün" gibi relative tarihler
- Saat bilgisi ekler

**`void _showEditDialog(BuildContext context)`** - Düzenleme Dialog'u
- Not düzenleme dialog'unu açar
- Mevcut verileri input'lara doldurur
- Kaydet/İptal butonları
- Güncellenmiş notu provider'a gönderir

**`void _showSnackBar(...)`** - SnackBar Gösterimi
- İşlem sonucu mesajları
- Geri alma özelliği
- Özelleştirilmiş tasarım

**`void _deleteNote(BuildContext context)`** - Not Silme
- Notu siler
- Geri alma snackbar'ı gösterir

**`void _togglePin(BuildContext context)`** - Pin Durumu Değiştirme
- Pin durumunu değiştirir
- Geri alma snackbar'ı gösterir

**`@override Widget build(BuildContext context)`** - UI Oluşturma
- Container ile not kartı
- Pin durumuna göre renk
- Başlık ve içerik gösterimi
- Tarih bilgisi
- Pin ve silme butonları

#### **UI Bileşenleri:**
- **Container**: Not kartı container'ı
- **Pin Indicator**: Pin durumu göstergesi
- **Title**: Not başlığı
- **Content**: Not içeriği (2 satır)
- **Date**: Oluşturulma tarihi
- **Pin Button**: Pin/unpin butonu
- **Delete Button**: Silme butonu

---

## 🚀 Main

### 🎯 main.dart

Uygulamanın giriş noktası.

#### **Metodlar:**

**`void main() async`** - Uygulama Başlatma
- Firebase'i initialize eder
- ConnectivityService'i başlatır
- LocalStorageService'i initialize eder
- MultiProvider ile provider'ları kurar
- MyApp widget'ını çalıştırır

**`class MyApp extends StatelessWidget`** - Ana Uygulama Widget'ı
- MaterialApp oluşturur
- Route'ları tanımlar
- Theme ayarlarını yapar

---

## 🔄 Veri Akışı

### 📊 Senkronizasyon Stratejisi

1. **Not Ekleme:**
   ```
   Local → Firebase → API → Local Refresh
   ```

2. **Not Güncelleme:**
   ```
   Firebase → API → Local
   ```

3. **Not Silme:**
   ```
   Firebase → API → Local
   ```

4. **Pin Değiştirme:**
   ```
   Firebase → Local → API
   ```

5. **Veri Getirme:**
   ```
   Firebase + API → Merge → Local
   ```

### 🌐 Offline Desteği

- İnternet yokken sadece local storage kullanılır
- İnternet geldiğinde otomatik senkronizasyon
- Çakışma durumunda son değişiklik öncelikli

### 🔄 Hata Yönetimi

- Retry mekanizması (3 deneme)
- Kullanıcı dostu hata mesajları
- Graceful degradation
- Offline durumu bildirimi

---

## 📈 Performans Optimizasyonları

### ⚡ Verimlilik

- **Lazy Loading**: Notlar sayfa sayfa yüklenir
- **Caching**: Local storage ile hızlı erişim
- **Debouncing**: Arama için gecikme
- **Rate Limiting**: Firebase API limitleri

### 🧠 Memory Management

- **Dispose**: Controller'lar düzgün dispose edilir
- **Stream Management**: Stream'ler düzgün kapatılır
- **Image Cache**: Görsel cache yönetimi

### 🔧 Code Quality

- **Error Handling**: Kapsamlı hata yönetimi
- **Type Safety**: Güçlü tip kontrolü
- **Documentation**: Detaylı kod dokümantasyonu
- **Testing**: Unit ve integration testler

---

Bu dokümantasyon, My Notes projesindeki tüm kod yapısını ve işlevselliğini detaylı olarak açıklamaktadır. Her metod ve fonksiyonun ne işe yaradığı, nasıl çalıştığı ve hangi durumlarda kullanıldığı belirtilmiştir.
