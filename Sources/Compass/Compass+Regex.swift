import Foundation
import Hitch
import Spanker

internal var regexCache: [Hitch: NSRegularExpression] = [:]
internal var regexCacheLock = NSLock()
internal func getCachedRegex(_ pattern: Hitch) -> NSRegularExpression? {
    regexCacheLock.lock(); defer { regexCacheLock.unlock() }
    
    guard pattern.first == .forwardSlash && pattern.last == .forwardSlash else {
        Compass.print("Regex string must start and end with \"/\": \(pattern)")
        return nil
    }
    
    guard let subpattern = pattern.substring(1, pattern.count-1) else {
        Compass.print("Failed to extract subpattern from regex: \(pattern)")
        return nil
    }
    
    guard let regex = regexCache[pattern] else {
        do {
            let regex = try NSRegularExpression(pattern: subpattern.description, options: [])
            regexCache[pattern] = regex
            return regex
        } catch {
            Compass.print("Failure to parse \"\(pattern)\" as regex: \(error)")
            return nil
        }
    }
    return regex
}
