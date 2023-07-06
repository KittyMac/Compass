import Foundation
import Hitch
import Spanker

public struct CompassRegex {
    public let regex: NSRegularExpression
    public let ignoreCase: Bool
    public let global: Bool
    public let multiline: Bool
    
    public init?(pattern: Hitch,
                 ignoreCase: Bool,
                 global: Bool,
                 multiline: Bool) {
        
        self.ignoreCase = ignoreCase
        self.global = global
        self.multiline = multiline
        
        var options: NSRegularExpression.Options = []
        if ignoreCase {
            options.insert(.caseInsensitive)
        }
        
        do {
            self.regex = try NSRegularExpression(pattern: pattern.description, options: options)
        } catch {
            Compass.print("Failure to parse \"\(pattern)\" as regex: \(error)")
            return nil
        }
    }
    
    public func matches(against: HalfHitch) -> [HalfHitch] {
        let againstAsString = against.description
        
        let range = NSRange(location: 0, length: againstAsString.count)
        var options: NSRegularExpression.MatchingOptions = []
        
        if global == false {
            options.insert(.anchored)
        }
        
        var results: [HalfHitch] = []
        let matches = regex.matches(in: againstAsString, options: options, range: range)
        if matches.count > 0 {
            
            for match in matches {
                for rangeIndex in 1..<match.numberOfRanges {
                    let matchRange = match.range(at: rangeIndex)
                    results.append(
                        HalfHitch(source: against,
                                  from: matchRange.lowerBound,
                                  to: matchRange.upperBound)
                    )
                }
                
            }
        }
        
        return results
    }
    
    public func remove(from: Hitch) {
        var againstAsString = from.description
                        
        while true {
            let range = NSRange(location: 0, length: againstAsString.count)
            let matches = regex.matches(in: againstAsString, range: range)
            guard matches.count > 0 else { break }
            
            // extract all ranges and ensure they are orders back to front
            var ranges: [NSRange] = []
            for match in matches {
                for idx in 0..<match.numberOfRanges {
                    ranges.append(match.range(at: idx))
                }
            }
            ranges.sort { lhs, rhs in
                return lhs.upperBound < rhs.lowerBound
            }
            for range in ranges {
                if let range = Range(range, in: againstAsString) {
                    againstAsString.removeSubrange(range)
                }
            }
        }
        
        from.replace(with: againstAsString)
    }
    
    public func test(against: HalfHitch) -> Bool {
        let againstAsString = against.description

        let range = NSRange(location: 0, length: againstAsString.count)
        var options: NSRegularExpression.MatchingOptions = []
        
        if global == false {
            options.insert(.anchored)
        }
        
        return regex.numberOfMatches(in: againstAsString, options: options, range: range) > 0
    }
}

extension CompassRegex: CustomStringConvertible {
    public var description: String {
        let hitch = Hitch()
        exportTo(hitch: hitch)
        return hitch.toString()
    }
    
    @discardableResult
    @inlinable
    public func exportTo(hitch: Hitch) -> Hitch {
        hitch.append(.forwardSlash)
        hitch.append(regex.pattern)
        hitch.append(.forwardSlash)
        if ignoreCase {
            hitch.append(.i)
        }
        if global {
            hitch.append(.g)
        }
        if multiline {
            hitch.append(.m)
        }
        return hitch
    }
}

internal var regexCache: [Hitch: CompassRegex] = [:]
internal var regexCacheLock = NSLock()
internal func parseRegex(_ pattern: Hitch) -> CompassRegex? {
    guard pattern.first == .forwardSlash else { return nil }
    
    // regex supports igm flags
    let flags: HalfHitch = "igm"
    let count = pattern.count
    if pattern.last == .forwardSlash,
       let subpattern = pattern.substring(1, pattern.count-1) {
        return CompassRegex(pattern: subpattern,
                            ignoreCase: false,
                            global: false,
                            multiline: false)
    }
    
    if count-2 > 0 &&
        pattern[count-2] == .forwardSlash &&
        flags.contains(pattern[count-1]),
       let subpattern = pattern.substring(1, pattern.count-2),
       let subflags = pattern.substring(pattern.count-2, pattern.count) {
        return CompassRegex(pattern: subpattern,
                            ignoreCase: subflags.contains(.i),
                            global: subflags.contains(.g),
                            multiline: subflags.contains(.m))
    }
    if count-3 > 0 &&
        pattern[count-3] == .forwardSlash &&
        flags.contains(pattern[count-1]) &&
        flags.contains(pattern[count-2]),
       let subpattern = pattern.substring(1, pattern.count-3),
       let subflags = pattern.substring(pattern.count-3, pattern.count) {
        return CompassRegex(pattern: subpattern,
                            ignoreCase: subflags.contains(.i),
                            global: subflags.contains(.g),
                            multiline: subflags.contains(.m))
    }
    if count-4 > 0 &&
        pattern[count-4] == .forwardSlash &&
        flags.contains(pattern[count-1]) &&
        flags.contains(pattern[count-2]) &&
        flags.contains(pattern[count-3]),
       let subpattern = pattern.substring(1, pattern.count-4),
       let subflags = pattern.substring(pattern.count-4, pattern.count) {
        return CompassRegex(pattern: subpattern,
                            ignoreCase: subflags.contains(.i),
                            global: subflags.contains(.g),
                            multiline: subflags.contains(.m))
    }
    
    return nil
}
internal func getCachedRegex(_ pattern: Hitch) -> CompassRegex? {
    regexCacheLock.lock(); defer { regexCacheLock.unlock() }
        
    guard let regex = regexCache[pattern] else {
        guard let regex = parseRegex(pattern) else {
            return nil
        }
        regexCache[pattern] = regex
        return regex
    }
    return regex
}
