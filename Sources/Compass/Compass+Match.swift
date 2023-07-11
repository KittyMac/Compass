import Foundation
import Hitch
import Spanker

extension Query {
    
    @inlinable
    func capture(key: Hitch,
                 value: Hitch,
                 matches: JsonElement) {
        guard let existing: JsonElement = matches[key] else {
            matches.set(key: key.halfhitch(), value: ^[value])
            return
        }
        existing.append(value: value)
    }
        
    @discardableResult
    @inlinable
    func match(compass: Compass,
               root: JsonElement,
               rootIdx: inout Int,
               debug: inout Bool,
               indent: Int,
               matches: JsonElement,
               rootCache: RootCache) -> Bool {
        guard rootIdx + minimumPartsCount <= root.count else {
            // Compass.print("Skipping query because \(rootIdx + minimumPartsCount) > \(root.count)")
            return false
        }
        
        var localRootIdx = rootIdx
        var lastCaptureIdx = rootIdx
        let localMatch = ^[:]
        
        for queryIdx in 0..<queryParts.count {
            let queryPart = queryParts[queryIdx]
            
            var nextQueryPart: QueryPart? = nil
            
            // Next part is used to know when to end. It doesn't make sense if nextPart is
            // a skipping operation, so advance once more maybe we get something real to match
            for nextQueryPartIdx in queryIdx+1..<queryIdx+3 {
                guard nextQueryPartIdx < queryParts.count else { break }
                let checkNextQueryPart = queryParts[nextQueryPartIdx]
                guard checkNextQueryPart.type != .skip &&
                        checkNextQueryPart.type != .skipAll &&
                        checkNextQueryPart.type != .skipOne &&
                        checkNextQueryPart.type != .skipStructure else {
                    continue
                }
                nextQueryPart = checkNextQueryPart
                break
            }
            
            if match(compass: compass,
                     queryPart: queryPart,
                     nextQueryPart: nextQueryPart,
                     root: root,
                     localRootIdx: &localRootIdx,
                     lastCaptureIdx: &lastCaptureIdx,
                     debug: &debug,
                     indent: indent,
                     localMatch: localMatch,
                     rootCache: rootCache) == false {
                return false
            }
        }
        
        // Advance the root index just past the last capture index
        rootIdx = lastCaptureIdx
        if debug {
            Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] QUERY SUCCESS: last capture at \(lastCaptureIdx)")
        }
        
        // Merge in our local matches into our global matches
        matches.append(value: localMatch)

