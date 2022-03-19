//: Playground - noun: a place where people can play

import XCTest

var str = "Hello, playground"

// TupleRegex.swift defines seven new member functions on String to make working
// with regular expressions easier.

if str.containsMatch(of: "play\\w+") {
    XCTAssert(true, "basic match")
}

if let firstWord: String = str.firstMatch(of: "(?<name>\\w)(\\w*)") {
    XCTAssertEqual(firstWord, "Hello", "extract match")
}

// functions are generic by return value and can single value or tuples or
// arrays of any of: String, Substring?, Range<String.Index>? or NSRange

if let (initial, remainnder): (String, String) = str.firstMatch(of: "(\\w)(\\w*)") {
    XCTAssert((initial, remainnder) == ("H", "ello"), "extract match")
}

// While tuples start at group 1, arrays contain "group 0", the full match

if let match: [Substring?] = str.firstMatch(of: "(\\w)(\\w*)") {
    XCTAssertEqual(match, ["Hello", "H", "ello"], "array match")
}

// when not optional it is also possible to extract all matches from a string

let allWords: [(String, String)] = str.allMatches(of: "(\\w)(\\w*)")
XCTAssert(allWords[0] == ("H", "ello") && allWords[1] == ("p", "layground"))

// there are functions available to replace the contents of the match

let replaced1 = str.replacing(regex: "Hello", with: "Ola")
XCTAssertEqual(replaced1, "Ola, playground", "simple replace")

// simple tuple values are a gloal replace

let replaced2 = str.replacing(regex: "\\w+", with: "Ola")
XCTAssertEqual(replaced2, "Ola, Ola", "global replace")

// to replace only the first or "N" matches use array assignment

let replaced3 = str.replacing(regex: "(\\w)(\\w*)", with: [("S", "alute")])
XCTAssertEqual(replaced3, "Salute, playground", "constrained replace")

// where pocessing is required a closure replace can be used.

let replaced4 = str.replacing(regex: "(\\w)(\\w*)") {
    (groups: (initial: String, remainder: String), stop) in
    return groups.initial+groups.remainder.uppercased()
}
XCTAssertEqual(replaced4, "HELLO, pLAYGROUND", "constrained replace")

// At this point it's possible to define a generic subscript of a String by a
// String with getters and setters to provide a shorthand for these functions.

if str["play\\w+"] {
    XCTAssert(true, "basic match")
}

if let firstWord: String = str["(\\w)(\\w*)"] {
    XCTAssertEqual(firstWord, "Hello", "extract match")
}

if let (initial, remainnder): (String, String) = str["(\\w)(\\w*)"] {
    XCTAssert((initial, remainnder) == ("H", "ello"), "extract match")
}

let allWords2: [(String, String)] = str["(\\w)(\\w*)"]
XCTAssert(allWords2[0] == ("H", "ello") && allWords2[1] == ("p", "layground"))

// perhaps this makes more sense when you realise subscripts can be assigned to

str["Hello"] = "Ola"
XCTAssertEqual(str, "Ola, playground", "simple replace")

str["\\w+"] = "Ola"
XCTAssertEqual(str, "Ola, Ola", "global replace")

str["(\\w)(\\w*)"] = [("S", "alute")]
XCTAssertEqual(str, "Salute, Ola", "constrained replace")

// this yields a single unified syntax for a variety of regex operations.

str = "Hello, playground"

// the first sections develop the idea from regex object to subscripts to string regexs

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

// declare subscripts in extension on String to create a shorthand

if let detail: (first: String, rest: String) = str[word] {
    XCTAssertEqual(detail.first, "O")
    XCTAssertEqual(detail.rest, "la")
}

str["(\\w)(\\w*)"] = [("B", "onjour")]
XCTAssertEqual(str, "Bonjour, playground")

// declare subscript on pattern as text (loose type inference)

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
    XCTAssert(match == ("555", "666", "1234"))
}

let allMatches: [(String, String, String)] = numbers["(\\d+) (\\d+)-(\\d+)"]
XCTAssert(allMatches[1] == ("555", "666", "4321"))

