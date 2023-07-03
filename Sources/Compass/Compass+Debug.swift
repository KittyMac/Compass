import Foundation
import Hitch
import Spanker

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
        case .regex:
            break
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
        case .captureSkip:
            hitch.append(.doubleQuote)
            hitch.append(partCaptureSkip)
            hitch.append(.doubleQuote)
            break
        case .capture2:
            hitch.append(.doubleQuote)
            hitch.append(partCapture2)
            hitch.append(.doubleQuote)
            break
        case .capture3:
            hitch.append(.doubleQuote)
            hitch.append(partCapture3)
            hitch.append(.doubleQuote)
            break
        case .capture4:
            hitch.append(.doubleQuote)
            hitch.append(partCapture4)
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
        case .capture:
            hitch.append(.doubleQuote)
            hitch.append(partCapture)
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

extension Query {
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
