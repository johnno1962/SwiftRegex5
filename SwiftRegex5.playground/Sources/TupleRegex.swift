//
//  TupleRegex.swift
//  SwiftRegex5
//
//  Created by John Holdsworth on 13/01/2018.
//  Copyright © 2018 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/SwiftRegex5
//
//  $Id: //depot/SwiftRegex5/SwiftRegex5.playground/Sources/TupleRegex.swift#39 $
//

import Foundation

/// Regex literal can be suffixed
/// e.g. "[A-Z]+".caseInsensitve
public protocol RegexLiteral {
    var regexOptioned: RegexOptioned { get }
}

/// Any String can be a regex literal
extension String: RegexLiteral {
    public var regexOptioned: RegexOptioned {
        return RegexOptioned(pattern: self, options: RegexOptioned.defaultOptions)
    }
}

public struct RegexOptioned: RegexLiteral, Hashable {

    public static var defaultOptions: NSRegularExpression.Options = []

    let pattern: String
    let options: NSRegularExpression.Options
    public var regexOptioned: RegexOptioned { return self }
    #if swift(>=5.0)
    public func hash(into: inout Hasher) {
        pattern.hash(into: &into)
        options.rawValue.hash(into: &into)
    }
    #else
    public var hashValue: Int { return pattern.hashValue ^ Int(options.rawValue) }
    #endif
    func add(options extra: NSRegularExpression.Options) -> RegexLiteral {
        return RegexOptioned(pattern: pattern, options: options.union(extra))
    }
}

extension RegexOptioned: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(pattern: value, options: RegexOptioned.defaultOptions)
    }
}

extension RegexLiteral {
    public var caseInsensitive: RegexLiteral {
        return regexOptioned.add(options: .caseInsensitive)
    }
    public var allowCommentsAndWhitespace: RegexLiteral {
        return regexOptioned.add(options: .allowCommentsAndWhitespace)
    }
    public var ignoreMetacharacters: RegexLiteral {
        return regexOptioned.add(options: .ignoreMetacharacters)
    }
    public var dotMatchesLineSeparators: RegexLiteral {
        return regexOptioned.add(options: .dotMatchesLineSeparators)
    }
    public var anchorsMatchLines: RegexLiteral {
        return regexOptioned.add(options: .anchorsMatchLines)
    }
    public var useUnixLineSeparators: RegexLiteral {
        return regexOptioned.add(options: .useUnixLineSeparators)
    }
    public var useUnicodeWordBoundaries: RegexLiteral {
        return regexOptioned.add(options: .useUnicodeWordBoundaries)
    }
    public var regexLazy: RegexLazy {
        return RegexLazy(literal: self)
    }
}

public struct RegexLazy {
    let literal: RegexLiteral
}

/// basic regex extensions to String
extension StringProtocol {
    fileprivate func nsRange(pos: Int? = nil) -> NSRange {
        #if swift(>=5.0)
        var range = NSRange(startIndex ..< endIndex, in: self)
        #else
        var range = NSMakeRange(0, self.utf16.count)
        #endif
        if let pos = pos, pos != 0 {
            range.location += pos
            range.length -= pos
        }
        return range
    }

    /// longhand API and bridge to implementation class
    public func containsMatch(of regex: RegexLiteral, pos: Int? = nil) -> Bool {
        return RegexImpl<String>(pattern: regex).matchResult(target: self, pos: pos) != nil
    }
    public func firstMatch<T>(of regex: RegexLiteral, pos: Int? = nil, group: Int? = nil) -> T? {
        return RegexImpl<T>(pattern: regex).match(target: self, pos: pos, group: group)
    }
    public func allMatches<T>(of regex: RegexLiteral, pos: Int? = nil, group: Int? = nil) -> [T] {
        return RegexImpl<T>(pattern: regex).matches(target: self, pos: pos, group: group)
    }
    public func lazyMatches<T>(of regex: RegexLiteral, pos: Int? = nil, group: Int? = nil) -> AnyIterator<T> {
        return RegexImpl<T>(pattern: regex).iterator(target: self, pos: pos, group: group)
    }
    public func replacing<T>(regex: RegexLiteral, pos: Int? = nil, group: Int? = nil,
                             with template: T) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, pos: pos, group: group, template: template)
    }
    public func replacing<T>(regex: RegexLiteral, pos: Int? = nil, group: Int? = nil,
                             with templates: [T]) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, pos: pos, group: group, templates: templates)
    }
    public func replacing<T>(regex: RegexLiteral, pos: Int? = nil, group: Int? = nil,
                             exec closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, pos: pos, group: group, exec: closure)
    }
}

