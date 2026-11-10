# Değişiklik Günlüğü

Bu proje [Semantic Versioning](https://semver.org/lang/tr/) kullanır.
Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) temellidir.

## [Yayınlanmadı]

- Share Extension ile Files uygulamasından doğrudan gönderim.
- Birden fazla dosyayı kuyruğa alıp sırayla gönderme.

## [1.0.0] - 2026-11-10

İlk herkese açık sürüm.

### Eklenenler

- iPhone/iPad (`imeds`) ve Apple TV (`imedtv`) için ortak SwiftUI projesi.
- MultipeerConnectivity ile internet gerektirmeyen, şifreli yerel ağ aktarımı
  (`imeds-transfer`).
- `Fotoğraf / Video Seç` (PHPicker) ve `Dosya Seç` (Files) menüleri.
- Gönderim ve alım için yüzde, `aktarılan / toplam` boyut ve anlık hız
  (`MB/sn`) göstergesi.
- Aktarım sırasında hem iPhone'da hem Apple TV'de **Vazgeç** desteği.
- İptal sonrası bilinen eşlere kademeli yeniden davet.
- Apple TV'de resim, video ve ses oynatma.
- Video oynatmadan önce `AVURLAsset` ile `isPlayable` ve video izi doğrulaması.
- Ses dosyaları için süre çubuğu ve Oynat/Duraklat düğmeli müzik kartı.
- Apple TV'de Geri tuşuyla medyayı küçültme ve son medyayı alt şeritte tutma.
- Alınan dosyaları `Documents/Received` altında saklama; klasör yoksa
  `Application Support/Received` ve `tmp/Received` yedekleri.
- Alınan fotoğraf/videoları galeriye kaydetme.
- Gönderici (uçan kağıt uçak) ve alıcı (sabit TV) için ayrı uygulama ikonları.
- Türkçe arayüz ve ayrıntılı README.

### Düzeltilenler

- `Label(systemName:)` yerine `Label(_:systemImage:)` kullanımı.
- `NetworkManager` içinde eksik `import Combine`.
- Yanlış `MCNearbyServiceAdvertiserDelegate` imzası.
- Security-scoped URL'in gönderimden önce geçici dosyaya kopyalanmaması.
- Gelen dosya adlarında `../` path traversal ve geçersiz karakter riski.
- Aynı adlı dosyaların üzerine yazılması; artık `dosya_1.ext` biçiminde
  benzersizleştiriliyor.
- İki cihazın aynı anda birbirini davet etmesinden doğan bağlantı yarışı.
- Peer seçimi ile gönderim/alım durumlarının birbirine karışması.
- Alım ilerlemesinin arayüze taşınmaması.
- Apple TV'de "kaydedilecek klasör yok" hatası.
- Video oynatıcının `fullScreenCover` ile boş açılması.
- Desteklenmeyen video codec'lerinde sessiz kalınması.
- Fotoğraf/video hazırlanırken arayüzün donması.
- Aktarım sırasında iPhone ekranının kapanıp Wi-Fi trafiğinin yavaşlaması.
- Apple TV'de Geri tuşunun uygulamadan çıkarması.

### Değişenler

- iPhone arayüzü `NavigationSplitView` yerine tek sütunlu `NavigationStack`
  yapısına geçirildi.
- Gönderim için seçilen medya, aktarım öncesi uygulama sanal alanına kopyalanır.
- Xcode 26'nın beklediği katmanlı (`imagestack`) tvOS marka ikonu yapısı.
