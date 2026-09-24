# MacClipboard

MacClipboard is an open-source macOS menu-bar clipboard history app. It keeps recent clipboard items available in a Spotlight-style popover and supports text, rich text, HTML, URLs, and images.

## Features

- Clipboard history with up to 10 recent items
- Image previews
- Text, rich-text, HTML, URL, and image detection
- Relative timestamps such as `just now` and `2 minutes ago`
- Click an item to restore it to the clipboard
- `Command-Option-V` global shortcut to open the clipboard popover
- Menu-bar utility with no Dock icon
- Local history storage in Application Support

## Requirements

- macOS 12 or newer
- Apple Silicon or Intel Mac
- Xcode Command Line Tools for building from source

## Download and install the DMG

Download the latest installer here: [Download MacClipboard.dmg](.build/release/MacClipboard.dmg)

For a public GitHub release, upload that file to the repository's **Releases** page and share the release download URL.

1. Download `MacClipboard.dmg`.
2. Double-click the downloaded DMG.
3. Drag the MacClipboard icon onto the Applications folder icon.
4. Open Applications and double-click MacClipboard.
5. The clipboard icon will appear in the menu bar.

The first launch may show a macOS confirmation because this app is currently unsigned and not notarized. Open the app from Finder, then choose **Open**. If macOS blocks it, open **System Settings > Privacy & Security** and choose **Open Anyway** for MacClipboard.

## Build locally

From the repository root:

```bash
./Scripts/build-app.sh
```

The script creates:

- `.build/release/MacClipboard.app`
- `.build/release/MacClipboard.dmg`

The app bundle is also opened automatically after a successful build. To install it manually:

```bash
cp -R .build/release/MacClipboard.app /Applications/
open /Applications/MacClipboard.app
```

The script uses Swift Package Manager when full Xcode is selected. On machines with only Command Line Tools, it uses `swiftc` directly.

## Usage

- Click the clipboard icon in the menu bar, or press `Command-Option-V`.
- Click an item to restore it to the system clipboard.
- Hover over an item and click the x button to remove it.
- Use **Clear All** to remove the saved history.
- Click the power button in the popover footer to quit MacClipboard.

The global shortcut works while MacClipboard is running.

## Start automatically at login

1. Open **System Settings**.
2. Click **General**.
3. Click **Login Items & Extensions** (called **Login Items** on some macOS versions).
4. Under **Open at Login**, click `+`.
5. Select **MacClipboard** from Applications and click **Open**.

MacClipboard will now start automatically every time you log in. To disable this later, return to the same screen and turn MacClipboard off or remove it from the list.

## Data and privacy

Clipboard history is stored locally at:

```text
~/Library/Application Support/MacClipboard/clipboard-history.json
```

The current version does not encrypt this file and does not upload clipboard contents.

## Open source

MacClipboard is open source. Contributions, bug reports, and feature requests are welcome through the project's issue tracker and pull requests.

Before publishing a release for general distribution, configure an Apple Developer signing identity, notarization, a stable bundle identifier, and a custom app icon.
