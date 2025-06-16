import ScriptingBridge

@objc protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: (any SBApplicationDelegate)? { get set }
    var isRunning: Bool { @objc(isRunning) get }
}
