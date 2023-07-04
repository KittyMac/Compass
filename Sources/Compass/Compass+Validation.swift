import Foundation
import Hitch
import Spanker

/// A validation is a reusable validation scheme whose purpose is to
/// determine that a captured value meets a certain criteria.
/// At the time of this writing, this is done by using a series
/// of allow/disallow regex. For a value to pass validation, it must
/// succeed against AT LEAST ONE of the allow regex and must not
///  (an empty allow array will always succeed)
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
    public var allows: [CompassRegex]
    public var disallows: [CompassRegex]
    public weak var compass: Compass?
    
    init?(element: JsonElement,
          compass: Compass) {
       
        self.compass = compass
        self.allows = []
        self.disallows = []
        
        guard let name: Hitch = element["validation"] else {
            //Compass.print("Malformed validation is missing \"validation\" key: \(element)")
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
            guard let pattern = compass.replaceWithDefinition(pattern),
                  let pattern = pattern.hitchValue else {
                Compass.print("Malformed allow array pattern is not a string: \(element)")
                return nil
            }
            guard let regex = getCachedRegex(pattern) else {
                Compass.print("Malformed allow regex: \(pattern)")
                return nil
            }
            self.allows.append(regex)
        }
        
        guard disallow.type == .array else {
            Compass.print("Malformed disallow array is not an array: \(element)")
            return nil
        }
        for pattern in disallow.iterValues {
            guard let pattern = compass.replaceWithDefinition(pattern),
                  let pattern = pattern.hitchValue else {
                Compass.print("Malformed disallow array pattern is not a string: \(element)")
                return nil
            }
            guard let regex = getCachedRegex(pattern) else {
                Compass.print("Malformed disallow regex: \(pattern)")
                return nil
            }
            self.disallows.append(regex)
        }
    }
    
    @usableFromInline
    func test(_ value: HalfHitch) -> Hitch? {
        guard name != "." else {
            return value.hitch()
        }
        
        if let compass = compass,
           let customValidation = compass.customValidations[name] {
            return customValidation(value, self)
        }
        
        for disallow in disallows {
            if disallow.test(against: value) {
                return nil
            }
        }
        if allows.isEmpty {
            return value.hitch()
        }
        for allow in allows {
            if allow.test(against: value) {
                return value.hitch()
            }
        }
        return nil
    }
}
