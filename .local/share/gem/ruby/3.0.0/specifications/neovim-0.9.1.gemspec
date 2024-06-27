# -*- encoding: utf-8 -*-
# stub: neovim 0.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "neovim".freeze
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex Genco".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-08-13"
  s.email = ["alexgenco@gmail.com".freeze]
  s.executables = ["neovim-ruby-host".freeze]
  s.files = ["exe/neovim-ruby-host".freeze]
  s.homepage = "https://github.com/neovim/neovim-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.3.25".freeze
  s.summary = "A Ruby client for Neovim".freeze

  s.installed_by_version = "3.3.25" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<msgpack>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.14"])
    s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<vim-flavor>.freeze, [">= 0"])
  else
    s.add_dependency(%q<msgpack>.freeze, ["~> 1.1"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.14"])
    s.add_dependency(%q<pry-byebug>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<vim-flavor>.freeze, [">= 0"])
  end
end
