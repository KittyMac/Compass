import Foundation
import Hitch
import Spanker

extension Query {
    
    @inlinable @inline(__always)
    func capture(key: Hitch,
                 value: Hitch,
                 matches: JsonElement) {
        guard let existing: JsonElement = matches[key] else {
            matches.set(key: key.halfhitch(), value: JsonElement(unknown: [value]))
            return
        }
        existing.append(value: value)
    }
        
    @discardableResult
    @inlinable @inline(__always)
    func match(root: JsonElement,
               rootIdx: inout Int,
               matches: JsonElement) -> Bool {
        // TODO: we should be able to optimize a little by skipping queries which
        // need more matches than the root has matches for; commenting out because the
        // following guard is buggy
        guard rootIdx + minimumPartsCount <= root.count else {
            // Compass.print("Skipping query because \(rootIdx + minimumPartsCount) > \(root.count)")
            return false
        }
        var debug = false
        
        var localRootIdx = rootIdx
        var lastCaptureIdx = rootIdx
        var localMatches: [(HalfHitch,HalfHitch)] = []
        for queryIdx in 0..<queryParts.count {
            guard let rootValue = root[localRootIdx]?.halfHitchValue else {
                Compass.print("Unexpected non-string value at root index \(localRootIdx): \(root[element: localRootIdx]?.description ?? "nil")")
                return false
            }
            
            let queryPart = queryParts[queryIdx]
            
            // We are looking to prove that this query part does not match the value in the root array at the rootIdx,
            // and if we do we can immediately return false
            switch queryPart.type {
            
            case .comment:
                break
            
            case .debug:
                debug = true
                if debug {
                    Compass.print("")
                    Compass.print(tag: "DEBUG", "[\(localRootIdx)] -- BEGIN DEBUG QUERY --")
                }
                break
            
            case .string:
                guard let queryValue = queryPart.value else {
                    Compass.print("Malformed query part with missing value encountered: \(self)")
                    return false
                }
                guard queryValue == rootValue else {
                    if debug { Compass.print(tag: "DEBUG", "[\(localRootIdx)] failed string match \(queryValue) != \(rootValue)") }
                    return false
                }
                if debug { Compass.print(tag: "DEBUG", "[\(localRootIdx)] MATCH: \(queryValue) == \(rootValue)") }
                localRootIdx += 1
            
            case .capture:
                guard let capturePartType = queryPart.capturePartType else {
                    Compass.print("Malformed capture with missing capturePartType encountered: \(self)")
                    return false
                }
                guard let captureKey = queryPart.captureKey else {
                    Compass.print("Malformed capture with missing captureKey encountered: \(self)")
                    return false
                }
                if capturePartType == .captureString {
                    if debug { Compass.print(tag: "DEBUG", "[\(localRootIdx)] ANY CAPTURE: [\(captureKey)] \(rootValue)") }
                    localMatches.append(
                        (captureKey.halfhitch(),rootValue)
                    )
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                    continue
                } else if capturePartType == .any {
                    if debug { Compass.print(tag: "DEBUG", "[\(localRootIdx)] SKIPPING CAPTURE: [\(captureKey)] \(rootValue)") }
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                    continue
                } else if capturePartType == .regex {
                    if debug { Compass.print(tag: "DEBUG", "[\(localRootIdx)] REGEX CAPTURE: [\(captureKey)] \(rootValue)") }
                    fatalError("TO BE IMPLEMENTED")
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                    continue
                } else {
                    Compass.print("Malformed capture of part type \(capturePartType) encountered: \(self)")
                    return false
                }
                
            default:
                Compass.print("Support for query part \(queryPart.type) to be implemented")
                return false
            }
        }
        
        // Advance the root index just past the last capture index
        rootIdx = lastCaptureIdx + 1
        if debug {
            Compass.print(tag: "DEBUG", "[\(localRootIdx)] QUERY SUCCESS: advancing to \(rootIdx)")
        }
        
        // Merge in our local matches into our global matches
        for match in localMatches {
            capture(key: match.0.hitch(),
                    value: match.1.hitch(),
                    matches: matches)
        }
        
        return true
    }
}

extension Compass {
    
    func matches(against root: JsonElement,
                 queries: [Query]) -> JsonElement? {
        guard root.type == .array else {
            Compass.print("queries can only be matched against an array")
            return nil
        }
        
        // We iterate over each entry in the root array and attempt to
        // match any query to that part of the array. If we find a match
        // we advance the roodIdx to the end of that match (parts of the
        // root array may not match multiple queries).
        //
        // Eventually we want to return a JsonElement of captures. Each
        // key in the element is a capture key defined in the
        // compass regex and the value is a array of all matches found.
        let matches = JsonElement(unknown: [:])
        
        var rootIdx = 0
        while rootIdx < root.count {
            
            var didMatchQuery = false
            for query in queries {
                if query.match(root: root,
                               rootIdx: &rootIdx,
                               matches: matches) {
                    didMatchQuery = true
                    break
                }
            }
            
            if didMatchQuery == false {
                rootIdx += 1
            }
        }
        
        return matches
    }
    
}