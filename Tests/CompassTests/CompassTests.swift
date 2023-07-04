import XCTest

import Compass
import Spanker

final class HitchTests: XCTestCase {
    
    func testCompile() {
        let compassJson = #"""
        [
            [
                "// simple match",
                "line1",
                "!--",
                "*--",
                "*",
                "?",
                "!*",
                ".",
                "DEBUG",
                /line(.*)/igm,
                ["KEY", "()", "IsString"]
            ]
        ]
        """#
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        XCTAssertEqual(compass.description, #"[["// simple match","line1","!--","*--","*","?","!*",".","DEBUG",/line(.*)/igm,["KEY","()","IsString"]]]"#)
    }
    
    func testSimpleMatch0() {
        let sourceJson = #"""
        [
            "line0",
            "line1",
            "line2",
            "line3",
            "line4",
        ]
        """#
        
        let compassJson = #"""
        [
            [
                "// should capture line2",
                "line1",
                ["KEY", "()", "."],
                "line3",
            ]
        ]
        """#
        
        let expectedMatches = ^[
            ["KEY": ["line2"]]
        ]
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
    
    func testSimpleMatch1() {
        let sourceJson = #"""
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
        """#
        
        let compassJson = #"""
        [
            {
                "validation": "isCat",
                "allow": [
                    /CAT\d+/,
                    /KITTEN\d+/
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
        """#
        
        let expectedMatches = ^[
            ["KEY": ["CAT1"]],
            ["KEY": ["CAT2"]],
            ["KEY": ["KITTEN0"]]
        ]
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
    
    func testSimpleMatchRegex0() {
        let sourceJson = #"""
        [
            "-- table --"
        ]
        """#
        
        let compassJson = #"""
        [
            [
                "// capture the name of all structures",
                ["STRUCTURE", /-- (\w+) --/i, "."],
            ]
        ]
        """#
        
        let expectedMatches = ^[
            ["STRUCTURE": ["table"]]
        ]
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
    
    func testComplexMatch0() {
        let sourceJson = #"""
        [
            "-- table --",
            "Title: The Lord of the Rings",
            "Author: J.R.R Tolkien",
            "-- table --",
            "NAME",
            "Gandlaf",
            "-- img --",
            "-- http://www.lotr.com/gandalf.png --",
            "-- endimg --",
            "CLASS",
            "Wizard",
            "HP",
            "100",
            "DESCRIPTION",
            "Gandalf is a wizard and a member of the Istari, a group of angelic beings sent to Middle-earth in human form to aid the free peoples in their struggle against the forces of darkness.",
            "He is known for his long grey robes, a wide-brimmed hat, and a staff.",
            "In his initial appearance as Gandalf the Grey, he is depicted as a wise and mysterious figure with a deep knowledge of the world and a strong connection to nature.",
            "-- table --",
            "NAME",
            "Gimli",
            "-- img --",
            "-- http://www.lotr.com/gimli.png --",
            "-- endimg --",
            "CLASS",
            "Warrior",
            "HP",
            "500",
            "DESCRIPTION",
            "Gimli is the son of Gloin, one of the dwarves who accompanied Bilbo Baggins on his adventure in The Hobbit.",
            "Like his father, Gimli is a skilled warrior and craftsman, known for his expertise in axe combat and his loyalty to his kin.",
            "He hails from the city of Erebor, the Lonely Mountain, which was once home to a vast treasure and the dwarves' ancestral kingdom.",
            "Gimli is chosen to represent the dwarves as a member of the Fellowship of the Ring.",
            "Despite initial reservations and tensions between dwarves and elves, Gimli forms an unlikely friendship with Legolas, an elf, during their quest.",
            "Together, they face numerous perils and challenges while journeying through Middle-earth.",
            "-- table --",
            "NAME",
            "Legolas",
            "-- img --",
            "-- http://www.lotr.com/legolas.png --",
            "-- endimg --",
            "CLASS",
            "Elf",
            "HP",
            "-1000",
            "DESCRIPTION",
            "Legolas is a prince of the Woodland Realm of Mirkwood and the son of Thranduil, the Elvenking.",
            "He is described as being fair, graceful, and possessing keen senses.",
            "Legolas is known for his exceptional archery skills, often displaying great accuracy and agility with his bow and arrows."
        ]
        """#
        
        let compassJson = #"""
        [
            {
                "validation": "isClass",
                "allow": [
                    /(Wizard|Warrior|Elf|Rogue)/
                ],
                "disallow": []
            },
            {
                "validation": "isName",
                "allow": [
                    /[\.\w\s]+/
                ],
                "disallow": []
            },
            {
                "validation": "isHitPoints",
                "allow": [
                    /\d+/
                ],
                "disallow": []
            },
            {
                "validation": "isStory",
                "allow": [],
                "disallow": [
                    /(NAME|CLASS|HP|DESCRIPTION)/
                ]
            },
            [
                "// Book Title",
                ["TITLE", /Title: ([\.\w\s]+)/, "isName"]
            ],
            [
                "// Book Author",
                ["AUTHOR", /Author: ([\.\w\s]+)/, "isName"]
            ],
            [
                "// Fantasy Characters",
                "NAME",
                ["NAME", "()", "isName"],
                "*--",
                "CLASS",
                ["CLASS", "()", "isClass"],
                "HP",
                ["HITPOINTS", "()", "isHitPoints"],
                "DESCRIPTION",
                [
                    "REPEAT",
                    ["STORY", "()", "isStory"]
                ],
                "^--"
            ]
        ]
        """#
        
        // Note: Legolas will not be matched because -1000 is not valid hitpoints
        let expectedMatches = ^[
            [
                "TITLE": ["The Lord of the Rings"]
            ],
            [
                "AUTHOR": ["J.R.R Tolkien"]
            ],
            [
                "NAME": ["Gandlaf"],
                "CLASS": ["Wizard"],
                "HITPOINTS": ["100"],
                "STORY": [
                    "Gandalf is a wizard and a member of the Istari, a group of angelic beings sent to Middle-earth in human form to aid the free peoples in their struggle against the forces of darkness.",
                    "He is known for his long grey robes, a wide-brimmed hat, and a staff.",
                    "In his initial appearance as Gandalf the Grey, he is depicted as a wise and mysterious figure with a deep knowledge of the world and a strong connection to nature."
                ]
            ],
            [
                "NAME": ["Gimli"],
                "CLASS": ["Warrior"],
                "HITPOINTS": ["500"],
                "STORY": [
                    "Gimli is the son of Gloin, one of the dwarves who accompanied Bilbo Baggins on his adventure in The Hobbit.",
                    "Like his father, Gimli is a skilled warrior and craftsman, known for his expertise in axe combat and his loyalty to his kin.",
                    "He hails from the city of Erebor, the Lonely Mountain, which was once home to a vast treasure and the dwarves' ancestral kingdom.",
                    "Gimli is chosen to represent the dwarves as a member of the Fellowship of the Ring.",
                    "Despite initial reservations and tensions between dwarves and elves, Gimli forms an unlikely friendship with Legolas, an elf, during their quest.",
                    "Together, they face numerous perils and challenges while journeying through Middle-earth."
                ]
            ]
        ]

        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.sortKeys().description, expectedMatches.sortKeys().description)
    }
}
