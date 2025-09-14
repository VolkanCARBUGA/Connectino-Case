# 📝 Notes API - FastAPI Backend

Bu proje, not uygulaması için geliştirilmiş RESTful API backend'idir. FastAPI, SQLAlchemy ve SQLite kullanılarak geliştirilmiştir.

## 🚀 Özellikler

- ✅ CRUD operasyonları (Create, Read, Update, Delete)
- ✅ SQLite veritabanı entegrasyonu
- ✅ Pydantic model validasyonu
- ✅ Otomatik API dokümantasyonu
- ✅ RESTful API tasarımı
- ✅ Pin/unpin not özelliği
- ✅ Otomatik tarih yönetimi

## 📋 Gereksinimler

- Python 3.8+
- pip (Python paket yöneticisi)

## 🛠️ Kurulum

### 1. Projeyi Klonlayın
```bash
git clone <repository-url>
cd backend
```

### 2. Virtual Environment Oluşturun
```bash
python -m venv myenv
```

### 3. Virtual Environment'ı Aktifleştirin

**macOS/Linux:**
```bash
source myenv/bin/activate
```

**Windows:**
```bash
myenv\Scripts\activate
```

### 4. Bağımlılıkları Yükleyin
```bash
pip install -r requirements.txt
```

### 5. Environment Variables Ayarlayın
`.env` dosyası oluşturun:
```env
DATABASE_URL=sqlite:///./notes.db
```

### 6. Uygulamayı Başlatın
```bash
uvicorn main:app --reload
```

## 🌐 API Endpoints

### Base URL
```
http://localhost:8000  ### bu cihazın  local adresine göre değişebilir
```

### 📖 API Dokümantasyonu
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## 📡 API Endpoints Detayları

### 1. Tüm Notları Getir
```http
GET /notes
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "Örnek Not",
    "description": "Bu bir örnek nottur",
    "isPinned": false,
    "created_at": "2024-01-01T10:00:00",
    "updated_at": "2024-01-01T10:00:00"
  }
]
```

### 2. Yeni Not Oluştur
```http
POST /notes
```

**Request Body:**
```json
{
  "title": "Yeni Not",
  "description": "Bu yeni bir nottur"
}
```

**Response:**
```json
{
  "id": 2,
  "title": "Yeni Not",
  "description": "Bu yeni bir nottur",
  "isPinned": false,
  "created_at": "2024-01-01T11:00:00",
  "updated_at": "2024-01-01T11:00:00"
}
```

### 3. Belirli Notu Getir
```http
GET /notes/{note_id}
```

**Response:**
```json
{
  "id": 1,
  "title": "Örnek Not",
  "description": "Bu bir örnek nottur",
  "isPinned": false,
  "created_at": "2024-01-01T10:00:00",
  "updated_at": "2024-01-01T10:00:00"
}
```

### 4. Notu Güncelle
```http
PUT /notes/{note_id}
```

**Request Body (Tüm alanlar opsiyonel):**
```json
{
  "title": "Güncellenmiş Başlık",
  "description": "Güncellenmiş açıklama",
  "isPinned": true
}
```

**Response:**
```json
{
  "id": 1,
  "title": "Güncellenmiş Başlık",
  "description": "Güncellenmiş açıklama",
  "isPinned": true,
  "created_at": "2024-01-01T10:00:00",
  "updated_at": "2024-01-01T12:00:00"
}
```

### 5. Notu Sil
```http
DELETE /notes/{note_id}
```

**Response:**
```json
{
  "id": 1,
  "title": "Silinen Not",
  "description": "Bu not silindi",
  "isPinned": false,
  "created_at": "2024-01-01T10:00:00",
  "updated_at": "2024-01-01T10:00:00"
}
```

## 📊 Veritabanı Şeması

### Notes Tablosu
| Alan | Tip | Açıklama |
|------|-----|----------|
| id | Integer | Primary Key, Auto Increment |
| title | String | Not başlığı |
| description | String | Not açıklaması |
| isPinned | Boolean | Sabitlenmiş mi? (Default: False) |
| created_at | DateTime | Oluşturulma tarihi |
| updated_at | DateTime | Güncellenme tarihi |

## 🔧 Geliştirme

### Proje Yapısı
```
backend/
├── main.py              # Ana uygulama dosyası
├── requirements.txt     # Python bağımlılıkları
├── README.md           # Bu dosya
├── .env                # Environment variables
├── notes.db            # SQLite veritabanı (otomatik oluşur)
└── myenv/              # Virtual environment
```

### Kod Yapısı

#### Models (SQLAlchemy)
```python
class Note(Base):
    __tablename__ = "notes"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, index=True)
    isPinned = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.now)
    updated_at = Column(DateTime, default=datetime.datetime.now)
```

#### Pydantic Schemas
- `NoteCreate`: Yeni not oluşturma için
- `NoteUpdate`: Not güncelleme için
- `NoteResponse`: API response için

## 🧪 Test Etme

### cURL ile Test Örnekleri

**1. Tüm notları getir:**
```bash
curl -X GET "http://localhost:8000/notes"
```

**2. Yeni not oluştur:**
```bash
curl -X POST "http://localhost:8000/notes" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Not", "description": "Bu bir test notudur"}'
```

**3. Notu güncelle:**
```bash
curl -X PUT "http://localhost:8000/notes/1" \
  -H "Content-Type: application/json" \
  -d '{"title": "Güncellenmiş Başlık", "isPinned": true}'
```

**4. Notu sil:**
```bash
curl -X DELETE "http://localhost:8000/notes/1"
```

## 📱 Mobil Uygulama Entegrasyonu

### Flutter/Dart için API Kullanımı

**Base URL:**
```dart
// Android Emulator için
static const String baseUrl = 'http://10.0.2.2:8000';

// iOS Simulator için
static const String baseUrl = 'http://localhost:8000';
```

**HTTP İstek Örneği:**
```dart
// Yeni not oluştur
final response = await http.post(
  Uri.parse('$baseUrl/notes'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'title': 'Mobil Not',
    'description': 'Mobil uygulamadan oluşturuldu'
  }),
);
```

## 🚨 Hata Kodları

| HTTP Status | Açıklama |
|-------------|----------|
| 200 | Başarılı |
| 201 | Oluşturuldu (FastAPI default olarak 200 döndürür) |
| 404 | Not bulunamadı |
| 422 | Validation hatası |
| 500 | Sunucu hatası |

## 🔒 Güvenlik Notları

⚠️ **Production için önemli:**
- Authentication/Authorization ekleyin
- HTTPS kullanın
- CORS ayarlarını production domain'lerine göre yapın
- Rate limiting uygulayın
- Input validation'ı güçlendirin

## 🚀 Production Deployment

### Heroku için
1. `Procfile` oluşturun:
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

2. `requirements.txt`'i güncelleyin:
```
fastapi
uvicorn[standard]
sqlalchemy
python-dotenv
```

### Docker için
```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 📝 Changelog

### v1.0.0
- ✅ Temel CRUD operasyonları
- ✅ SQLite veritabanı entegrasyonu
- ✅ Pydantic model validasyonu
- ✅ Otomatik API dokümantasyonu

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

**Volkan Çarbuğa**
- 📧 Email: [email@example.com]
- 💼 LinkedIn: [LinkedIn Profili]
- 🐙 GitHub: [GitHub Profili]

## 📞 Destek

Sorunlarınız için:
- 🐛 Bug report: [Issues sayfası]
- 💬 Sorular: [Discussions sayfası]
- 📧 Email: [email@example.com]

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
