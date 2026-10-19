# DockMate for macOS 🪟

**DockMate**, macOS için geliştirilmiş yerel (native), hafif ve arka planda çalışan modern bir Dock pencere önizleme ve yönetim aracıdır. Windows görev çubuğundaki veya MacEnhance DockMate/DockDoor araçlarındaki gibi, macOS Dock'taki simgelerin üzerine mouse ile gelindiğinde pencerelerin canlı önizlemelerini ve kontrollerini sunar.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🌟 Öne Çıkan Özellikler

- **Canlı Dock Önizlemeleri (Hover Previews):** Dock'taki herhangi bir uygulamanın üzerine mouse ile gelindiğinde açık pencerelerin anlık küçük resim önizlemelerini (thumbnails) şık bir kayan pencerede (`NSPanel`) gösterir.
- **Doğrudan Pencere Yönetimi:**
  - **Öne Getirme (Focus):** Önizleme kartına tıklayarak pencereyi anında en öne getirin.
  - **Pencereyi Kapatma (Close):** Kartın sağ üstündeki kırmızı buton ile tek tıkla pencereyi kapatın.
  - **Küçültme (Minimize):** Sarı buton ile pencereyi küçültün veya eski haline getirin.
- **Apple Music & Spotify Medya Entegrasyonu:** Müzik uygulamalarının üzerine gelindiğinde çalan şarkı adı, sanatçı, albüm ve Oynat/Duraklat, İleri, Geri butonları sunan mini oynatıcı kartı.
- **Arka Planda Sessiz Çalışma (`LSUIElement`):** Dock'ta gereksiz yer kaplamaz, macOS menü çubuğunda (Menu Bar) zarif bir durum simgesiyle yer alır.
- **Özelleştirilebilir Ayarlar (Preferences Window):**
  - Kart boyutu: Küçük (220px), Orta (300px), Büyük (380px).
  - Fare bekleme gecikmesi (Hover Delay): 50ms - 800ms.
  - Otomatik kapanma süresi (Dismiss Delay): 100ms - 600ms.
  - Küçültülmüş pencereleri gizleme/gösterme seçeneği.
- **Modern Ekran Yakalama (`ScreenCaptureKit`):** macOS 14+ Sonoma ve Sequoia ile tam uyumlu resmi ScreenCaptureKit API'si kullanır.
- **Sıfır Telemetri & Tam Gizlilik:** Tamamen yerel çalışır, internete hiçbir veri göndermez.

---

## 🚀 Hızlı Başlangıç

### 1. Uygulamayı Başlatma

Terminal üzerinden doğrudan oluşturulmuş `.app` paketini açabilirsiniz:

```bash
open DockMate.app
```

Veya Finder üzerinden `DockMate.app` üzerine çift tıklayabilirsiniz.

### 2. Gerekli macOS İzinleri

DockMate'in doğru şekilde çalışabilmesi için macOS Sistem Ayarları'ndan 2 izne ihtiyaç vardır:

1. **Erişilebilirlik (Accessibility):** Dock simgelerinin konumunu ve pencerelerin durumlarını tespit etmek, kapatma/küçültme eylemlerini gerçekleştirmek için.
   - *Sistem Ayarları > Gizlilik ve Güvenlik > Erişilebilirlik > DockMate*
2. **Ekran Kaydı (Screen Recording):** Canlı pencere küçük resimlerini (live thumbnail preview) render etmek için.
   - *Sistem Ayarları > Gizlilik ve Güvenlik > Ekran Kaydı > DockMate*

> **Not:** Uygulama ilk açıldığında izin durumunu otomatik olarak denetler ve menü çubuğundaki simgeden **"İzin ve Kurulum Sihirbazı..."** penceresini açarak tek tıkla sistem ayarlarını açmanızı sağlar.

---

## 🛠️ Proje Mimarisi

```
dockmate/
├── Package.swift                    # Swift Package Manager tanımı (macOS 14+)
├── build_app.sh                     # Otomatik derleme ve .app paketleme betiği
├── DockMate.app/                    # Derlenmiş, imzalanmış macOS uygulaması
├── Resources/
│   ├── Info.plist                   # LSUIElement ve izin tanımları
│   ├── AppIcon.icns                 # macOS standartlarında squircle ikon
│   └── AppIcon.png                  # Yüksek çözünürlüklü kaynak görsel
└── Sources/
    └── DockMate/
        ├── Main.swift               # @main uygulama giriş noktası
        ├── AppDelegate.swift        # Yaşam döngüsü ve servis başlatıcı
        ├── Models/
        │   ├── DockItem.swift       # Dock simgeleri modeli (koordinatlar & PID)
        │   ├── WindowInfo.swift     # Açık pencereler ve küçük resimler modeli
        │   └── MediaTrackInfo.swift # Müzik oynatıcı durum modeli
        ├── Core/
        │   ├── DockDetector.swift   # com.apple.dock Accessibility tarayıcısı
        │   ├── DockTracker.swift    # Fare hareketi, bekleme süresi ve koordinasyon
        │   ├── WindowEngine.swift   # ScreenCaptureKit & AX pencere yakalayıcı
        │   ├── MediaController.swift# Apple Music & Spotify denetleyicisi
        │   └── PermissionManager.swift # Sistem izinleri yöneticisi
        ├── UI/
        │   ├── PreviewPanel.swift   # Kayan önizleme penceresi (NSPanel)
        │   ├── DockPreviewContainerView.swift # SwiftUI önizleme kapsayıcısı
        │   ├── WindowPreviewCardView.swift    # Tekil pencere kartı & butonlar
        │   ├── MediaPreviewCardView.swift     # Müzik çalar önizleme kartı
        │   ├── StatusMenuController.swift     # Menü çubuğu denetleyicisi
        │   ├── PreferencesView.swift          # Kapsamlı ayarlar penceresi
        │   └── OnboardingView.swift           # İzin ve karşılama sihirbazı
        └── Helpers/
            ├── SettingsManager.swift          # UserDefaults ayar yönetimi
            └── GeometryHelpers.swift          # Koordinat dönüşümleri ve panel konumu
```

---

## 🔨 Yeniden Derleme ve Paketleme

Kod üzerinde değişiklik yaptığınızda uygulamayı tek bir komutla yeniden derleyebilirsiniz:

```bash
./build_app.sh
```

Bu betik:
1. Swift projesini `release` modunda optimize ederek derler.
2. `DockMate.app` klasör yapısını kurar (`Contents/MacOS`, `Contents/Resources`).
3. `Info.plist` ve `AppIcon.icns` dosyalarını dahil eder.
4. macOS Gatekeeper uyumluluğu için yerel ad-hoc kod imzalaması yapar.

---

## ⚙️ Menü Çubuğu Kısayolları

Menü çubuğundaki DockMate simgesine tıkladığınızda:
- **● Durum: Aktif / Duraklatıldı:** Dock izlemeyi anında açıp kapatabilirsiniz.
- **Önizleme Testini Tetikle (Cmd+T):** Fareyi Dock'a götürmeden de önizleme panelini test edebilirsiniz.
- **Dock Simgelerini Yeniden Tara (Cmd+R):** Yeni açılan veya kapanan uygulamaları anında yeniler.
- **Ayarlar... (Cmd+,):** Boyut, gecikme ve görünüm seçeneklerini yapılandırabilirsiniz.
- **İzin ve Kurulum Sihirbazı:** Eksik izinleri kontrol edip tek tıkla açabilirsiniz.
- **Çıkış Yap (Cmd+Q):** Uygulamayı tamamen sonlandırır.
