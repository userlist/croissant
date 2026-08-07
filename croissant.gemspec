# frozen_string_literal: true

require_relative 'lib/croissant/version'

Gem::Specification.new do |spec|
  spec.name = 'croissant'
  spec.version = Croissant::VERSION
  spec.authors = ['Benedikt Deicke']
  spec.email = ['benedikt@benediktdeicke.com']

  spec.summary = 'Modern processing pipeline for HTML emails'
  spec.description = 'A processing pipeline that parses HTML and CSS of emails to apply a series of transformations ' \
                     'to make them more compatible with various email clients.'
  spec.homepage = 'https://github.com/userlist/croissant/'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/userlist/croissant/'
  spec.metadata['changelog_uri'] = 'https://github.com/userlist/croissant/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/userlist/croissant/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
