import Foundation
import Hitch
import Spanker

/// A validation is a reusable validation scheme whose purpose is to
/// determine that a captured value meets a certain criteria.
/// At the time of this writing, this is done by using a series
/// of allow/disallow regex. For a value to pass validation, it must
/// succeed against AT LEAST ONE of the allowAny regex, it must
/// succeed against ALL of the allowAll, and must not
/// succeed against ANY of the disallow regex. Leaving any of these
/// empty will be ignored.
///
/// {
///     "validation": "isCat",
///     "allowAll": [
///         "/CAT\\d+/"
///     ],
///     "allowAny": [
///         "/CAT\\d+/"
///     ],
///     "disallow": []
///     "remove": []
/// }

public struct Validation {
    public let name: Hitch
    public var allowsAll: [CompassRegex]
    public var allowsAny: [CompassRegex]
    public var disallows: [CompassRegex]
    public var removes: [CompassRegex]
    public weak var compass: Compass?
    
    init?(element: JsonElement,
          compass: Compass) {
       
        self.compass = compass
        self.allowsAll = []
        self.allowsAny = []
        self.disallows = []
        self.removes = []
        
        guard let name: Hitch = element["validation"] else {
            //Compass.print("Malformed validation is missing \"validation\" key: \(element)")
            return nil
        }
        self.name = name
        
        if let allowAny: JsonElement = element["allowAny"],
           allowAny.type == .array {
            for pattern in allowAny.iterValues {
                guard let pattern = compass.replaceWithDefinition(pattern),
                      let pattern = pattern.hitchValue else {
                    Compass.print("Malformed allow array pattern is not a string: \(element)")
                    return nil
                }
                guard let regex = getCachedRegex(pattern) else {
                    Compass.print("Malformed allow regex: \(pattern)")
                    return nil
                }
                self.allowsAny.append(regex)
            }
        }
        
        if let allowAll: JsonElement = element["allowAll"],
           allowAll.type == .array {
            for pattern in allowAll.iterValues {
                guard let pattern = compass.replaceWithDefinition(pattern),
                      let pattern = pattern.hitchValue else {
                    Compass.print("Malformed allow array pattern is not a string: \(element)")
                    return nil
                }
                guard let regex = getCachedRegex(pattern) else {
                    Compass.print("Malformed allow regex: \(pattern)")
                    return nil
                }
                self.allowsAll.append(regex)
            }
        }
        
        if let disallow: JsonElement = element["disallow"],
           disallow.type == .array {
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
        
        // Optional
        if let remove: JsonElement = element["remove"],
           remove.type == .array {
            for pattern in remove.iterValues {
                guard let pattern = compass.replaceWithDefinition(pattern),
                      let pattern = pattern.hitchValue else {
                    Compass.print("Malformed remove array pattern is not a string: \(element)")
                    return nil
                }
                guard let regex = getCachedRegex(pattern) else {
                    Compass.print("Malformed remove regex: \(pattern)")
                    return nil
                }
                self.removes.append(regex)
            }
        }
    }
    
    @usableFromInline
    func remove(_ value: Hitch) -> Hitch {
        for regex in removes {
            regex.remove(from: value)
        }
        return value
    }
    
    @usableFromInline
    func test(_ value: HalfHitch) -> Hitch? {
        guard name != "." else {
            return remove(value.hitch())
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
        
        if allowsAll.isEmpty == false {
            for allow in allowsAll {
                if allow.test(against: value) == false {
                    return nil
                }
            }
        }
        
        if allowsAny.isEmpty {
            return remove(value.hitch())
        }
        
        for allow in allowsAny {
            if allow.test(against: value) {
                return remove(value.hitch())
            }
        }
        
        return nil
    }
}
