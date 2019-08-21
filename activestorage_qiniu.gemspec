
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activestorage_qiniu/version"

Gem::Specification.new do |spec|
  spec.name          = "activestorage_qiniu"
  spec.version       = ActivestorageQiniu::VERSION
  spec.authors       = ['Mycolorway', "seandong"]
  spec.email         = ["sindon@gmail.com"]

  spec.summary       = %q{Wraps the Qiniu Storage Service as an Active Storage service}
  spec.description   = %q{Wraps the Qiniu Storage Service as an Active Storage service. https://www.qiniu.com}
  spec.homepage      = "https://github.com/mycolorway/activestorage_qiniu"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_runtime_dependency 'rails', '>= 5.1.6.2'

  spec.add_dependency 'qiniu', '~> 6.9'
  spec.add_dependency 'retries', '~> 0.0.5'
end
