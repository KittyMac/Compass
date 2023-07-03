import Foundation
import Hitch
import Spanker

@usableFromInline let partComment: HalfHitch = "//";
@usableFromInline let partNotStructure: HalfHitch = "!--";
@usableFromInline let partSkipStructure: HalfHitch = "*--";
@usableFromInline let partCaptureSkip: HalfHitch = "(*)";
@usableFromInline let partCapture2: HalfHitch = "(2)";
@usableFromInline let partCapture3: HalfHitch = "(3)";
@usableFromInline let partCapture4: HalfHitch = "(4)";
@usableFromInline let partRepeat: HalfHitch = "REPEAT";
@usableFromInline let partRepeatUntilStructure: HalfHitch = "REPEAT_UNTIL_STRUCTURE";
@usableFromInline let partSkip: HalfHitch = "*";
@usableFromInline let partSkipOne: HalfHitch = "?";
@usableFromInline let partSkipAll: HalfHitch = "!*";
@usableFromInline let partCapture: HalfHitch = "()";
@usableFromInline let partAny: HalfHitch = ".";
@usableFromInline let partDebug: HalfHitch = "DEBUG";

public enum PartType: Int {
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

public struct QueryPart {
    public let type: PartType
    public let value: Hitch?
    
    init(type: PartType,
         value: Hitch?) {
        self.type = type
        self.value = value
    }
}

/// A query is a series of query parts, each part intending to match
/// against an entry in the source JSON array. How they match are
/// dependent on the type of the part
public struct Query {
    public let queryParts: [QueryPart]
}

extension Compass {
    
    func compile(query element: JsonElement) -> Query? {
        guard element.type == .array else {
            print("Unexpected query item detected:")
            print(element.description)
            return nil
        }
        
        var queryParts: [QueryPart] = []
        
        for elementPart in element.iterValues {
            var queryPartType: PartType?
            var queryPartValue: Hitch?
            
            // var queryPart = QueryPart(type: PartType, value: Hitch)
            // capture group
            if elementPart.type == .array {
                
            }
            
            // other token
            if elementPart.type == .string,
               let value = elementPart.halfHitchValue {
                
                if value.starts(with: partComment) {
                    queryPartType = .comment
                    queryPartValue = value.substring(2, value.count)
                } else if value == partNotStructure {
                    queryPartType = .notStructure
                } else if value == partSkipStructure {
                    queryPartType = .skipStructure
                } else if value == partCaptureSkip {
                    queryPartType = .captureSkip
                } else if value == partCapture2 {
                    queryPartType = .capture2
                } else if value == partCapture3 {
                    queryPartType = .capture3
                } else if value == partCapture4 {
                    queryPartType = .capture4
                } else if value == partRepeat {
                    queryPartType = .repeat
                } else if value == partRepeatUntilStructure {
                    queryPartType = .repeatUntilStructure
                } else if value == partSkip {
                    queryPartType = .skip
                } else if value == partSkipOne {
                    queryPartType = .skipOne
                } else if value == partSkipAll {
                    queryPartType = .skipAll
                } else if value == partCapture {
                    queryPartType = .capture
                } else if value == partAny {
                    queryPartType = .any
                } else if value == partDebug {
                    queryPartType = .debug
                } else {
                    queryPartType = .string
                    queryPartValue = value.hitch()
                }
            }
            
            if let queryPartType = queryPartType {
                queryParts.append(
                    QueryPart(type: queryPartType,
                              value: queryPartValue)
                )
            }
        }
        
        return Query(queryParts: queryParts)
    }
        
}
