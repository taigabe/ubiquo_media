# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ubiquo_media/version"

Gem::Specification.new do |s|
  s.name        = "ubiquo_media"
  s.version     = UbiquoMedia.version
  s.authors     = ["Jordi Beltran", "Albert Callarisa", "Bernat Foj", "Eric Garcia", "Felip Ladrón", "David Lozano", "Toni Reina", "Ramon Salvadó", "Arnau Sánchez"]
  s.homepage    = "http://www.ubiquo.me"
  s.summary     = %q{This gem provides a media management system for Ubiquo}
  s.description = %q{This gem provides a media management system for Ubiquo}

  s.rubyforge_project = "ubiquo_media"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "ubiquo_core", ["~> 0.9.0.b1"]
  s.add_development_dependency "sqlite3", "~> 1.3.5"
  s.add_development_dependency "mocha", "~> 0.10.0"

end
