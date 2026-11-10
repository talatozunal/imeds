# imeds

Bu klasör, iPhone/iPad ve Apple TV arasında yerel ağ üzerinden dosya aktaran imeds
projesinin kaynak kodlarını içerir.

## Hedefler
- imeds (iOS 17+): gönderici/alıcı arayüzü
- imedtv (tvOS 17+): Apple TV alıcı ekranı

## Dosyalar
1. ImedsApp.swift: Uygulama giriş noktası (iOS/tvOS ayrımı).
2. Models.swift: Dosya modeli ve medya tipi algılama.
3. NetworkManager.swift: MultipeerConnectivity ağ motoru, dosya kaydetme ve galeri.
4. ContentView.swift: iOS arayüzü.
5. AppleTVView.swift: tvOS alıcı arayüzü.
6. FilePicker.swift: iOS dosya seçici köprüsü.

## Info.plist İzinleri
- NSLocalNetworkUsageDescription
- NSBonjourServices: _imeds-transfer._tcp ve _imeds-transfer._udp
- NSPhotoLibraryAddUsageDescription

Alınan dosyalar Documents/Received/ altında tutulur.
