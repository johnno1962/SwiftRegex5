#  SwiftRegex5 - basic regex operations in Swift4

A basic regular expression library based on the idea that subscripting into a string with
a string should be a regex match. Where you might use an int or string subscript on a
container to specify a subset of the data, a string subscript on a String type is notionally
the matches with the subscript interpreted as a regex pattern which can be extracted,
assigned to or iterated over. Extensively rewritten, again, now that subscripts can be generic
the current version is now [TupleRegex.swift](SwiftRegex5.playground/Sources/TupleRegex.swift)
explored in [SwiftRegex5.playground](SwiftRegex5.playground.zip).

```Swift
import XCTest

var str = "Hello, playground"

// the first sections develop the idea from regex object to subscripts on string regexs

let word = RegexImpl<(first: String, rest: String)>(pattern: "(\\w)(\\w*)")

if let detail = word.match(target: str) {
    XCTAssertEqual(detail.first, "H")
    XCTAssertEqual(detail.rest, "ello")
}

let matches = word.matches(target: str)
print(matches)

for (first, rest) in word.matches(target: str) {
    print(first, rest)
}

for (first, rest) in word.iterator(target: str) {
    print(first, rest)
}

str = word.replacing(target: str, templates: [("O", "la")])
XCTAssertEqual(str, "Ola, playground")

// declare subscripts in extension on String to create a shorthand.
// tuple is global replace, array applies only the given matches
// one-tuple is equivalent to a String which is always group 0

str["(\\w)(\\w*)"] = [("B", "onjour")]
XCTAssertEqual(str, "Bonjour, playground")

if let detail: (first: String, rest: String) = str["(\\w)(\\w*)"] {
    XCTAssertEqual(detail.first, "B")
    XCTAssertEqual(detail.rest, "onjour")
}

if let (first, rest): (String, String) = str["(\\w)(\\w*)".caseInsensitive] {
    XCTAssertEqual(first, "B")
    XCTAssertEqual(rest, "onjour")
}

let matches3: [(String, String)] = str["(\\w)(\\w*)"]
print(matches3)

for (first, rest): (String, String) in str["(\\w)(\\w*)"] {
    print(first, rest)
}

for (first, rest): (String, String) in str["(\\w)(\\w*)".regexLazy] {
    print(first, rest)
}

str["(\\w)(\\w*)"] = [("S", "alut")]
XCTAssertEqual(str, "Salut, playground")

// fetch to tuple and assign from tuple operate on first match,

var numbers = "phone: 555 666-1234 fax: 555 666-4321"

if let match: (String, String, String) = numbers["(\\d+) (\\d+)-(\\d+)"] {
    XCTAssert(match == ("555", "666","1234"), "single match")
}
numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "777", "1234")]
XCTAssertEqual(numbers, "phone: 555 777-1234 fax: 555 666-4321")

// arrays of tuples operate on all matches

let matches4: [(String, String, String)] = numbers["(\\d+) (\\d+)-(\\d+)"]
print(matches4)

numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "888", "1234"), ("555", "999", "4321")]
XCTAssertEqual(numbers, "phone: 555 888-1234 fax: 555 999-4321")

// individual groups of first match can be addressed and assigned to

if let area = numbers["(\\d+) (\\d+)-(\\d+)", 1] {
    XCTAssertEqual(area, "555")
}

numbers["(\\d+) (\\d+)-(\\d+)", 1] = ["444"]
XCTAssertEqual(numbers, "phone: 444 888-1234 fax: 555 999-4321")

// a single element tuple always refers to the entire match (group 0)

if let area: (String) = numbers["(\\d+) (\\d+)-(\\d+)"] {
    XCTAssertEqual(area, "444 888-1234")
}

numbers["(\\d+) (\\d+)-(\\d+)"] = ("444 000-1234")
XCTAssertEqual(numbers["(\\d+) (\\d+)-(\\d+)"], "444 000-1234")

// replacements are regex templates and can be specified inline

XCTAssertEqual(str["(\\w)(\\w*)", "$1-$2"], "S-alut, p-layground")

// assignment can be from a closure which is passed over all matches

str["(\\w)(\\w*)"] = {
    (groups: (first: String, rest: String), stop) -> String in
    return groups.first+groups.rest.uppercased()
}
XCTAssertEqual(str, "SALUT, pLAYGROUND")

// parsing a properties file using regex as iterator

let props = """
    name1 = value1
    name2 = value2
    """

var params = [String: String]()
for (name, value): (String, String) in props["(\\w+)\\s*=\\s*(.*)".regexLazy] {
    params[name] = value
}
XCTAssertEqual(params, ["name1": "value1", "name2": "value2"])

// arrays and tuples of String, Substring? and NSRange can be fetched from matches

if let r: [NSRange] = props["(\\w+)\\s*=\\s*(.*)"] {
    print(r)
}
if let r: (Substring?, Substring?) = props["(\\w+)\\s*=\\s*(.*)"] {
    print(r)
}
for r: [String] in props["(\\w+)\\s*=\\s*(.*)"] {
    print(r)
}
for r: (NSRange, NSRange) in props["(\\w+)\\s*=\\s*(.*)".regexLazy] {
    print(r)
}

// exploring use in switch/case

let match = RegexMatch()
switch str {
case "(\\w)(\\w*)".regex(capture: match):
    let (first, rest): (String, String) = str[match]
    print("\(first)~\(rest)")
default:
    break
}

// previous tests

var input = "The quick brown fox jumps over the lazy dog."

XCTAssertEqual(input["quick .* fox"], "quick brown fox", "basic match")

if input["quick orange fox"] {
    XCTAssert(false, "non-match fail")
}
else {
    XCTAssert(true, "non-match pass")
}

XCTAssertEqual(input["quick brown (\\w+)", 1], "fox", "group subscript")
XCTAssertEqual(input["the (\\w+)".caseInsensitive, 1], ["quick", "lazy"], "group matches")
XCTAssertEqual(input["(the lazy) (dog)?", 2], "dog", "optional group pass")
XCTAssertEqual(input["(the lazy) (cat)?", 2], nil, "nil optional group pass")

input["(the) (\\w+)"] = "$1 very $2"
XCTAssertEqual(input, "The quick brown fox jumps over the very lazy dog.", "replace pass")

input["(\\w)(\\w+)"] = {
    (groups: [Substring?], stop) in
    return groups[1]!.uppercased()+groups[2]!
}

XCTAssertEqual(input, "The Quick Brown Fox Jumps Over The Very Lazy Dog.", "block pass")

input["Quick (\\w+)", 1] = "Red $1"

XCTAssertEqual(input, "The Quick Red Brown Fox Jumps Over The Very Lazy Dog.", "group replace pass")

var z = "👨‍👩‍👧‍👦👨‍👩‍👧‍👦 👨‍👩‍👧‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺 🇭🇺🇭🇺"

z["👨‍👩‍👧‍👦"] = "👩‍👩‍👦"
XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺 🇭🇺🇭🇺", "emoji pass")

z["🇭🇺"] = {
    (groups: [Substring?], stop) in
    stop.pointee = true
    return "🇫🇷"
}
XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇫🇷 🇭🇺🇭🇺", "emoji pass")

z["👩‍👩‍👦"] = ["$0", nil, "$0", "👪", "👩‍👧‍👧"]

XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👪👩‍👧‍👧👩‍👩‍👦 🇫🇷 🇭🇺🇭🇺", "emoji pass")
```
