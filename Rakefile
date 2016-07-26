require "rspec/core/rake_task"

# Default pattern is 'spec/**{,/*/**}/*_spec.rb'
RSpec::Core::RakeTask.new(:spec)

if RUBY_ENGINE == "ruby"
	begin
		require "rake/extensiontask"
		Rake::ExtensionTask.new('rtype_native')
	rescue LoadError
		# No C native extension
	end
end

task :default => :spec

# Benchmark
desc "Compare with pure ruby and other gems"
task :benchmark do
  ruby "benchmark/benchmark.rb"
end
