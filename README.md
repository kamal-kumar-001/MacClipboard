# MacClipboard

MacClipboard is an open-source macOS clipboard history app designed with an Android-style quick-paste workflow. It opens right at your active text cursor / caret (or mouse position) in any editor or app with an arrow notch pointing to where you type, complete with an instant search bar, category navigation, and one-key paste shortcuts.

## Features

- **Context-Aware Popover**: Opens right at your active text cursor / caret (with mouse cursor fallback) with an arrow notch pointing directly to your typing location.
- **Android-Style One-Key Paste**: Press `1` through `9` or `0` to instantly paste the corresponding entry into your active text input without any modifier keys.
- **Click to Auto-Paste**: Click any entry to automatically copy and paste it into whatever application you are working in.
- **Instant Search**: Filter clipboard history in real time by typing in the search bar.
- **Keyboard Navigation**:
  - `↑` / `↓` arrow keys with prominent high-contrast highlight.
  - `Return` / `Enter` to paste the selected item (`Option-Return` to copy to clipboard only).
  - `1` – `9` and `0` for instant item selection and paste.
  - `Escape` dismisses the popover and restores focus directly back to your text input.
- **Category Navigation Bar**: Quickly filter between All, Text & Code, Links, and Images using the bottom bar.
- **Clipboard History**: Tracks recent items with rich previews, URL detection, code snippet formatting, and image thumbnails.
- **Menu-Bar Utility**: Lightweight background utility (`Command-Option-V` global hotkey or menu-bar icon click).
- **Privacy First**: History is stored locally on your machine in Application Support.

## Requirements

- macOS 12 or newer
- Apple Silicon or Intel Mac
- Xcode Command Line Tools for building from source

## Accessibility Permission

To enable MacClipboard to position itself right at your text cursor in other apps (such as VS Code, Xcode, Notes, TextEdit, or browsers) and automatically paste (`⌘V`), grant it Accessibility permission:

1. Open **System Settings**.
2. Navigate to **Privacy & Security > Accessibility**.
3. Toggle **MacClipboard** ON (or click `+` and add `MacClipboard.app` from `/Applications`).

> If Accessibility is not enabled, the popover will fall back to opening at your mouse cursor and will copy items to the clipboard for manual pasting.

## Download and install the DMG

Download the latest installer here: [Download MacClipboard.dmg](MacClipboard.dmg)

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
- `MacClipboard.dmg` for sharing or downloading

To install it manually:

```bash
cp -R .build/release/MacClipboard.app /Applications/
open /Applications/MacClipboard.app
```

## Usage

- Press `Command-Option-V` anywhere to open the clipboard popover right at your text cursor.
- You can also click the clipboard icon in the menu bar.
- Press **`1` through `9`** to paste entries #1 through #9 instantly.
- Press **`0`** to paste entry #10 instantly.
- Click any entry to automatically paste it at your cursor.
- Type in the **Search** field to filter clipboard history in real time.
- Press `↑` / `↓` arrow keys to navigate entries, then press `Return` to paste.
- Press `Option-Return` to copy to clipboard without auto-pasting.
- Press `Escape` or click outside to dismiss the popover and return focus to your input.
- Switch between categories (All, Text, Links, Images) using the bottom bar icons.
- Hover over an item and click the `x` button to delete it from history.
- Use the **trash** button in the bottom bar to clear all history.
- Click the **power** button in the bottom bar to quit MacClipboard.

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
