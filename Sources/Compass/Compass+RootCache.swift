import Foundation
import Hitch
import Spanker

// Records requests on a "per root index" basis
public class RegexCache {
    @usableFromInline var testByIndexCache: [Int: Bool] = [:]
    @usableFromInline var matchesByIndexCache: [Int: [HalfHitch]] = [:]
    
    @usableFromInline
    init() { }
}

public class RootCache {
    
    @usableFromInline var regexCache: [String: RegexCache] = [:]
    
    @inlinable
    func cache(regex: CompassRegex) -> RegexCache {
        if let cached = regexCache[regex.uniqueId] {
            return cached
        }
        let cached = RegexCache()
        regexCache[regex.uniqueId] = cached
        return cached
    }
    
    @inlinable
    func test(regex: CompassRegex,
              index: Int,
              value: HalfHitch) -> Bool {
        let regexCache = cache(regex: regex)
        if let cached = regexCache.testByIndexCache[index] {
            return cached
        }
        
        let result = regex.test(against: value)
        regexCache.testByIndexCache[index] = result
        return result
    }
    
    @inlinable
    func matches(regex: CompassRegex,
                 index: Int,
                 value: HalfHitch) -> [HalfHitch] {
        let regexCache = cache(regex: regex)
        if let cached = regexCache.matchesByIndexCache[index] {
            return cached
        }
        
        let result = regex.matches(against: value)
        regexCache.matchesByIndexCache[index] = result
        return result
    }
}
