import Foundation
import Hitch
import Spanker

/// A validation is a reusable validation scheme whose purpose is to
/// determine that a captured value meets a certain criteria.
/// At the time of this writing, this is done by using a series
/// of allow/disallow regex. For a value to pass validation, it must
/// succeed against AT LEAST ONE of the allow regex and must not
/// succeed against ANY of the disallow regex.
///
/// {
///     "validation": "isCat",
///     "allow": [
///         "/CAT\\d+/"
///     ],
///     "disallow": []
/// }

public struct Validation {
    public let name: Hitch
    public var allows: [NSRegularExpression]
    public var disallows: [NSRegularExpression]
    
    init?(element: JsonElement) {
       
        
        self.allows = []
        self.disallows = []
        
        guard let name: Hitch = element["validation"] else {
            Compass.print("Malformed validation is missing \"validation\" key: \(element)")
            return nil
        }
        self.name = name
        
        guard let allow: JsonElement = element["allow"] else {
            Compass.print("Malformed validation is missing \"allow\" key: \(element)")
            return nil
        }
        guard let disallow: JsonElement = element["disallow"] else {
            Compass.print("Malformed validation is missing \"disallow\" key: \(element)")
            return nil
        }
        
        guard allow.type == .array else {
            Compass.print("Malformed allow array is not an array: \(element)")
            return nil
        }
        for pattern in allow.iterValues {
            guard let pattern = pattern.hitchValue else {
                Compass.print("Malformed allow array pattern is not a string: \(element)")
                return nil
            }
            guard let regex = getCachedRegex(pattern) else {
                Compass.print("Malformed allow regex: \(element)")
                return nil
            }
            self.allows.append(regex)
        }
        
        guard disallow.type == .array else {
            Compass.print("Malformed disallow array is not an array: \(element)")
            return nil
        }
        for pattern in disallow.iterValues {
            guard let pattern = pattern.hitchValue else {
                Compass.print("Malformed disallow array pattern is not a string: \(element)")
                return nil
            }
            guard let regex = getCachedRegex(pattern) else {
                Compass.print("Malformed disallow regex: \(element)")
                return nil
            }
            self.disallows.append(regex)
        }
    }
    
    @usableFromInline
    func test(_ value: HalfHitch) -> Bool {
        guard name != "." else {
            return true
        }
        
        let valueAsString = value.description
        let valueRange = NSRange(location: 0, length: value.count)
        
        for disallow in disallows {
            if disallow.firstMatch(in: valueAsString, range: valueRange) != nil {
                return false
            }
        }
        for allow in allows {
            if allow.firstMatch(in: valueAsString, range: valueRange) != nil {
                return true
            }
        }
        return false
    }
}
