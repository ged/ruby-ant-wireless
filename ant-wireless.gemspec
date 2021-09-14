# -*- encoding: utf-8 -*-
# stub: ant-wireless 0.2.0.pre.20210913230613 ruby lib
# stub: ext/ant_ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "ant-wireless".freeze
  s.version = "0.2.0.pre.20210913230613"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/ruby-ant-wireless", "changelog_uri" => "https://deveiate.org/code/ant-wireless/History_md.html", "documentation_uri" => "https://deveiate.org/code/ant-wireless", "homepage_uri" => "https://sr.ht/~ged/ruby-ant-wireless/", "source_uri" => "https://hg.sr.ht/~ged/ruby-ant-wireless" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.date = "2021-09-13"
  s.description = "A binding for the ANT ultra-low power wireless protocol via the Garmin USB ANT Stick. ANT can be used to send information wirelessly from one device to another device, in a robust and flexible manner.".freeze
  s.email = ["ged@FaerieMUD.org".freeze, "mahlon@martini.nu".freeze]
  s.extensions = ["ext/ant_ext/extconf.rb".freeze]
  s.files = ["History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "ext/ant_ext/ant_ext.c".freeze, "ext/ant_ext/ant_ext.h".freeze, "ext/ant_ext/antdefines.h".freeze, "ext/ant_ext/antmessage.h".freeze, "ext/ant_ext/build_version.h".freeze, "ext/ant_ext/callbacks.c".freeze, "ext/ant_ext/channel.c".freeze, "ext/ant_ext/defines.h".freeze, "ext/ant_ext/extconf.rb".freeze, "ext/ant_ext/message.c".freeze, "ext/ant_ext/types.h".freeze, "ext/ant_ext/version.h".freeze, "lib/ant-wireless.rb".freeze, "lib/ant.rb".freeze, "lib/ant/channel.rb".freeze, "lib/ant/channel/event_callbacks.rb".freeze, "lib/ant/message.rb".freeze, "lib/ant/mixins.rb".freeze, "lib/ant/response_callbacks.rb".freeze, "lib/ant/wireless.rb".freeze, "spec/ant_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://sr.ht/~ged/ruby-ant-wireless/".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A binding for the ANT ultra-low power wireless protocol via the Garmin USB ANT Stick.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.10"])
    s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
  else
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.10"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
  end
end
