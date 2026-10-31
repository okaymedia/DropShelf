🇹🇷 [Türkçe](README.tr.md)

# 🗂️ DropShelf

**A little shelf for the files you need right now.**


| What it does | How |
| --- | --- |
| Drop in | Drag files or folders onto the shelf. |
| Drag out | Drag items from the shelf to Finder or another app. |
| Show or hide | Press ⌥⌘D (customizable). |
| Quick Look | Select an item and press Space. |
| Sort or clear | Right-click the shelf. |
| Find missing files | Use Locate to reconnect a missing item. |

- Original files are never touched; the shelf stores references only.
- Lives in the menu bar, with an optional launch at login.
- English and Turkish follow the system language automatically.
- No network access or data collection.
- macOS 14 or later, on Apple Silicon and Intel.

## Installation

Mac App Store — link coming soon.

## Build from source

Requires Xcode and XcodeGen:

```sh
xcodegen generate
xcodebuild -project DropShelf.xcodeproj -scheme DropShelf -configuration Debug -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Alternatively, run `xcodegen generate` and open `DropShelf.xcodeproj` in Xcode.

## Privacy

DropShelf stores shelf references and security-scoped bookmarks locally in Application Support. It collects no data and has no network entitlement.

## License

MIT. See [LICENSE](LICENSE).