let secondMatch: (String, String, String) = numbers["(\\d+) (\\d+)-(\\d+)"][1]
XCTAssert(secondMatch == ("555", "666", "4321"))

numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "777", "1234")]
XCTAssertEqual(numbers, "phone: 555 777-1234 fax: 555 666-4321")

// arrays of tuples operate on all matches

let matches4: [(String, String, String)] = numbers["(\\d+) (\\d+)-(\\d+)"]
print(matches4)
numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "888", "1234"), ("555", "999", "4321")]
XCTAssertEqual(numbers, "phone: 555 888-1234 fax: 555 999-4321")

// individual groups of first match can be addressed and assigned to

if let area: String = numbers["(\\d+) (\\d+)-(\\d+)", 1] {
    print(area)
    XCTAssertEqual(area, "555")
}

numbers["(\\d+) (\\d+)-(\\d+)", 1] = ["444"]
print(numbers)
XCTAssertEqual(numbers, "phone: 444 888-1234 fax: 555 999-4321")

// a single element tuple always refers to the entire match (group 0)

if let all: (String) = numbers["(\\d+) (\\d+)-(\\d+)"] {
    XCTAssertEqual(all, "444 888-1234")
}

if let all: (String) = numbers["(\\d+) (\\d+)-(\\d+)", 0] {
    XCTAssertEqual(all, "444 888-1234")
}

if let area: String = numbers["(\\d+) (\\d+)-(\\d+)", 1] {
    XCTAssertEqual(area, "444")
}

let areas: [String] = numbers["(\\d+) (\\d+)-(\\d+)", 1]
XCTAssertEqual(areas, ["444", "555"])

numbers["(\\d+) (\\d+)-(\\d+)"] = ("444 000-1234")
XCTAssertEqual(numbers["(\\d+) (\\d+)-(\\d+)"], "444 000-1234")

// replacements are regex templates and can be specified inline

XCTAssertEqual(str["(\\w)(\\w*)", 2, "-$2"], "S-alut, p-layground")

// assignment can be from a closure which is passed over all matches

str[word] = {
    (groups, stop) -> String in
    return groups.first.uppercased()+groups.rest
}
XCTAssertEqual(str, "Salut, Playground")

str["(\\w)(\\w*)"] = {
    (groups: (first: String, rest: String), stop) -> String in
    return groups.first+groups.rest.uppercased()
}
XCTAssertEqual(str, "SALUT, PLAYGROUND")

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
case match["(\\w)(\\w*)"]:
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

let rgs: [Range<String.Index>?] = input["the (\\w+)".caseInsensitive, 1]
XCTAssertEqual(rgs.map { input[$0!] }, ["quick", "lazy"], "range matches")
XCTAssertEqual(input["quick brown (\\w+)", 1], "fox", "group subscript")
XCTAssertEqual(input["the (\\w+)".caseInsensitive, 1], ["quick", "lazy"], "group matches")
XCTAssertEqual(input["(the lazy) (dog)?", 2], "dog", "optional group pass")
XCTAssertEqual(input["(the lazy) (cat)?", 2], nil, "nil optional group pass")

for subs: [Substring?] in input["(the) ?(lazy)?".caseInsensitive] {
    print(subs)
}

for subs: (Substring?, Substring?) in input["(the) (lazy)?".caseInsensitive] {
    print(subs)
}

for subs: Substring? in input["(the) (lazy)?".caseInsensitive, 2] {
    print(subs)
}

for subs: Substring? in input["(the) (lazy)?".caseInsensitive.regexLazy, 2] {
    print(subs)
}

input["(the) (\\w+)"] = "$1 very $2"
XCTAssertEqual(input, "The quick brown fox jumps over the very lazy dog.", "replace pass")

input["(\\w)(\\w+)"] = {
    (groups: (initial: String, remainder: String), stop) in
    return groups.initial.uppercased()+groups.remainder
}

XCTAssertEqual(input, "The Quick Brown Fox Jumps Over The Very Lazy Dog.", "block pass")

