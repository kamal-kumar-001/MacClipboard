import AppKit
import SwiftUI
import Carbon.HIToolbox

@MainActor(unsafe)
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    private var popover: NSPopover!

    private var monitor: ClipboardMonitor!

    private var hotKeyRef: EventHotKeyRef?

    private var eventHandlerRef: EventHandlerRef?

    private let store =
        ClipboardStore.shared

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        setupMenuBar()

        monitor =
            ClipboardMonitor(
                store: store
            )

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
                delegate.togglePopover()
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

        statusItem =
            NSStatusBar.system.statusItem(
                withLength: NSStatusItem.squareLength
            )

        guard
            let button = statusItem.button
        else {
            return
        }

        button.image =
            NSImage(
                systemSymbolName:
                    "doc.on.clipboard",
                accessibilityDescription:
                    "Clipboard"
            )

        button.image?.isTemplate = true

        button.action =
            #selector(togglePopover)

        button.target = self
    }

    private func setupPopover() {

        popover =
            NSPopover()

        popover.behavior =
            .transient

        popover.animates =
            true

        popover.contentSize =
            NSSize(
                width: 380,
                height: 520
            )

        let contentView =
            ClipboardPopover(
                onClose: { [weak self] in
                    self?.closePopover()
                },
                onCopy: { [weak self] in
                    self?.monitor.ignoreNextClipboardChange()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )

        popover.contentViewController =
            NSHostingController(
                rootView: contentView
            )
    }

    @objc
    private func togglePopover() {

        guard
            let button = statusItem.button
        else {
            return
        }

        if popover.isShown {

            popover.performClose(nil)

        } else {

            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )

            popover.contentViewController?
                .view
                .window?
                .becomeKey()

        }
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func closePopover() {

        popover.performClose(nil)
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        monitor.stop()
    }
}
