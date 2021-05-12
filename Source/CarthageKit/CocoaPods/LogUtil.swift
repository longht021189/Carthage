public func log(msg: String) {
    #if DEBUG
    print(">>>> \(msg)")
    #endif
}