        return true
    }
    
    @discardableResult
    @inlinable
    func match(compass: Compass,
               queryPart: QueryPart,
               nextQueryPart: QueryPart?,
               root: JsonElement,
               localRootIdx: inout Int,
               lastCaptureIdx: inout Int,
               debug: inout Bool,
               indent: Int,
               localMatch: JsonElement,
               rootCache: RootCache) -> Bool {
        guard localRootIdx < root.count else { return false }
        
        guard var rootValue = root[localRootIdx]?.halfHitchValue else {
            Compass.print("Unexpected non-string value at root index \(localRootIdx): \(root[element: localRootIdx]?.description ?? "nil")")
            return false
        }
                
        // We are looking to prove that this query part does not match the value in the root array at the rootIdx,
        // and if we do we can immediately return false
        switch queryPart.type {
        
        case .comment:
            break
        
        case .debug:
            debug = true
            if debug {
                Compass.print("")
                Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] -- BEGIN DEBUG QUERY --")
            }
            break
            
        case .skipStructure:
            while rootValue.starts(with: "-- ") {
                localRootIdx += 1
                guard let nextRootValue = root[localRootIdx]?.halfHitchValue else {
                    Compass.print("Unexpected non-string value at root index \(localRootIdx): \(root[element: localRootIdx]?.description ?? "nil")")
                    return false
                }
                rootValue = nextRootValue
            }
            break
            
        case .notStructure:
            guard rootValue.starts(with: "-- ") == false else {
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] failed to match non structure: \(rootValue)") }
                return false
            }
            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] MATCH NOT STRUCTURE: \(rootValue)") }
            localRootIdx += 1
            break
        
        case .subquery, .repeat, .repeatUntilStructure:
            let subqueryMatches = ^[]
            let endOnStructure = queryPart.type == .repeatUntilStructure
            let shouldRepeat = queryPart.type != .subquery
            
            while localRootIdx < root.count {
                
                if shouldRepeat {
                    // end on structure?
                    if endOnStructure,
                       let rootValue = root[localRootIdx]?.halfHitchValue,
                       rootValue.starts(with: "-- ") {
                        break
                    }
                    
                    // are we the next part?
                    var nextPartNoDebug = false
                    var nextPartIdx = localRootIdx
                    var nextPartCaptureIdx = localRootIdx
                    let nextPartMatches = ^[]
                    if let nextQueryPart = nextQueryPart,
                       match(compass: compass,
                             queryPart: nextQueryPart,
                             nextQueryPart: nil,
                             root: root,
                             localRootIdx: &nextPartIdx,
                             lastCaptureIdx: &nextPartCaptureIdx,
                             debug: &nextPartNoDebug,
                             indent: indent + 1,
                             localMatch: nextPartMatches,
                             rootCache: rootCache) {
                        break
                    }
                }
                
                // match the subquery?
                if let subquery = queryPart.subquery,
                   subquery.match(compass: compass,
                                  root: root,
                                  rootIdx: &localRootIdx,
                                  debug: &debug,
                                  indent: indent + 1,
                                  matches: subqueryMatches,
                                  rootCache: rootCache) {
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                    if shouldRepeat {
                        continue
                    }
                    break
                }
                
                // otherwise we end
                return false
            }
            
            localRootIdx = lastCaptureIdx + 1
            
            for subqueryMatch in subqueryMatches.iterValues {
                for key in subqueryMatch.iterKeys {
                    guard let valueArray: JsonElement = subqueryMatch[key] else { continue }
                    for value in valueArray.iterValues {
                        guard let valueHitch = value.hitchValue else { continue }
                        capture(key: key.hitch(),
                                value: valueHitch,
                                matches: localMatch)
                    }
                }
            }
            
            break
            
        case .regex:
            guard let queryRegex = queryPart.regex else {
                Compass.print("Malformed query part with missing regex encountered: \(self)")
                return false
            }
            guard rootCache.test(regex: queryRegex,
                                 index: localRootIdx,
                                 value: rootValue) else {
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] failed regex match \(queryRegex) against \(rootValue)") }
                return false
            }
            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] REGEX MATCH: \(queryRegex) against \(rootValue)") }
            localRootIdx += 1
        
        case .string:
            guard let queryValue = queryPart.value else {
                Compass.print("Malformed query part with missing value encountered: \(self)")
                return false
            }
            guard queryValue == rootValue else {
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] failed string match \(queryValue) != \(rootValue)") }
                return false
            }
            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] STRING MATCH: \(queryValue) == \(rootValue)") }
            localRootIdx += 1
            
        case .stringStartsWith:
            guard let queryValue = queryPart.value else {
                Compass.print("Malformed query part with missing value encountered: \(self)")
                return false
            }
            guard rootValue.starts(with: queryValue) else {
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] failed string match \(queryValue) != \(rootValue)") }
                return false
            }
            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] STRING STARTS WITH: \(queryValue) == \(rootValue)") }
            localRootIdx += 1
            
        case .stringContains:
            guard let queryValue = queryPart.value else {
                Compass.print("Malformed query part with missing value encountered: \(self)")
                return false
            }
            guard rootValue.contains(queryValue) else {
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] failed string match \(queryValue) != \(rootValue)") }
                return false
            }
            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] STRING CONTAINS: \(queryValue) == \(rootValue)") }
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
            guard let captureValidationKey = queryPart.captureValidationKey,
                  let validation = compass.validations[captureValidationKey] else {
                Compass.print("Malformed capture with missing validation: \(self)")
                return false
            }
            
            if capturePartType == .captureString ||
                capturePartType == .any {
                let label = capturePartType == .captureString ? "ANY CAPTURE" : "SKIP CAPTURE"
                // We capture the whole string, whatever it is, from the root element
                if let result = validation.test(rootValue) {
                    if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] \(label): [\(captureKey)] \(result)") }
                    capture(key: captureKey,
                            value: result,
                            matches: localMatch)
                } else {
                    if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] FAILED VALIDATION \(validation.name): [\(captureKey)] \(rootValue)") }
                    return false
                }
                if capturePartType == .captureString {
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                }
                return true
            } else if capturePartType == .regex,
                      let regex = queryPart.regex {
                
                let matches = rootCache.matches(regex: regex,
                                                index: localRootIdx,
                                                value: rootValue)
                if matches.count > 0 {
                    for match in matches {
                        // We capture the whole string, whatever it is, from the capture query
                        if let result = validation.test(match) {
                            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] REGEX CAPTURE: [\(captureKey)] \(match)") }
                            capture(key: captureKey,
                                    value: result,
                                    matches: localMatch)
                        } else {
                            if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] FAILED VALIDATION \(validation.name): [\(captureKey)] \(match)") }
                            return false
                        }
                    }
                                        
                    lastCaptureIdx = localRootIdx
                    localRootIdx += 1
                    return true
                }
                
                if debug { Compass.print(indent: indent, tag: "DEBUG", "[\(localRootIdx)] FAILED REGEX \(regex): [\(captureKey)] \(rootValue)") }
                return false
            } else {
                Compass.print("Malformed capture of part type \(capturePartType) encountered: \(self)")
                return false
            }
            
        default:
            Compass.print("Support for query part \(queryPart.type) to be implemented")
            return false
            /*
        case .regex:
        case .skip:
        case .skipOne:
        case .skipAll:
        case .any:
            */
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
        let matches = ^[]
        
        let rootCache = RootCache()
        var localQueries = queries

        var rootIdx = 0
        while rootIdx < root.count && localQueries.count > 0 {
            for query in queries {
                var debug = false
                if query.match(compass: self,
                               root: root,
                               rootIdx: &rootIdx,
                               debug: &debug,
                               indent: 0,
                               matches: matches,
                               rootCache: rootCache) {
                    
                    // localQueries = localQueries.filter { query in
                    //     query.isFinished(matches: matches) == false
                    // }
                    
                    break
                }
            }
            rootIdx += 1
        }
        
        return matches
    }
    
}
