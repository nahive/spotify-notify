import SwiftUI
import AppKit
import KeyHolder
import Magnet

struct ShortcutView: NSViewRepresentable {
    typealias NSViewType = RecordView

    let notificationsInteractor: NotificationsInteractor
    let defaultsInteractor: DefaultsInteractor

    func makeNSView(context: Context) -> RecordView {
        let view = RecordView(frame: .zero)
        view.cornerRadius = 5
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ recordView: RecordView, context: Context) {
        recordView.keyCombo = defaultsInteractor.shortcut
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    class Coordinator: NSObject, @preconcurrency RecordViewDelegate {
        var parent: ShortcutView

        init(parent: ShortcutView) {
            self.parent = parent
        }

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            self.parent.defaultsInteractor.shortcut = keyCombo

            if let keyCombo {
                let hotKey = HotKey(identifier: "showKey", keyCombo: keyCombo) { key in
                    self.parent.notificationsInteractor.forceShowNotification()
                }
                HotKeyCenter.shared.register(with: hotKey)
            } else {
                HotKeyCenter.shared.unregisterAll()
            }
        }

        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
            true
        }

        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
            true
        }

        func recordViewDidEndRecording(_ recordView: RecordView) {
            // nothing
        }
    }
}
