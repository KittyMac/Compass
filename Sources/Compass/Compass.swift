import Foundation
import Hitch
import Spanker

// Compass is like regex for json structures. You create a a Compass supplying it
// a "json regex", which Compass compiles into a more optimized format. You can then
// run this compass against different json and it will return the matches found.

public typealias CompassValidation = (HalfHitch, Validation) -> Hitch?

public final class Compass {
    
    public var queries: [Query] = []
    public var validations: [Hitch: Validation] = [:]
    public var definitions: [Hitch: Definition] = [:]
    
    public var customValidations: [Hitch: CompassValidation] = [:]
    
    public init?(queries root: JsonElement) {
        // Note: the memory used by element will be deallocated after this call, so it it
        // important to not rely on the contents of element for persistance
        //
        // Note: element is expected to be an array of queries
        //
        
        guard root.type == .array else { return nil }
        
        for queryElement in root.iterValues {
            if queryElement.type == .string && queryElement.halfHitchValue?.starts(with: "//") == true {
                continue
            }
            if queryElement.type == .dictionary {
                if let validation = Validation(element: queryElement,
                                               compass: self) {
                    validations[validation.name] = validation
                    continue
                }
                if let definition = Definition(element: queryElement,
                                               compass: self) {
                    definitions[definition.name] = definition
                    continue
                }
                
                Compass.print("Malformed object at query level (should this be a Validation or a Definition?): \(queryElement)")
                return nil
            }
            if queryElement.type == .array,
               let query = Query(element: queryElement,
                                 compass: self) {
                queries.append(query)
                continue
            }
            
            Compass.print("Failed to process query: \(queryElement)")
            return nil
        }
        
        validations["."] = Validation(element: ^["validation":".","allow":[],"disallow":[]], compass: self)
    }
    
    public convenience init?(json: HalfHitch) {
        guard let root = Spanker.parse(halfhitch: json) else { return nil }
        self.init(queries: root)
    }
    
    public convenience init?(json: Hitch) {
        self.init(json: json.halfhitch())
    }
    
    public convenience init?(json: String) {
        self.init(json: Hitch(string: json).halfhitch())
    }
    
    public func add(validation name: Hitch,
                    callback: @escaping CompassValidation) {
        customValidations[name] = callback
        
        // we need to ensure there is an existing Validation by this name
        if validations[name] == nil {
            validations[name] = Validation(element: ^[
                "validation": name,
                "allow": [],
                "disallow": []
            ], compass: self)
        }
    }
    
    public func matches(against: JsonElement) -> JsonElement? {
        return matches(against: against, queries: queries)
    }
    
    public func matches(against: HalfHitch) -> JsonElement? {
        guard let element = Spanker.parse(halfhitch: against) else { return nil }
        return matches(against: element)
    }
    
    public func matches(against: Hitch) -> JsonElement? {
        return matches(against: against.halfhitch())
    }
    
    public func matches(against: String) -> JsonElement? {
        return matches(against: Hitch(string: against).halfhitch())
    }
    
    public func replaceWithDefinition(_ element: JsonElement) -> JsonElement? {
        guard let value = element.halfHitchValue,
              value.starts(with: "$") else { return element }
        
       if let definition = definitions[value.hitch()] {
           return definition.element
       }
       Compass.print("Unable to find definition: \(element)")
       return nil
    }
    
}
