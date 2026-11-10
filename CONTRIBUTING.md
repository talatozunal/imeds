# Katkı Rehberi

Katkılarınız için teşekkürler. Bu proje iki SwiftUI hedefinden oluşur:

- `imeds` → iOS 17+ (gönderici/alıcı)
- `imedtv` → tvOS 17+ (Apple TV alıcı)

## Geliştirme Ortamı

- macOS ve Xcode 16 veya üzeri
- Harici bağımlılık yok; proje yalnızca Apple çatısını kullanır
- Gerçek cihazda test için bir iPhone ve Apple TV önerilir

```bash
git clone https://github.com/talatozunal/imeds.git
cd imeds
open imeds.xcodeproj
```

Xcode'da iki hedef için de **Signing & Capabilities → Team** seçin.
Depoda `DEVELOPMENT_TEAM` bilgisi bilinçli olarak tutulmaz.

## Derleme ve Doğrulama

Değişiklikten sonra iki hedefi de derleyin:

```bash
xcodebuild -project imeds.xcodeproj -scheme imeds \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project imeds.xcodeproj -scheme imedtv \
  -sdk appletvsimulator -destination 'generic/platform=tvOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Ağ davranışını test ederken iki simülatörü birlikte çalıştırın. Multipeer
bağlantısı simülatörde zaman zaman gecikebilir; gerçek cihaz testi daha güvenilirdir.

## Pull Request Kuralları

- Değişikliği tek bir konuya odaklayın.
- Kullanıcıya görünen metinler Türkçe olmalıdır.
- Yeni dosya türü desteği eklerken `Models.swift` içindeki listeyi ve
  `UTType` yedeğini birlikte güncelleyin.
- Ağ protokolünü değiştirirseniz iki hedefi de aynı PR'da güncelleyin;
  `serviceType` (`imeds-transfer`) iki uygulamada aynı kalmalıdır.
- `README.md`, `README.en.md` ve gerekirse `CHANGELOG.md` dosyalarını güncelleyin.

## Hata Bildirimi

Lütfen şunları ekleyin:

- Cihaz ve işletim sistemi sürümü (ör. iPhone 15 / iOS 18.2, Apple TV 4K / tvOS 18)
- Xcode sürümü
- Hatayı yeniden üretme adımları
- Varsa ekran görüntüsü ve `imeds`/`imedtv` birleşik günlük kaydı
  (`subsystem == "com.talat.imeds"`)
