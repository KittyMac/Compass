import Foundation
import Hitch
import Spanker

extension QueryPart: CustomStringConvertible {
    public var description: String {
        let hitch = Hitch()
        exportTo(hitch: hitch)
        return hitch.toString()
    }
}

extension QueryPart {
    @discardableResult
    @inlinable @inline(__always)
    public func exportTo(hitch: Hitch) -> Hitch {
        switch type {
        case .string:
            hitch.append(.doubleQuote)
            if let value = value {
                hitch.append(value)
            }
            hitch.append(.doubleQuote)
            break
        case .stringStartsWith:
            hitch.append(.doubleQuote)
            hitch.append(.carrat)
            if let value = value {
                hitch.append(value)
            }
            hitch.append(.doubleQuote)
            break
        case .stringContains:
            hitch.append(.doubleQuote)
            hitch.append(.tilde)
            if let value = value {
                hitch.append(value)
            }
            hitch.append(.doubleQuote)
            break
        case .regex:
            hitch.append(.doubleQuote)
            hitch.append(.forwardSlash)
            if let regex = regex {
                hitch.append(regex.pattern)
            }
            hitch.append(.forwardSlash)
            hitch.append(.doubleQuote)
            break
        case .capture:
            hitch.append(.openBrace)
            hitch.append(.doubleQuote)
            hitch.append(captureKey ?? "MISSING_CAPTURE_KEY")
            hitch.append(.doubleQuote)
            hitch.append(.comma)
            if capturePartType == .captureString {
                hitch.append(.doubleQuote)
                hitch.append(partCaptureString)
                hitch.append(.doubleQuote)
            } else if capturePartType == .any {
                hitch.append(.doubleQuote)
                hitch.append(partAny)
                hitch.append(.doubleQuote)
            } else if capturePartType == .regex,
                      let regex = capturePartRegex {
                hitch.append(.doubleQuote)
                hitch.append(.forwardSlash)
                hitch.append(regex.pattern)
                hitch.append(.forwardSlash)
                hitch.append(.doubleQuote)
            } else {
                hitch.append("MISSING_CAPTURE_PART")
            }
            hitch.append(.comma)
            hitch.append(.doubleQuote)
            hitch.append(captureValidationKey ?? "MISSING_VALIDATION_KEY")
            hitch.append(.doubleQuote)
            hitch.append(.closeBrace)
        case .captureString:
            hitch.append(.doubleQuote)
            hitch.append(partCaptureString)
            hitch.append(.doubleQuote)
        case .comment:
            hitch.append(.doubleQuote)
            hitch.append(partComment)
            if let value = value {
                hitch.append(value)
            }
            hitch.append(.doubleQuote)
            break
        case .notStructure:
            hitch.append(.doubleQuote)
            hitch.append(partNotStructure)
            hitch.append(.doubleQuote)
            break
        case .skipStructure:
            hitch.append(.doubleQuote)
            hitch.append(partSkipStructure)
            hitch.append(.doubleQuote)
            break
        case .repeat:
            hitch.append(.doubleQuote)
            hitch.append(partRepeat)
            hitch.append(.doubleQuote)
            break
        case .repeatUntilStructure:
            hitch.append(.doubleQuote)
            hitch.append(partRepeatUntilStructure)
            hitch.append(.doubleQuote)
            break
        case .skip:
            hitch.append(.doubleQuote)
            hitch.append(partSkip)
            hitch.append(.doubleQuote)
            break
        case .skipOne:
            hitch.append(.doubleQuote)
            hitch.append(partSkipOne)
            hitch.append(.doubleQuote)
            break
        case .skipAll:
            hitch.append(.doubleQuote)
            hitch.append(partSkipAll)
            hitch.append(.doubleQuote)
            break
        case .any:
            hitch.append(.doubleQuote)
            hitch.append(partAny)
            hitch.append(.doubleQuote)
            break
        case .debug:
            hitch.append(.doubleQuote)
            hitch.append(partDebug)
            hitch.append(.doubleQuote)
            break
        }
        
        hitch.append(.comma)
        
        return hitch
    }
}

extension Query: CustomStringConvertible {
    public var description: String {
        let hitch = Hitch(capacity: 1024)
        exportTo(hitch: hitch)
        return hitch.toString()
    }
    
    @discardableResult
    @inlinable @inline(__always)
    public func exportTo(hitch: Hitch) -> Hitch {
        hitch.append(.openBrace)
        for queryPart in queryParts {
            queryPart.exportTo(hitch: hitch)
        }
        if hitch.last == .comma {
            hitch.count -= 1
        }
        hitch.append(.closeBrace)
        
        return hitch
    }
}

extension Compass: CustomStringConvertible {
    
    public var description: String {
        let hitch = Hitch(capacity: 1024)
        exportTo(hitch: hitch)
        return hitch.toString()
    }
    
    @discardableResult
    @inlinable @inline(__always)
    public func exportTo(hitch: Hitch) -> Hitch {
        hitch.append(.openBrace)
        for query in queries {
            query.exportTo(hitch: hitch)
        }
        if hitch.last == .comma {
            hitch.count -= 1
        }
        hitch.append(.closeBrace)
        
        return hitch
    }
}
