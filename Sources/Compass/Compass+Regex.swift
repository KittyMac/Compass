import Foundation
import Hitch
import Spanker

internal var regexCache: [Hitch: NSRegularExpression] = [:]
internal var regexCacheLock = NSLock()
internal func isRegex(_ pattern: Hitch) -> (Hitch, Bool, Bool, Bool)? {
    guard pattern.first == .forwardSlash else { return nil }
    
    // regex supports igm flags
    let flags: HalfHitch = "igm"
    let count = pattern.count
    if pattern.last == .forwardSlash,
       let subpattern = pattern.substring(1, pattern.count-1) {
        return (subpattern, false, false, false)
    }
    
    if count-2 > 0 &&
        pattern[count-2] == .forwardSlash &&
        flags.contains(pattern[count-1]),
       let subpattern = pattern.substring(1, pattern.count-2),
       let subflags = pattern.substring(pattern.count-2, pattern.count) {
        return (subpattern, subflags.contains(.i), subflags.contains(.g), subflags.contains(.m))
    }
    if count-3 > 0 &&
        pattern[count-3] == .forwardSlash &&
        flags.contains(pattern[count-1]) &&
        flags.contains(pattern[count-2]),
       let subpattern = pattern.substring(1, pattern.count-3),
       let subflags = pattern.substring(pattern.count-3, pattern.count) {
        return (subpattern, subflags.contains(.i), subflags.contains(.g), subflags.contains(.m))
    }
    if count-4 > 0 &&
        pattern[count-4] == .forwardSlash &&
        flags.contains(pattern[count-1]) &&
        flags.contains(pattern[count-2]) &&
        flags.contains(pattern[count-3]),
       let subpattern = pattern.substring(1, pattern.count-4),
       let subflags = pattern.substring(pattern.count-4, pattern.count) {
        return (subpattern, subflags.contains(.i), subflags.contains(.g), subflags.contains(.m))
    }
    
    return nil
}
internal func getCachedRegex(_ pattern: Hitch) -> NSRegularExpression? {
    regexCacheLock.lock(); defer { regexCacheLock.unlock() }
        
    guard let regex = regexCache[pattern] else {
        guard let (subpattern, ignoreCase, _, _) = isRegex(pattern) else {
            Compass.print("Regex string must start and end with \"/\": \(pattern)")
            return nil
        }
        
        var options: NSRegularExpression.Options = []
        if ignoreCase {
            options.insert(.caseInsensitive)
        }
        
        do {
            let regex = try NSRegularExpression(pattern: subpattern.description, options: options)
            regexCache[pattern] = regex
            return regex
        } catch {
            Compass.print("Failure to parse \"\(pattern)\" as regex: \(error)")
            return nil
        }
    }
    return regex
}
