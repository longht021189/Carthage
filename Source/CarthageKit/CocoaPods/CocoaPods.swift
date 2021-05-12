import Foundation
import ReactiveSwift

public final class CocoaPods {
    private init() {}
    
    public static let specsGitURL = GitURL("https://github.com/CocoaPods/Specs.git")
    
    private static var specsRepositoryURL: URL!
    private static var dependencySpecPath: [String : URL] = [:]
    private static var dependencyVersions: [String : [String]] = [:]
    
    public static func cloneOrPullSpecs(destinationURL: URL, forceUpdate: Bool = false) -> SignalProducer<URL, CarthageError> {
        let fileManager = FileManager.default
        let specsRepositoryURL = destinationURL.appendingPathComponent("Specs", isDirectory: true)
        
        CocoaPods.specsRepositoryURL = specsRepositoryURL
        
        return isGitRepository(specsRepositoryURL)
            .flatMap(.merge) { isRepository -> SignalProducer<URL, CarthageError> in
                if isRepository {
                    guard !forceUpdate else {
                        return SignalProducer<URL, CarthageError>.init(value: specsRepositoryURL)
                    }
                    
                    return pullRepository(specsRepositoryURL)
                        .map { _ -> URL in specsRepositoryURL }
                } else {
                    _ = try? fileManager.removeItem(at: specsRepositoryURL)
                    
                    return cloneRepository(self.specsGitURL, specsRepositoryURL, isBare: false)
                        .map { _ -> URL in specsRepositoryURL }
                }
            }
    }
    
    public static func findDependencyGitURL(dependency: Dependency, destinationURL: URL) -> SignalProducer<GitURL, CarthageError> {
        guard dependency.isPod else {
            return SignalProducer<GitURL, CarthageError>(error: CarthageError.unknownDependencies([dependency.description]))
        }
        
        return cloneOrPullSpecs(destinationURL: destinationURL)
            .flatMap(.merge) { specsRepositoryURL -> SignalProducer<URL, CarthageError> in
                if let url = CocoaPods.dependencySpecPath[dependency.name] {
                    return SignalProducer<URL, CarthageError>.init(value: url)
                }
                
                let urlSpecs = specsRepositoryURL.appendingPathComponent("Specs", isDirectory: true)
                
                if let specsPath = findPodSpec(url: urlSpecs, name: dependency.name) {
                    let url = specsRepositoryURL.appendingPathComponent("Specs/\(specsPath)", isDirectory: true)
                    CocoaPods.dependencySpecPath[dependency.name] = url
                    return SignalProducer<URL, CarthageError>.init(value: url)
                } else {
                    fatalError("Not implement") // Spec not found
                }
            }
            .map { path -> GitURL in
                if let latestVersion = findLatestVersion(path: path.path) {
                    let jsonPath = path.appendingPathComponent("\(latestVersion)/\(dependency.name).podspec.json")
                    let jsonDecoder = JSONDecoder()
                    
                    if let jsonData = try? Data(contentsOf: jsonPath),
                       let json = try? jsonDecoder.decode(PodSpecInfo.self, from: jsonData),
                       let gitURL = json.source.git {
                        return GitURL(gitURL)
                    } else {
                        fatalError("Not implement") // Can not open file, or decode error
                    }
                } else {
                    fatalError("Not implement") // Spec not found
                }
            }
    }
    
    private static func findLatestVersion(path: String) -> String? {
        let versions: [(SemanticVersion, String)]
        
        do {
            versions = try FileManager.default.contentsOfDirectory(atPath: path)
                .compactMap { str -> (SemanticVersion, String)? in
                    if let value = SemanticVersion.from(PinnedVersion(str)).value {
                        return (value, str)
                    } else {
                        return nil
                    }
                }
        } catch {
            return nil
        }
        
        let latestVersion = versions.max { left, right -> Bool in
            return left.0 < right.0
        }
        
        return latestVersion?.1
    }

    private static func findPodSpec(url: URL, name: String, depth: Int = 0) -> String? {
        let directoryContents: [String]
        
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return nil
        }
        
        if depth >= 3 {
            for item in directoryContents {
                if item == name {
                    return item
                }
            }
        } else {
            for item in directoryContents {
                let childUrl = url.appendingPathComponent(item, isDirectory: true)
                if let value = findPodSpec(url: childUrl, name: name, depth: depth + 1) {
                    return "\(item)/\(value)"
                }
            }
        }
        
        return nil
    }
}
