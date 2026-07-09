import SwiftUI
import AppKit
import KeyHolder
import Magnet

struct ShortcutView: NSViewRepresentable {
    typealias NSViewType = RecordView

    let shortcutsInteractor: ShortcutsInteractor
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
            parent.shortcutsInteractor.update(keyCombo: keyCombo)
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
