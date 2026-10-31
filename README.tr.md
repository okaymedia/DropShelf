🇬🇧 [English](README.md)

# 🗂️ DropShelf

**Şu anda ihtiyacınız olan dosyalar için küçük bir raf.**


| Ne yapar | Nasıl |
| --- | --- |
| Rafa ekle | Dosyaları veya klasörleri rafa sürükleyin. |
| Raftan çıkar | Öğeleri raftan Finder'a veya başka bir uygulamaya sürükleyin. |
| Göster veya gizle | ⌥⌘D tuşlarına basın (değiştirilebilir). |
| Hızlı Bakış | Bir öğe seçip Boşluk tuşuna basın. |
| Sırala veya temizle | Rafa sağ tıklayın. |
| Eksik dosyaları bul | Eksik bir öğeyi yeniden bağlamak için Bul seçeneğini kullanın. |

- Orijinal dosyalara dokunulmaz; raf yalnızca referansları saklar.
- Menü çubuğunda yaşar; isteğe bağlı olarak girişte açılır.
- İngilizce ve Türkçe, sistem diline göre otomatik seçilir.
- Ağ erişimi veya veri toplama yoktur.
- Apple Silicon ve Intel üzerinde macOS 14 veya üstü gerektirir.

## Kurulum

Mac App Store — bağlantı yakında.

## Kaynak koddan derleme

Xcode ve XcodeGen gerektirir:

```sh
xcodegen generate
xcodebuild -project DropShelf.xcodeproj -scheme DropShelf -configuration Debug -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Alternatif olarak `xcodegen generate` çalıştırıp `DropShelf.xcodeproj` dosyasını Xcode'da açın.

## Gizlilik

DropShelf raf referanslarını ve güvenlik kapsamlı yer imlerini Application Support içinde yerel olarak saklar. Veri toplamaz ve ağ yetkisi yoktur.

## Lisans

MIT. Bkz. [LICENSE](LICENSE).
