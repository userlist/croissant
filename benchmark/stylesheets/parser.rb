# frozen_string_literal: true

require 'bundler/inline'
require 'objspace'

gemfile do
  source 'https://rubygems.org'

  gem 'croissant', path: File.expand_path('../..', __dir__)

  gem 'benchmark-ips', require: 'benchmark/ips'
  gem 'memory_profiler'
  gem 'stackprof'

  gem 'css_parser'
end

def parse_with_croissant(css)
  Croissant::Stylesheet::Parser.parse(css)
end

def parse_with_css_parser(css)
  parser = CssParser::Parser.new
  parser.add_block!(css)
  parser
end

css = File.read(File.expand_path('example.css', __dir__))

puts "CSS file size in memory: #{(ObjectSpace.memsize_of(css) / 1024.0).round(1)} KB\n\n"

tasks = {
  'CSS Parser' => -> { parse_with_css_parser(css) },
  'Croissant' => -> { parse_with_croissant(css) }
}

puts "Single Run Memory Usage:\n\n"

results = tasks.to_h { |name, task| [name, MemoryProfiler.report { task.call }] }
results.each do |name, report|
  objects = report.total_allocated.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse.rjust(12)
  memory = (report.total_allocated_memsize / 1024.0 / 1024.0).round(1).to_s.rjust(8)

  puts "  #{name.rjust(12)} #{objects} objects #{memory} MB"
end

puts "\n\nIPS Benchmark:\n\n"

Benchmark.ips do |x|
  tasks.each { |name, task| x.report(name, &task) }

  x.compare!
end

%i[cpu wall].each do |mode|
  tasks.each do |name, task|
    puts "\n\n#{name} #{mode.to_s.upcase} profile:"

    profile = StackProf.run(mode:, interval: 100) { 100.times { task.call } }
    StackProf::Report.new(profile).print_text
  end
end
