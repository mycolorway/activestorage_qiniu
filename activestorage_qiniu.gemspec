
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activestorage_qiniu/version"

Gem::Specification.new do |spec|
  spec.name          = "activestorage_qiniu"
  spec.version       = ActivestorageQiniu::VERSION
  spec.authors       = ['Mycolorway', "seandong"]
  spec.email         = ["sindon@gmail.com"]

  spec.summary       = %q{Qiniu cloud service for Active Storage}
  spec.description   = %q{Qiniu cloud service for Active Storage}
  spec.homepage      = "https://zhiren.com"
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

  spec.add_dependency 'rails', ['>= 5.2.0.alpha', '< 6']
  spec.add_dependency 'qiniu', '~> 6.8.1'
end