/// build subscript based shorthand on extensions to StringProtocol
extension StringProtocol {

    /// plain old string regex pattern matches
    public subscript(pattern: RegexLiteral) -> Bool {
        return containsMatch(of: pattern)
    }

    /// single match and global replace
    public subscript<T>(pattern: RegexLiteral) -> T? {
        get { return firstMatch(of: pattern) }
        set(newValue) { self = Self(replacing(regex: pattern, with: newValue!))! }
    }

    /// mutliple match and selective replace
    public subscript<T>(pattern: RegexLiteral) -> [T] {
        get { return allMatches(of: pattern) }
        set(newValues) { self = Self(replacing(regex: pattern, with: newValues))! }
    }

    /// operating on individual group
    public subscript(pattern: RegexLiteral, group: Int) -> String? {
        get { return firstMatch(of: pattern, group: group) }
        set(newValue) { self = Self(replacing(regex: pattern, group: group, with: newValue!))! }
    }
    public subscript<T>(pattern: RegexLiteral, group: Int) -> [T] {
        get { return allMatches(of: pattern, group: group) }
        set(newValue) { self = Self(replacing(regex: pattern, group: group, with: newValue))! }
    }

    /// closure replace
    public subscript<T>(pattern: RegexLiteral) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = Self(replacing(regex: pattern, exec: closure))! }
    }

    public subscript<T>(pattern: RegexLiteral, group: Int) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = Self(replacing(regex: pattern, group: group, exec: closure))! }
    }

    /// inplace replace
    public subscript(pattern: RegexLiteral, template: String) -> String {
        return replacing(regex: pattern, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, templates: [T]) -> String {
        return replacing(regex: pattern, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral,
                        closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return replacing(regex: pattern, exec: closure)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, template: T) -> String {
        return replacing(regex: pattern, group: group, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, templates: [T]) -> String {
        return replacing(regex: pattern, group: group, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int,
                        closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return replacing(regex: pattern, group: group, exec: closure)
    }
}

/// lazy iterators
extension StringProtocol {

    public subscript<T>(pattern: RegexLazy) -> AnyIterator<T> {
        return lazyMatches(of: pattern.literal)
    }
    public subscript<T>(pattern: RegexLazy, group: Int) -> AnyIterator<T> {
        return lazyMatches(of: pattern.literal, group: group)
    }
}

/// future compiler-aware regex literals...
extension StringProtocol {

    /// future compiler-aware regex literals...
    public subscript<T>(regex: RegexImpl<T>) -> T? {
        get { return regex.match(target: self) }
        set(newValue) { self = Self(regex.replacing(target: self, template: newValue!))! }
    }
    public subscript<T>(regex: RegexImpl<T>) -> [T] {
        get { return regex.matches(target: self) }
        set(newValues) { self = Self(regex.replacing(target: self, templates: newValues))! }
    }
    public subscript<T>(regex: RegexImpl<T>) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = Self(regex.replacing(target: self, exec: closure))! }
    }
}

/// labeled versions if you prefer
extension StringProtocol {
    public subscript(pattern: RegexLiteral, group group: Int) -> String? {
        get { return firstMatch(of: pattern, group: group) }
        set(newValue) { self = Self(replacing(regex: pattern, group: group, with: newValue!))! }
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int) -> [T] {
        get { return allMatches(of: pattern, group: group) }
        set(newValue) { self = Self(replacing(regex: pattern, group: group, with: newValue))! }
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = Self(replacing(regex: pattern, group: group, exec: closure))! }
    }
    public subscript<T>(pattern: RegexLiteral, substitute template: T) -> String {
        return replacing(regex: pattern, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, substitute templates: [T]) -> String {
        return replacing(regex: pattern, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral,
            substitute closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return replacing(regex: pattern, exec: closure)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int, substitute template: T) -> String {
        return replacing(regex: pattern, group: group, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int, substitute templates: [T]) -> String {
        return replacing(regex: pattern, group: group, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int,
            substitute closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return replacing(regex: pattern, group: group, exec: closure)
    }
}

/// interface to Regex engine in use
public typealias RegexImpl = TupleRegex

private var regexCache = [RegexOptioned: NSRegularExpression]()
private var cacheLock = NSLock()

open class TupleRegex<T>: RegexLiteral, ExpressibleByStringLiteral {

    public let regexOptioned: RegexOptioned

    lazy var regex: NSRegularExpression = {
        cacheLock.lock(); defer { cacheLock.unlock() }
        if let regex = regexCache[self.regexOptioned] {
            return regex
        }
        do {
            let regex = try NSRegularExpression(pattern: self.regexOptioned.pattern,
                                                options: self.regexOptioned.options)
            regexCache[self.regexOptioned] = regex
            return regex
        } catch {
            fatalError("Could not parse regex: \(self.regexOptioned.pattern) - \(error)")
        }
    }()

    public init(pattern: RegexLiteral) {
        regexOptioned = pattern.regexOptioned
    }
    public required init(stringLiteral value: String) {
        regexOptioned = value.regexOptioned
    }

    /// matching
    func matchResult<SP: StringProtocol>(target: SP, pos: Int? = nil) -> NSTextCheckingResult? {
        return regex.firstMatch(in: String(target), options: [], range: target.nsRange(pos: pos))
    }
    open func match<SP: StringProtocol>(target: SP, pos: Int? = nil, group: Int? = nil) -> T? {
        return matchResult(target: target, pos: pos).flatMap {
            group != nil && $0.range(at: group!).location == NSNotFound ? nil :
                entuple(match: $0, from: NSString(string: String(target)), group: group)
        }
    }
    open func matches<SP: StringProtocol>(target: SP, pos: Int? = nil, group: Int? = nil) -> [T] {
        var out = [T]()
        let nstarget = NSString(string: String(target))
        regex.enumerateMatches(in: String(target), options: [], range: target.nsRange(pos: pos)) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            out.append(self.entuple(match: match!, from: nstarget, group: group))
        }
        return out
    }

    lazy var tupleTypeDescription = "\(T.self)"
    func entuple(match: NSTextCheckingResult, from target: NSString, group: Int? = nil) -> T {
        if let match = match as? T {
            return match
        }

        // https://stackoverflow.com/questions/24746397/how-can-i-convert-an-array-to-a-tuple
        func tuple<E>(from array: inout [E]) -> T? {
            if E.self == T.self,
               let tuple = (array.count == 2 ? array[1] : array[0]) as? T {
                return tuple
            }
            if [E].self == T.self {
                return array as? T
            }
            if MemoryLayout<E>.stride * (array.count - 1) == MemoryLayout<T>.stride &&
                tupleTypeDescription.hasSuffix(" \(E.self))") {
                return array.withUnsafeBufferPointer {
                    ($0.baseAddress! + 1).withMemoryRebound(to: T.self, capacity: 1) { $0[0] }
                }
            }
            return nil
        }

        let ats = group != nil ? group! ..< group! + 1 : 0 ..< match.numberOfRanges
        var nsranges: [NSRange] = ats.map { match.range(at: $0) }
        if let nsranges = tuple(from: &nsranges) {
            return nsranges
        }

        var substrs: [Substring?] = nsranges.map { $0.location == NSNotFound ? nil :
                                                Substring(target.substring(with: $0)) }
        if let substrs = tuple(from: &substrs) {
            return substrs
        }

        var groups: [String] = substrs.map { String($0 ?? "") }
        if let groups = tuple(from: &groups) {
            return groups
        }

        var ranges: [Range<String.Index>?] = nsranges.map { Range($0, in: target as String) }
        if let ranges = tuple(from: &ranges) {
            return ranges
        }

        fatalError("Cannot entuple type \(T.self) from \(groups[1...])")
    }

    /// replacing
    func detuple(newValue: T) -> [String?] {
        let children = Mirror(reflecting: newValue).children
        return children.count != 0 ? children.map { $0.value as? String } : [newValue as? String]
    }
    func groupRange(match: NSTextCheckingResult, replacements: [String?]) -> CountableRange<Int> {
        return replacements.count == 1 ? match.numberOfRanges == 2 ? 1 ..< 2 : 0 ..< 1 :
            (match.numberOfRanges == 1 ? 0 : 1) ..< min(match.numberOfRanges, replacements.count + 1)
    }

    open func replacing<SP: StringProtocol>(target: SP, pos: Int? = nil, group: Int? = nil, template: T) -> String {
        return replacing(target: target, pos: pos, group: group, templates: [template], global: true)
    }
    open func replacing<SP: StringProtocol>(target: SP, pos posin: Int? = nil, group forceGroup: Int? = nil,
                        templates: [T], global: Bool = false) -> String {
        if templates.count == 0 {
            return String(target)
        }
        var out = [String]()
        var pos = 0, matchno = 0

        let nstarget = NSString(string: String(target))
        regex.enumerateMatches(in: String(target), options: [], range: target.nsRange(pos: posin)) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let replacements = self.detuple(newValue: global ? templates[0] : templates[matchno])

            matchno += 1
            if !global && matchno == templates.count {
                stop.pointee = true
            }

            for group in forceGroup != nil ? forceGroup! ..< forceGroup! + 1 :
                    self.groupRange(match: match, replacements: replacements) {
                let range = match.range(at: group)
                if range.location != NSNotFound && range.location >= pos,
                    let replacement = replacements[forceGroup != nil ? 0 : max(0, group - 1)] {
                    out.append(nstarget.substring(with: NSMakeRange(pos, range.location - pos)))
                    out.append(self.regex.replacementString(for: match, in: String(target), offset: 0,
                                                            template: replacement))
                    pos = NSMaxRange(range)
                }
            }
        }

        out.append(nstarget.substring(with: target.nsRange(pos: pos)))
        return out.joined()
    }
    open func replacing<SP: StringProtocol>(target: SP, pos posin: Int? = nil, group: Int? = nil,
                        exec closure: @escaping (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        var out = [String]()
        var pos = 0

        let nstarget = NSString(string: String(target))
        regex.enumerateMatches(in: String(target), options: [], range: target.nsRange(pos: posin)) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group ?? 0)
            out.append(nstarget.substring(with: NSMakeRange(pos, range.location - pos)))
            out.append(closure(self.entuple(match: match, from: nstarget), stop))
            pos = NSMaxRange(range)
        }

        out.append(nstarget.substring(with: target.nsRange(pos: pos)))
        return out.joined()
    }

    /// interating
    private struct TupleIterator: IteratorProtocol {
        let regex: RegexImpl<T>
        let target: String
        let nstarget: NSString
        let group: Int?
        var pos: Int?

        public mutating func next() -> T? {
            if let match = regex.matchResult(target: target, pos: pos) {
                pos = NSMaxRange(match.range)
                return regex.entuple(match: match, from: nstarget, group: group)
            }
            return nil
        }
    }
    open func iterator<SP: StringProtocol>(target: SP, pos: Int? = nil, group: Int? = nil) -> AnyIterator<T> {
        var iterator = TupleIterator(regex: self, target: String(target),
                                     nstarget: NSString(string: String(target)),
                                     group: group, pos: pos)
        return AnyIterator {
            iterator.next()
        }
    }
}

/// use in switch
extension String {
    public subscript<T>(match: RegexMatch) -> T {
        return RegexImpl<T>(pattern: "").entuple(match: match.match!, from: NSString(string: self))
    }
    public subscript(match: RegexMatch, group: Int) -> String {
        return RegexImpl<String>(pattern: "").entuple(match: match.match!, from: NSString(string: self), group: group)
    }
}

public class RegexMatch {
    var match: NSTextCheckingResult?
    public init() {}
    public subscript(pattern: RegexLiteral) -> RegexPattern {
        return RegexPattern(literal: pattern, capture: self)
    }
}

extension RegexLiteral {
    public func regex(capture: RegexMatch?) -> RegexPattern {
        return RegexPattern(literal: self, capture: capture)
    }
}

public struct RegexPattern {
    let literal: RegexLiteral
    let capture: RegexMatch?
    public static func ~= (pattern: RegexPattern, value: String) -> Bool {
        if let match = RegexImpl<String>(pattern: pattern.literal).matchResult(target: value) {
            pattern.capture?.match = match
            return true
        }
        return false
    }
}
