# Uygulama İkonları

İki uygulama da tek bir Swift betiğiyle üretilen, ortak paletli ikonlar kullanır:
mor-magenta zemin, mavi ışık ve açık mavi/beyaz vurgular.

| Uygulama | Rol | Tema | Konum |
| --- | --- | --- | --- |
| `imeds` | Gönderici | Uçan kağıt uçak + noktalı gönderim yolu | `imeds/Assets.xcassets/AppIcon.appiconset/` |
| `imedtv` | Alıcı | Sabit duran TV + gelen medya | `imeds/Assets.xcassets/tvOS App Icon & Top Shelf Image.brandassets/` |

## iPhone / iPad — `imeds`

- Tek kaynak: `AppIcon-1024.png` (1024×1024, alfa kanalı yok).
- `Contents.json` tek `universal / ios / 1024x1024` girdisi içerir.
- Derleme çıktısında `AppIcon60x60@2x.png` ve `Assets.car` üretilir;
  `Info.plist` içinde `CFBundleIcons → CFBundleIconName = AppIcon` görünür.

## Apple TV — `imedtv`

- Xcode 26'nın beklediği katmanlı yapı kullanılır:
  `<stack>.imagestack/ <Layer>.imagestacklayer/Content.imageset/`.
- Katmanlar (önden arkaya):
  - `Front`: TV ekranı ve gelen medya.
  - `Middle`: mavi ışık.
  - `Back`: mor-magenta gradyan ve vinyet.
- App Store vitrini: `App Icon - App Store.imagestack` → 1280×768 (1x).
- Apple TV ana ekranı: `App Icon.imagestack` → 400×240 (1x) + 800×480 (2x).
- Build setting: `ASSETCATALOG_COMPILER_APPICON_NAME = "tvOS App Icon & Top Shelf Image"`.

> tvOS marka varlıkları düz (`role` tabanlı) yapıyla derlenmez; `imagestack`
> katmanları zorunludur. `actool` bu yapıyı `Assets.car` içine başarıyla paketler.

## İkonları Yeniden Üretmek

```bash
swift Tools/make-icons.swift "imeds/Assets.xcassets"
open Tools/imeds-icon-preview.png
open Tools/imedtv-icon-preview.png
```

Betik şunları yeniden oluşturur:

- `imeds/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (opak, 1024×1024)
- `imeds/Assets.xcassets/tvOS App Icon & Top Shelf Image.brandassets/` (katmanlı)
- `Tools/imeds-icon-preview.png` ve `Tools/imedtv-icon-preview.png`
