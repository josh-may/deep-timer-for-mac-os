import Foundation

enum AppResources {
    private static let bundleName = "DeepTimer_DeepTimer.bundle"

    static let bundle: Bundle? = {
        let fileManager = FileManager.default
        let candidateURLs = [
            Bundle.main.resourceURL?.appendingPathComponent(bundleName),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(bundleName)")
        ].compactMap { $0 }

        for url in candidateURLs where fileManager.fileExists(atPath: url.path) {
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            if bundle.bundleURL.lastPathComponent == bundleName {
                return bundle
            }

            if let nestedURL = bundle.resourceURL?.appendingPathComponent(bundleName),
               fileManager.fileExists(atPath: nestedURL.path),
               let nestedBundle = Bundle(url: nestedURL) {
                return nestedBundle
            }
        }

        return nil
    }()

    static func audioURL(named resourceName: String, supportedExtensions: [String]) -> URL? {
        let candidateBundles = ([bundle, Bundle.main] + Bundle.allBundles + Bundle.allFrameworks).compactMap { $0 }

        for bundle in candidateBundles {
            for fileExtension in supportedExtensions {
                if let url = bundle.url(forResource: resourceName, withExtension: fileExtension) {
                    return url
                }
            }
        }

        return nil
    }
}
