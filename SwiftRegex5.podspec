Pod::Spec.new do |s|
    s.name        = "SwiftRegex5"
    s.version     = "5.2.1"
    s.summary     = "Regular expressions for Swift version 5"
    s.homepage    = "https://github.com/johnno1962/SwiftRegex5"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/johnno1962/SwiftRegex5/blob/master/README.md"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "swiftregex@johnholdsworth.com" }

    s.ios.deployment_target = "10.0"
    s.osx.deployment_target = "10.11"
    s.source   = { :git => "https://github.com/johnno1962/SwiftRegex5.git", :tag => s.version }
    s.source_files = "SwiftRegex5.playground/Sources/*.swift"
end
