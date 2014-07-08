# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_advanced_inventory'
  s.version     = '0.1'
  s.summary     = 'Additional inventory options and simple dropship capability'
  s.description = 'SpreeAdvancedInventory supports supplier lists, ordering stock from suppliers, receiving shipments to inventory and fulfilling orders via dropship from suppliers.'
  s.required_ruby_version = '>= 1.9.2'

  s.author    = 'Zach Karpinski'
  s.email     = 'zkarpinski@gmail.com'
  s.homepage  = 'http://zachkarpinski.com'

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.2.2'

  s.add_development_dependency 'capybara', '~> 1.1.2'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'factory_girl', '~> 2.6.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.9'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'sqlite3'
end
