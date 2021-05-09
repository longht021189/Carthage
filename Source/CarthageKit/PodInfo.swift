public struct PodInfo {
    public let name: String
}

extension PodInfo : Equatable {
    
}

extension PodInfo : Hashable {
    
}

public struct PodSpecInfo : Codable {
    let source: PodSpecSource
}

public struct PodSpecSource : Codable {
    let git: String?
    let tag: String?
}

public struct VersionWrapper : Equatable {
    let version: SemanticVersion
    let raw: String
}
