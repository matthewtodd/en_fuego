# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{oauth_provider}
  s.version = "0.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["halorgium"]
  s.date = %q{2010-07-13}
  s.description = %q{Oauth provider wrapper}
  s.email = %q{tim@spork.in}
  s.files = ["lib/oauth_provider/backends/abstract.rb", "lib/oauth_provider/backends/data_mapper/consumer.rb", "lib/oauth_provider/backends/data_mapper/user_access.rb", "lib/oauth_provider/backends/data_mapper/user_request.rb", "lib/oauth_provider/backends/data_mapper.rb", "lib/oauth_provider/backends/in_memory.rb", "lib/oauth_provider/backends/mysql.rb", "lib/oauth_provider/backends/sequel.rb", "lib/oauth_provider/backends/sqlite3.rb", "lib/oauth_provider/backends.rb", "lib/oauth_provider/consumer.rb", "lib/oauth_provider/fixes.rb", "lib/oauth_provider/provider.rb", "lib/oauth_provider/token.rb", "lib/oauth_provider/user_access.rb", "lib/oauth_provider/user_request.rb", "lib/oauth_provider/version.rb", "lib/oauth_provider.rb"]
  s.homepage = %q{http://github.com/halorgium/oauth_provider/tree/master}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{oauth_provider}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Oauth provider wrapper}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<oauth>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<oauth>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<oauth>, [">= 0"])
  end
end
