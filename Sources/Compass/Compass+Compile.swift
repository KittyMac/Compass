import Foundation
import Hitch
import Spanker

let partComment: HalfHitch = "//";
let partNotStructure: HalfHitch = "!--";
let partSkipStructure: HalfHitch = "*--";
let partCaptureSkip: HalfHitch = "(*)";
let partCapture2: HalfHitch = "(2)";
let partCapture3: HalfHitch = "(3)";
let partCapture4: HalfHitch = "(4)";
let partRepeat: HalfHitch = "REPEAT";
let partRepeatUntilStructure: HalfHitch = "REPEAT_UNTIL_STRUCTURE";
let partSkip: HalfHitch = "*";
let partSkipOne: HalfHitch = "?";
let partSkipAll: HalfHitch = "!*";
let partCapture: HalfHitch = "()";
let partAny: HalfHitch = ".";
let partDebug: HalfHitch = "DEBUG";

enum PartType: Int {
    case string = 0
    case regex = 1

    case comment = 2
    case notStructure = 4
    case skipStructure = 5
    case captureSkip = 6
    case capture2 = 7
    case capture3 = 8
    case capture4 = 9
    case `repeat` = 10
    case repeatUntilStructure = 11
    case skip = 12
    case skipOne = 13
    case skipAll = 14
    case capture = 15
    case any = 16
    case debug = 17
}

struct QueryPart {
    let type: PartType
    let value: Hitch
    
    init(type: PartType,
         value: Hitch) {
        self.type = type
        self.value = value
    }
}

/// A query is a series of query parts, each part intending to match
/// against an entry in the source JSON array. How they match are
/// dependent on the type of the part
struct Query {
    let parts: [QueryPart]
}

extension Compass {
    
    func compile(query element: JsonElement) -> Query? {
        guard element.type == .array else { return nil }
        
        var parts: [QueryPart] = []
        
        for elementPart in element.iterValues {
            var queryPartType: PartType?
            
            // var queryPart = QueryPart(type: PartType, value: Hitch)
            // capture group
            if elementPart.type == .array {
                
            }
            
            // other token
            if elementPart.type == .string,
               let value = elementPart.halfHitchValue {
                
                if value.starts(with: partComment) {
                    queryPartType = .comment
                } else if value.starts(with: partNotStructure) {
                    queryPartType = .notStructure
                } else if value.starts(with: partSkipStructure) {
                    queryPartType = .skipStructure
                } else if value.starts(with: partCaptureSkip) {
                    queryPartType = .captureSkip
                } else if value.starts(with: partCapture2) {
                    queryPartType = .capture2
                } else if value.starts(with: partCapture3) {
                    queryPartType = .capture3
                } else if value.starts(with: partCapture4) {
                    queryPartType = .capture4
                } else if value.starts(with: partRepeat) {
                    queryPartType = .repeat
                } else if value.starts(with: partRepeatUntilStructure) {
                    queryPartType = .repeatUntilStructure
                } else if value.starts(with: partSkip) {
                    queryPartType = .skip
                } else if value.starts(with: partSkipOne) {
                    queryPartType = .skipOne
                } else if value.starts(with: partSkipAll) {
                    queryPartType = .skipAll
                } else if value.starts(with: partCapture) {
                    queryPartType = .capture
                } else if value.starts(with: partAny) {
                    queryPartType = .any
                } else if value.starts(with: partDebug) {
                    queryPartType = .debug
                }
            }

        }
        
        return Query(parts: parts)
    }
        
}
