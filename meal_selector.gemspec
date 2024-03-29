# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'meal_selector'
  spec.version       = '0.6.0'
  spec.authors       = ['Anthony Tilelli']
  spec.email         = ['Anthony@Tilelli.me']

  spec.summary       = 'Program help user look for and find meals.'
  spec.description   = 'Program queries the mealdb to search for meal by varous factors, such as name, ingredient and randomly.'
  spec.homepage      = 'https://github.com/Anthonyntilelli/MealSelector'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://www.rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/Anthonyntilelli/MealSelector'
    spec.metadata['changelog_uri'] = 'https://github.com/Anthonyntilelli/MealSelector'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dev
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rubocop', '~> 0.76.0'
  spec.add_development_dependency 'yard', '~> 0.9.20'
  # Runtime
  spec.add_runtime_dependency 'httparty', '~> 0.17.1'
  spec.add_runtime_dependency 'launchy', '>= 2.4.3'
end
