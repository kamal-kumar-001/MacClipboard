import AppKit
import ApplicationServices

@MainActor
final class CaretLocator {

    struct AnchorResult {
        let rect: NSRect
        let isCaret: Bool
    }

    /// Finds the best anchor screen rectangle for showing the clipboard popover.
    /// Prioritizes the active text insertion point (caret) or focused input element.
    /// If caret/input is unavailable, falls back to the current mouse cursor location.
    static func findBestAnchor() -> AnchorResult {
        // 1. Prompt for accessibility if not granted
        if !AXIsProcessTrusted() {
            let promptOption = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(promptOption)
        }

        // 2. Query focused input/caret rect
        if let inputRect = getFocusedInputScreenRect() {
            return AnchorResult(rect: inputRect, isCaret: true)
        }

        // 3. Fallback to mouse cursor position
        let mouseLocation = NSEvent.mouseLocation
        let mouseRect = NSRect(
            x: mouseLocation.x - 2,
            y: mouseLocation.y - 2,
            width: 4,
            height: 4
        )
        return AnchorResult(rect: mouseRect, isCaret: false)
    }

    /// Queries the macOS Accessibility API for the current text caret or focused input field bounds.
    static func getFocusedInputScreenRect() -> NSRect? {
        guard AXIsProcessTrusted() else {
            return nil
        }

        let systemWide = AXUIElementCreateSystemWide()

        // Strategy A: Query system-wide focused UI element directly
        var focusedElement: AXUIElement?
        var directElemVal: CFTypeRef?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &directElemVal) == .success,
           let val = directElemVal {
            focusedElement = (val as! AXUIElement)
        }

        // Strategy B: If direct query returned nil, query the focused application first
        if focusedElement == nil {
            var focusedAppVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppVal) == .success,
               let appVal = focusedAppVal {
                let appElem = (appVal as! AXUIElement)
                var appFocusedElemVal: CFTypeRef?
                if AXUIElementCopyAttributeValue(appElem, kAXFocusedUIElementAttribute as CFString, &appFocusedElemVal) == .success,
                   let elemVal = appFocusedElemVal {
                    focusedElement = (elemVal as! AXUIElement)
                }
            }
        }

        guard let element = focusedElement else {
            return nil
        }

        // Sub-strategy 1: Check selected text range bounds (caret / insertion point)
        if let caretRect = getCaretBounds(from: element) {
            return convertQuartzToCocoa(caretRect)
        }

        // Sub-strategy 2: Check input element's own frame (kAXPositionAttribute & kAXSizeAttribute)
        if let elementRect = getElementBounds(from: element) {
            return convertQuartzToCocoa(elementRect)
        }

        return nil
    }

    private static func getCaretBounds(from element: AXUIElement) -> CGRect? {
        var selectedRangeVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeVal) == .success,
              let rangeVal = selectedRangeVal else {
            return nil
        }

        var boundsVal: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeVal,
            &boundsVal
        ) == .success, let bVal = boundsVal else {
            return nil
        }

        var quartzRect = CGRect.zero
        guard AXValueGetValue(bVal as! AXValue, .cgRect, &quartzRect) else {
            return nil
        }

        guard !quartzRect.origin.x.isNaN, !quartzRect.origin.y.isNaN,
              quartzRect.origin.x > -10000, quartzRect.origin.y > -10000 else {
            return nil
        }

        return quartzRect
    }

    private static func getElementBounds(from element: AXUIElement) -> CGRect? {
        var posVal: CFTypeRef?
        var sizeVal: CFTypeRef?

        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posVal) == .success,
              let pVal = posVal,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeVal) == .success,
              let sVal = sizeVal else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero

        guard AXValueGetValue(pVal as! AXValue, .cgPoint, &point),
              AXValueGetValue(sVal as! AXValue, .cgSize, &size) else {
            return nil
        }

        guard size.width > 0 || size.height > 0 else {
            return nil
        }

        return CGRect(origin: point, size: size)
    }

    private static func convertQuartzToCocoa(_ quartzRect: CGRect) -> NSRect? {
        guard let primaryScreen = NSScreen.screens.first else {
            return nil
        }

        let primaryHeight = primaryScreen.frame.height
        let width = max(quartzRect.size.width, 2.0)
        let height = max(quartzRect.size.height, 18.0)
        let cocoaY = primaryHeight - quartzRect.origin.y - height

        return NSRect(
            x: quartzRect.origin.x,
            y: cocoaY,
            width: width,
            height: height
        )
    }
}