input["Quick (\\w+)", 1] = "Red $1"
print(input)
XCTAssertEqual(input, "The Quick Red Brown Fox Jumps Over The Very Lazy Dog.", "group replace pass")

if let a: [String] = "Hello, playground"["(\\w)(\\w*)"] {
    print(a)
}
let a: [String] = "Hello, playground"["(\\w)(\\w*)"]
print(a)
for a: String in "Hello, playground"["(\\w)(\\w*)"] {
    print(a)
}

// new special casing of single element tuples
var str1 = "hello world"
if let world: String = str1["\\w+ (\\w+)"] {
    XCTAssertEqual(world, "world")
}

str1["\\w+ (\\w+)"] = "single"
XCTAssertEqual(str1, "hello single")

let datePattern = #"(\d{4})-(\d{2})-(\d{2})"#
let date = "2018-01-01"
if let (year, month, day): (String, String, String) = date[datePattern] {
    print( year, month, day )
}

var date2 = "0000-00-00"
date2[datePattern] = ("2018", "01", "01")
print(date == date2)

let dates = "2018-01-01 2019-02-02 2020-03-03"
for (year, month, day): (String, String, String) in  date[datePattern] {
    print( year, month, day )
}

/// assorted testing
var capture = RegexMatch()
switch input {
case capture["Fox (\\w+)"]:
    print(input[capture, 1])
default:
    break
}

var s = "Hello, playground"
s["(\\w)(\\w*)"] = [("M", "ellooo")]
print(s)
s["(\\w)(\\w*)"] = ("M", "ellooo")
print(s)
s["(\\w)(\\w*)"] = ["Na", "Gesellschaft"]
print(s)
s["(\\w)(\\w*)"] = Optional(["Na", "Gesellschaft"])
print(s)
s["(\\w)(\\w*)"] = [("Na", "Gesellschaft")]
print(s)
for i in stride(from: 1, to: 17, by: 4) {
    print(i)
}
var a1 = "abcd"
a1["(.)(.)"] = [("n", "m")]
print(a1)
print(a1[".", [nil, "$0$0", "a"]])
"" + "abcd"["(.)(.)", 2][1]
var detail1: [(String, String)] = "abcd"["(.)(.)"]
if let a2 = "abcd"["(.)(.)", 2] {
    a2
}
let s3: [String] = "abcd"["(.)(.)", 2]
for a4: String in "abcd"["(.)(.)", 2] {
    print(a4)
}
"aabbccdd"["(..)(..)", 2, "ee"]
"aabbccdd"["(..)(..)", 2, ["cc"]]

struct C {
    subscript (s: String) -> String? {
        return ""
    }
    subscript (s: String) -> [String] {
        return [""]
    }
}

C()[""] ?? ""
let s1 = C()[""]!
if let _ = C()[""] ?? nil {
}
let s2: [String] = C()[""]

if case let z = 44 { } 

"abc"["(\\w)(\\w)", substitute: ("$2", "$1")]
"abc"["(\\w)(\\w)", substitute: { (groups: (String, String), stop) in
    groups.1+groups.0 }]
"abc"["(\\w)(\\w)", substitute: { (groups: (String, String), stop) in
    groups.1.uppercased()+groups.0 }]
let c = "abcd".replacing(regex: "(\\w)(\\w)") {
    (groups: (String, String), stop) in
    groups.1.uppercased()+groups.0
}
"abc"["(.)(.)"].map { (groups: (String, String)) in
    return groups.1+groups.0 }.joined()
"abc"["(.)(.)"].map { (groups: [String]) in
    return groups[2]+groups[1] }.joined()
print("abcde"["(.)(.)", 1].map { $0+"-" }.joined())

let s5: [String] = "abcd".allMatches(of: ".")
var s6 = "1234"
s6.replacing(regex: "(.)(.)", with: [("$0"), ("k", "j$2j")])
s6["(.)(.)"] = [("$0"), ("k", "j$2j")]
print(s6)
