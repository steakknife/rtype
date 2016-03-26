require 'benchmark/ips'

is_mri = RUBY_ENGINE == 'ruby'

require "rtype"
require "rubype" if is_mri
require "sig"
require "contracts"
require "contracts/version"
require "typecheck"

puts "Ruby version: #{RUBY_VERSION}"
puts "Ruby engine: #{RUBY_ENGINE}"
puts "Ruby description: #{RUBY_DESCRIPTION}"

puts "Rtype version: #{Rtype::VERSION}"
puts "Rubype version: #{Rubype::VERSION}" if is_mri
puts "Sig version: #{Sig::VERSION}"
puts "Contracts version: #{Contracts::VERSION}"
puts "Typecheck version: #{Typecheck::VERSION}"

class PureTest
	def sum(x, y)
		x + y
	end

	def mul(x, y)
		x * y
	end

	def args(a, b, c, d)
	end
end
pure_obj = PureTest.new

class RtypeTest
	rtype :sum, [Numeric, Numeric] => Numeric
	def sum(x, y)
		x + y
	end

	rtype :mul, [:to_i, :to_i] => Numeric
	def mul(x, y)
		x * y
	end

	rtype :args, [Integer, Numeric, String, :to_i] => Any
	def args(a, b, c, d)
	end
end
rtype_obj = RtypeTest.new

if is_mri
	class RubypeTest
		def sum(x, y)
			x + y
		end
		typesig :sum, [Numeric, Numeric] => Numeric

		def mul(x, y)
			x * y
		end
		typesig :mul, [:to_i, :to_i] => Numeric

		def args(a, b, c, d)
		end
		typesig :args, [Integer, Numeric, String, :to_i] => Any
	end
	rubype_obj = RubypeTest.new
end

class SigTest
	sig [Numeric, Numeric], Numeric,
	def sum(x, y)
		x + y
	end

	sig [:to_i, :to_i], Numeric,
	def mul(x, y)
		x * y
	end

	# nil means wildcard
	sig [Integer, Numeric, String, :to_i], nil,
	def args(a, b, c, d)
	end
end
sig_obj = SigTest.new

class ContractsTest
	include Contracts

	Contract Num, Num => Num
	def sum(x, y)
		x + y
	end

	Contract RespondTo[:to_i], RespondTo[:to_i] => Num
	def mul(x, y)
		x * y
	end

	Contract Int, Num, String, RespondTo[:to_i] => Any
	def args(a, b, c, d)
	end
end
contracts_obj = ContractsTest.new

class TypecheckTest
	extend Typecheck

	typecheck 'Numeric, Numeric -> Numeric',
	def sum(x, y)
		x + y
	end

	typecheck '#to_i, #to_i -> Numeric',
	def mul(x, y)
		x * y
	end

	typecheck 'Integer, Numeric, String, #to_i -> BasicObject',
	def args(a, b, c, d)
	end
end
typecheck_obj = TypecheckTest.new

Benchmark.ips do |x|
	x.report("pure") do |times|
		i = 0
		while i < times
			pure_obj.sum(1, 2)
			pure_obj.mul(1, 2)
			pure_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.report("rtype") do |times|
		i = 0
		while i < times
			rtype_obj.sum(1, 2)
			rtype_obj.mul(1, 2)
			rtype_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	if is_mri
		x.report("rubype") do |times|
			i = 0
			while i < times
				rubype_obj.sum(1, 2)
				rubype_obj.mul(1, 2)
				rubype_obj.args(1, 2, "c", 4)
				i += 1
			end
		end
	end
	
	x.report("sig") do |times|
		i = 0
		while i < times
			sig_obj.sum(1, 2)
			sig_obj.mul(1, 2)
			sig_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.report("contracts") do |times|
		i = 0
		while i < times
			contracts_obj.sum(1, 2)
			contracts_obj.mul(1, 2)
			contracts_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.report("typecheck") do |times|
		i = 0
		while i < times
			typecheck_obj.sum(1, 2)
			typecheck_obj.mul(1, 2)
			typecheck_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.compare!
end