import AppKit
import Foundation

final class GlobalShortcutService {
    private var monitor: Any?
    var onAction: ((ShortcutAction) -> Void)?

    func start(with bindings: [ShortcutBinding]) {
        stop()
        let active = bindings.filter { $0.isEnabled && $0.keyCode != nil }
        guard !active.isEmpty else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            for binding in active {
                guard
                    let keyCode = binding.keyCode,
                    event.keyCode == keyCode,
                    flags.rawValue == binding.modifierFlags
                else { continue }
                self.onAction?(binding.action)
                break
            }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
