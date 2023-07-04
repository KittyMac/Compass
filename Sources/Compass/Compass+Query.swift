import Foundation
import Hitch
import Spanker

// Definition
// Structure: a string which begins with "--"; these are typically structure elements
//   captured from the HTML and included as guides.
// Examples:
//  link: -- http:\/\/www.example.com --
//  table: -- table --
//  image: -- img --
//         -- http:\/\/www.example.com/image.png --
//         -- endimg --
//
// Matching Ruleset:
// String matches in general are straight compares (case senstive and must match all)
// ~ at the beginning means to match the rest of the string anywhere in the content
// ^ at the beginning means to match the rest of the string at the beginning of the content
// Examples:
//   "^Price" will match "Price" and "Prices are low!" but not "Low Prices"
//   "~Price" will match "Price" and "Prices are low!" and "Low Prices"
//
// Regex can also be used to match against the content.
// Example:
//   /price/i will match "Price" and "price" but not "Prices are low!" or "Low Prices"
//
// Custom Commands:
// "//" means a developer comment (doesn't match anything)
// "DEBUG" means to print debugging information for this specific query
//
// "!--" means to match anything that is not a structure
// "*--" means to skip forward until we find a non-structure
// "*" means to advance until the next part matches, we reach end of document, or we encounter structure
// "!*" means to advance until the next part matches or we reach end of document
// "?" means to advance at most once or until the next part matches
// "." means to advance once (matches anything)
// "REPEAT" means to repeat this query until we match the next part
// "REPEAT_UNTIL_STRUCTURE" means to repeat this query until we match the next part or a structure
//
// To capture a value, you must provide a capture block. This is an array where
// Index 0 is the capture key
// Index 1 is the capture command
// Index 2 is the validation command


@usableFromInline let partComment: HalfHitch = "//";
@usableFromInline let partCaptureString: HalfHitch = "()";
@usableFromInline let partNotStructure: HalfHitch = "!--";
@usableFromInline let partSkipStructure: HalfHitch = "*--";
@usableFromInline let partRepeat: HalfHitch = "REPEAT";
@usableFromInline let partRepeatUntilStructure: HalfHitch = "REPEAT_UNTIL_STRUCTURE";
@usableFromInline let partSkip: HalfHitch = "*";
@usableFromInline let partSkipOne: HalfHitch = "?";
@usableFromInline let partSkipAll: HalfHitch = "!*";
@usableFromInline let partAny: HalfHitch = ".";
@usableFromInline let partDebug: HalfHitch = "DEBUG";

public enum PartType: Int {
    case capture = 0
    case string = 1
    case regex = 2

    case comment = 3
    case notStructure = 4
    case skipStructure = 5
    case `repeat` = 10
    case repeatUntilStructure = 11
    case captureString = 12
    case skip = 13
    case skipOne = 14
    case skipAll = 15
    case any = 16
    case debug = 17
}

public struct QueryPart {
    // Simple query parts have a type and an optional value
    public let type: PartType
    public let value: Hitch?
    public let regex: NSRegularExpression?
    
    // Capture query parts have a key (the place to store the captured values),
    // a capture type (how to determine the value to capture) and
    // a validation key (a lookup to a ruleset which determines if this is
    // a valid value)
    public let captureKey: Hitch?
    public let capturePartType: PartType?
    public let capturePartRegex: NSRegularExpression?
    public let captureValidationKey: Hitch?
        
    init?(element: JsonElement) {
        // var queryPart = QueryPart(type: PartType, value: Hitch)
        // capture group
        if element.type == .array {
            guard element.count == 3 else {
                Compass.print("Malformed query capture detected: \(element)")
                return nil
            }

            guard let captureKey: Hitch = element[0] else {
                Compass.print("Malformed query capture detected (capture key is not a string): \(element)")
                return nil
            }
            guard let validationKey: Hitch = element[2] else {
                Compass.print("Malformed query capture detected (validation key is not a string): \(element)")
                return nil
            }
            guard let capturePartElement: JsonElement = element[1] else {
                Compass.print("Malformed query capture detected (failure to extract capture part): \(element)")
                return nil
            }
            guard let capturePart = QueryPart(element: capturePartElement) else {
                Compass.print("Malformed query capture detected (failure to part query part): \(element)")
                return nil
            }
            guard capturePart.type == .regex ||
                    capturePart.type == .captureString ||
                    capturePart.type == .string else {
                Compass.print("Malformed query capture detected (capture part is not regex, \"()\" or \".\"): \(element)")
                return nil
            }
            
            self.type = .capture
            self.value = capturePart.value
            self.regex = capturePart.regex
            self.captureKey = captureKey
            self.capturePartType = capturePart.type
            self.capturePartRegex = capturePart.regex
            self.captureValidationKey = validationKey
            return
        }
        
        // other token
        var queryPartType: PartType?
        var queryPartValue: Hitch?
        var queryPartRegex: NSRegularExpression?
        if element.type == .string,
           let value = element.halfHitchValue {
            
            if value.first == .forwardSlash && value.last == .forwardSlash {
                queryPartType = .regex
                queryPartRegex = getCachedRegex(value.hitch())
                if queryPartRegex == nil {
                    return nil
                }
            } else if value.starts(with: partComment) {
                queryPartType = .comment
                queryPartValue = value.substring(2, value.count)
            } else if value == partCaptureString {
                queryPartType = .captureString
            } else if value == partNotStructure {
                queryPartType = .notStructure
            } else if value == partSkipStructure {
                queryPartType = .skipStructure
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
            } else if value == partAny {
                queryPartType = .any
            } else if value == partDebug {
                queryPartType = .debug
            } else {
                queryPartType = .string
                queryPartValue = value.hitch()
            }
        }
        
        guard let queryPartType = queryPartType else {
            Compass.print("Malformed query detected (unknown part type): \(element)")
            return nil
        }
        
        self.type = queryPartType
        self.value = queryPartValue
        self.regex = queryPartRegex
        self.captureKey = nil
        self.capturePartType = nil
        self.capturePartRegex = nil
        self.captureValidationKey = nil
    }
    
    
}

/// A query is a series of query parts, each part intending to match
/// against an entry in the source JSON array. How they match are
/// dependent on the type of the part
public struct Query {
    public let queryParts: [QueryPart]
    public let minimumPartsCount: Int
        
    init?(element: JsonElement) {
        guard element.type == .array else {
            Compass.print("Unexpected query item detected: \(element)")
            return nil
        }
        
        var queryParts: [QueryPart] = []
        
        for elementPart in element.iterValues {
            guard let queryPart = QueryPart(element: elementPart) else {
                return nil
            }
            queryParts.append(queryPart)
        }
        
        // Count up the minimum number of matching parts required
        // This is sued to skip queries which cannot possibly match
        var count = 0
        for queryPart in queryParts {
            switch queryPart.type {
            case .debug, .comment:
                break
            default:
                count += 1
                break
            }
        }
        
        self.minimumPartsCount = count
        self.queryParts = queryParts
    }
}
