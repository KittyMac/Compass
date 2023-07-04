import XCTest

import Compass
import Spanker

final class HitchTests: XCTestCase {
    
    func testCompile() {
        let compassJson = """
        [
            [
                "// simple match",
                "line1",
                "!--",
                "*--",
                "REPEAT",
                "REPEAT_UNTIL_STRUCTURE",
                "*",
                "?",
                "!*",
                ".",
                "DEBUG",
                "/line(.*)/",
                ["KEY", "()", "IsString"]
            ]
        ]
        """
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        XCTAssertEqual(compass.description, #"[["// simple match","line1","!--","*--","REPEAT","REPEAT_UNTIL_STRUCTURE","*","?","!*",".","DEBUG","/line(.*)/",["KEY","()","IsString"]]]"#)
    }
    
    func testSimpleMatch0() {
        let sourceJson = """
        [
            "line0",
            "line1",
            "line2",
            "line3",
            "line4",
        ]
        """
        
        let compassJson = """
        [
            [
                "// should capture line2",
                "line1",
                ["KEY", "()", "."],
                "line3",
            ]
        ]
        """
        
        let expectedMatches = ^[
            ["KEY": ["line2"]]
        ]
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
    
    func testSimpleMatch1() {
        let sourceJson = """
        [
            "DOG",
            "CAT1",
            "DOG",
            "ELEPHANT",
            "DOG",
            "CAT2",
            "DOG"
            "KITTEN0",
            "DOG"
        ]
        """
        
        let compassJson = """
        [
            {
                "validation": "isCat",
                "allow": [
                    "/CAT\\d+/",
                    "/KITTEN\\d+/"
                ],
                "disallow": []
            },
            [
                "// should capture both cats",
                "DOG",
                ["KEY", "()", "isCat"],
                "DOG"
            ]
        ]
        """
        
        let expectedMatches = ^[
            ["KEY": ["CAT1"]],
            ["KEY": ["CAT2"]],
            ["KEY": ["KITTEN0"]]
        ]
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
    
    func testComplexMatch0() {
        let sourceJson = """
        [
            "lorem ipsum",
            "-- character",
            "NAME",
            "Gandlaf",
            "CLASS",
            "Wizard",
            "HP",
            "100",
            "lorem ipsum",
            "lorem ipsum",
            "-- character",
            "NAME",
            "Gimli",
            "CLASS",
            "Warrior",
            "HP",
            "500",
            "lorem ipsum",
            "lorem ipsum",
            "-- character",
            "NAME",
            "Legolas",
            "CLASS",
            "Elf",
            "HP",
            "-1000",
        ]
        """
        
        let compassJson = """
        [
            {
                "validation": "isClass",
                "allow": [
                    "/(Wizard|Warrior)/"
                ],
                "disallow": []
            },
            {
                "validation": "isName",
                "allow": [
                    "/\\w+/"
                ],
                "disallow": []
            },
            {
                "validation": "isHitPoints",
                "allow": [
                    "/\\d+/"
                ],
                "disallow": []
            },
            [
                "NAME",
                ["NAME", "()", "isName"],
                "CLASS",
                ["CLASS", "()", "isClass"],
                "HP",
                ["HITPOINTS", "()", "isHitPoints"],
            ]
        ]
        """
        
        // Note: Legolas will not be matched because -1000 is not valid hitpoints
        let expectedMatches = ^[
            ["NAME": ["Gandlaf"], "CLASS": ["Wizard"], "HITPOINTS": ["100"] ],
            ["NAME": ["Gimli"], "CLASS": ["Warrior"], "HITPOINTS": ["500"] ]
        ]

        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
}
