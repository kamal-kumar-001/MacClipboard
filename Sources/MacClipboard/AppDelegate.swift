import AppKit
import SwiftUI
import Carbon.HIToolbox
import ApplicationServices

@MainActor(unsafe)
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var monitor: ClipboardMonitor!
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var anchorWindow: AnchorWindow?
    private var previousApp: NSRunningApplication?

    private let store = ClipboardStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        monitor = ClipboardMonitor(store: store)

        setupPopover()
        setupGlobalShortcut()
        monitor.start()
    }

    private func setupGlobalShortcut() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else {
                return noErr
            }

            let delegate = Unmanaged<AppDelegate>
                .fromOpaque(userData)
                .takeUnretainedValue()

            Task { @MainActor in
                delegate.togglePopover(fromMenuBar: false)
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4D434C50),
            id: 1
        )

        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Clipboard"
        )
        button.image?.isTemplate = true
        button.action = #selector(menuBarButtonClicked)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 360, height: 470)

        let contentView = ClipboardPopover(
            onClose: { [weak self] in
                self?.closePopover()
            },
            onCopyAndPaste: { [weak self] item, pasteImmediately in
                self?.handleItemSelection(item, pasteImmediately: pasteImmediately)
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )

        popover.contentViewController = NSHostingController(
            rootView: contentView
        )
    }

    @objc
    private func menuBarButtonClicked() {
        togglePopover(fromMenuBar: true)
    }

    @objc
    func togglePopover(fromMenuBar: Bool = false) {
        if popover.isShown {
            closePopover()
            return
        }

        // Store previously focused app so we can return focus and paste into it
        previousApp = NSWorkspace.shared.frontmostApplication

        if fromMenuBar, let button = statusItem.button {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        } else {
            let anchor = CaretLocator.findBestAnchor()
            let window = AnchorWindow(targetRect: anchor.rect)
            window.orderFront(nil)
            self.anchorWindow = window

            guard let contentView = window.contentView else { return }

            popover.show(
                relativeTo: contentView.bounds,
                of: contentView,
                preferredEdge: .minY
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    private func handleItemSelection(_ item: ClipboardItem, pasteImmediately: Bool) {
        monitor.ignoreNextClipboardChange()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let pasteboardItem = NSPasteboardItem()
        for (typeString, data) in item.representations {
            let type = NSPasteboard.PasteboardType(typeString)
            pasteboardItem.setData(data, forType: type)
        }
        pasteboard.writeObjects([pasteboardItem])

        // 1. Close popover
        popover.performClose(nil)

        // 2. Reactivate the previous application where user was typing
        let targetApp = previousApp
        targetApp?.activate(options: .activateIgnoringOtherApps)

        // 3. Automatically paste at input
        if pasteImmediately {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                Self.simulatePaste()
            }
        }
    }

    private static func simulatePaste() {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode = CGKeyCode(kVK_ANSI_V)
        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        usleep(25000) // 25ms hold duration to ensure target app processes key event
        keyUp.post(tap: .cghidEventTap)
    }

    private func closePopover() {
        popover.performClose(nil)
        previousApp?.activate(options: .activateIgnoringOtherApps)
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        anchorWindow?.orderOut(nil)
        anchorWindow = nil
        previousApp?.activate(options: .activateIgnoringOtherApps)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        monitor.stop()
    }
}
