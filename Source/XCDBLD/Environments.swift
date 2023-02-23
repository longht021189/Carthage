import Foundation

public protocol Environments {
    var buildArguments: [String]? { get }
    var forcedMachOType: MachOType? { get }
}

public func getEnvironments() -> Environments {
    if let e = envs  {
        return e
    } else {
        let e = Envs()
        envs = e
        return e
    }
}

fileprivate var envs: Envs? = nil

fileprivate struct Envs : Environments {
    let isBuildStaticOnly = ProcessInfo.processInfo
        .environment["BUILD_STATIC_ONLY"] == "true"
    
    var forcedMachOType: MachOType? {
        get {
            if isBuildStaticOnly {
                return MachOType.staticlib
            } else {
                return nil
            }
        }
    }
    
    var buildArguments: [String]? {
        get {
            if isBuildStaticOnly {
                return [
                    "MACH_O_TYPE=\(MachOType.staticlib)",
                    "DEBUG_INFORMATION_FORMAT=dwarf"
                ]
            } else {
                return nil
            }
        }
    }
}
