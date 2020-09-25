
Gem::Specification.new do |s|

  s.name = 'rufus-lua'

  s.version = File.read(
    File.expand_path('../lib/rufus/lua/version.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux', 'Alain Hoang', 'Scott Persinger' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'https://github.com/jmettraux/rufus-lua'
  s.license = 'MIT'
  s.summary = 'ruby-ffi based bridge from Ruby to Lua'

  s.description = %{
ruby-ffi based bridge from Ruby to Lua
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_dependency 'ffi', '~> 1.9'

  s.add_development_dependency 'rspec', '>= 2.13.0'

  s.require_path = 'lib'
end

