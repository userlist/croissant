# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'croissant', path: File.expand_path('../..', __dir__)

  gem 'benchmark-ips', require: 'benchmark/ips'
  gem 'memory_profiler'
  gem 'stackprof'
end

SELECTORS = [
  'main > article.post:not(.draft) h2 + p::first-line',
  'nav[aria-label="Main"] ul li:nth-child(2n+1) > a[href^="https://"]',
  '#content .card:has(> img.thumbnail) .card-title',
  'table.data tbody tr:nth-of-type(odd) td:last-child',
  'form input[type="text" i]:not([disabled], .readonly) ~ label',
  'section:is(.featured, #hero) .cta-button.primary[data-track]',
  'ul.menu > li.menu-item:first-child a::after',
  'custom-element::part(button)'
].freeze

def parse_all(selectors)
  parser = Croissant::Selector::Parser.new
  selectors.each { |selector| parser.parse(selector) }
end

SELECTORS.each do |selector|
  parsed = Croissant::Selector::Parser.parse(selector)
  raise "failed to parse: #{selector}" unless parsed

  puts "  #{parsed} (specificity: #{parsed.specificity.inspect})"
end

puts "\nSelectors: #{SELECTORS.size}\n\n"

puts "Single Run Memory Usage:\n\n"

report = MemoryProfiler.report { parse_all(SELECTORS) }
objects = report.total_allocated.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
memory = (report.total_allocated_memsize / 1024.0).round(1)

puts "  #{objects} objects #{memory} KB"

puts "\n\nIPS Benchmark:\n\n"

Benchmark.ips do |x|
  x.report('Selector::Parser') { parse_all(SELECTORS) }
end

%i[cpu wall].each do |mode|
  puts "\n\nSelector::Parser #{mode.to_s.upcase} profile:"

  profile = StackProf.run(mode:, interval: 100) { 50_000.times { parse_all(SELECTORS) } }
  StackProf::Report.new(profile).print_text
end
