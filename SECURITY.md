# Güvenlik Politikası

## Kapsam

`imeds` ve `imedtv` tamamen yerel ağ üzerinde çalışır:

- Veriler üçüncü taraf bir sunucuya gönderilmez.
- Analitik, reklam veya izleme kodu yoktur.
- `MCSession` aktarımı `encryptionPreference: .required` ile şifrelenir.
- Alınan dosya adları temizlenir; `../` gibi path traversal girişimleri engellenir.

## Desteklenen Sürümler

Yalnızca en son sürüm güvenlik düzeltmesi alır.

| Sürüm | Destek |
| --- | --- |
| 1.x | Evet |
| < 1.0 | Hayır |

## Güvenlik Açığı Bildirimi

Lütfen güvenlik açığını herkese açık bir issue olarak paylaşmayın.
GitHub deposunda **Security → Report a vulnerability** yolunu kullanarak özel
bildirim açın. Bildiriminizde etkilenen hedefi (`imeds` veya `imedtv`), sürümü
ve yeniden üretme adımlarını belirtin.

Makul süre içinde yanıt verilir ve düzeltme yayınlandıktan sonra kredi
verilmesi talep edilebilir.
