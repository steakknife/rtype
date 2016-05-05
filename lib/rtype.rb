if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
	begin
		require 'java'
		require 'rtype/rtype_java'
		puts "Rtype with Java extension"
	rescue LoadError
		puts "Rtype without native extension"
	end
else
	begin
		require "rtype/rtype_native"
		puts "Rtype with C native extension"
	rescue LoadError
		puts "Rtype without native extension"
	end
end

require_relative 'rtype/rtype_proxy'
require_relative 'rtype/method_annotator'
require_relative 'rtype/core_ext'
require_relative 'rtype/version'
require_relative 'rtype/type_signature_error'
require_relative 'rtype/argument_type_error'
require_relative 'rtype/return_type_error'
require_relative 'rtype/type_signature'
require_relative 'rtype/behavior'

module Rtype
	extend self

	# This is just the 'information'
	# Any change of this doesn't affect type checking
	@@type_signatures = Hash.new

	def define_typed_method(owner, method_name, type_sig_info)
		method_name = method_name.to_sym
		raise ArgumentError, "method_name is nil" if method_name.nil?
		assert_valid_type_sig(type_sig_info)

		el = type_sig_info.first
		arg_sig = el[0]
		return_sig = el[1]

		if arg_sig.is_a?(Array)
			expected_args = arg_sig.dup
			if expected_args.last.is_a?(Hash)
				expected_kwargs = expected_args.pop
			else
				expected_kwargs = {}
			end
		elsif arg_sig.is_a?(Hash)
			expected_args = []
			expected_kwargs = arg_sig
		end

		sig = TypeSignature.new
		sig.argument_type = arg_sig
		sig.return_type = return_sig
		unless @@type_signatures.key?(owner)
			@@type_signatures[owner] = {}
		end
		@@type_signatures[owner][method_name] = sig

		define_typed_method_to_proxy(owner, method_name, expected_args, expected_kwargs, return_sig)
	end

	def define_typed_accessor(owner, accessor_name, type_behavior)
		getter = accessor_name.to_sym
		setter = :"#{accessor_name}="
		valid?(type_behavior, nil)
		define_typed_method owner, getter, [] => type_behavior
		define_typed_method owner, setter, [type_behavior] => Any
	end

	def type_signatures
		@@type_signatures
	end

=begin
	def assert_keyword_arguments_type(expected_kwargs, kwargs)
		kwargs.each do |key, value|
			expected = expected_kwargs[key]
			unless expected.nil?
				unless valid?(expected, value)
					raise ArgumentTypeError, "for '#{key}' argument:\n" + type_error_message(expected, value)
				end
			end
		end
	end
=end

	def arg_type_error_message(idx, expected, value)
		"#{arg_message(idx)}\n" + type_error_message(expected, value)
	end

	def kwarg_type_error_message(key, expected, value)
		"#{kwarg_message(key)}\n" + type_error_message(expected, value)
	end

	def arg_message(idx)
		"for #{ordinalize_number(idx+1)} argument:"
	end

	def kwarg_message(key)
		"for '#{key}' argument:"
	end

	def type_error_message(expected, value)
		case expected
		when Rtype::Behavior::Base
			expected.error_message(value)
		when Module
			"Expected #{value.inspect} to be a #{expected}"
		when Symbol
			"Expected #{value.inspect} to respond to :#{expected}"
		when Regexp
			"Expected stringified #{value.inspect} to match regexp #{expected.inspect}"
		when Range
			"Expected #{value.inspect} to be included in range #{expected.inspect}"
		when Array
			arr = expected.map { |e| type_error_message(e, value) }
			arr.join("\nOR ")
		when Hash
			if value.is_a?(Hash)
				arr = []
				expected.each do |k, v|
					if v.is_a?(Array) || v.is_a?(Hash)
						arr << "- #{k} : {\n" + type_error_message(v, value[k]) + "\n}"
					else
						arr << "- #{k} : " + type_error_message(v, value[k])
					end
				end
				"Expected #{value.inspect} to be an hash with #{expected.length} elements:\n" + arr.join("\n")
			else
				"Expected #{value.inspect} to be an hash"
			end
		when Proc
			"Expected #{value.inspect} to return a truthy value for proc #{expected}"
		when true
			"Expected #{value.inspect} to be a truthy value"
		when false
			"Expected #{value.inspect} to be a falsy value"
		when nil # for return
			"Expected #{value.inspect} to be nil"
		end
	end

	def assert_valid_type_sig(sig)
		unless sig.is_a?(Hash)
			raise TypeSignatureError, "Invalid type signature: type signature is not hash"
		end
		if sig.empty?
			raise TypeSignatureError, "Invalid type signature: type signature is empty hash"
		end
		assert_valid_arguments_type_sig(sig.first[0])
		assert_valid_return_type_sig(sig.first[1])
	end

	def assert_valid_arguments_type_sig(sig)
		if sig.is_a?(Array)
			sig = sig.dup
			if sig.last.is_a?(Hash)
				kwargs = sig.pop
			else
				kwargs = {}
			end
			sig.each { |e| assert_valid_argument_type_sig_element(e) }
			if kwargs.keys.any? { |e| !e.is_a?(Symbol) }
				raise TypeSignatureError, "Invalid type signature: keyword arguments contain non-symbol key"
			end
			kwargs.each_value { |e| assert_valid_argument_type_sig_element(e) }
		elsif sig.is_a?(Hash)
			if sig.keys.any? { |e| !e.is_a?(Symbol) }
				raise TypeSignatureError, "Invalid type signature: keyword arguments contain non-symbol key"
			end
			sig.each_value { |e| assert_valid_argument_type_sig_element(e) }
		else
			raise TypeSignatureError, "Invalid type signature: arguments type signature is neither array nor hash"
		end
	end

	def assert_valid_argument_type_sig_element(sig)
		case sig
		when Rtype::Behavior::Base
		when Module
		when Symbol
		when Regexp
		when Range
		when Array
			sig.each do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Hash
			sig.each_value do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Proc
		when true
		when false
		when nil
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{sig}"
		end
	end

	def assert_valid_return_type_sig(sig)
		assert_valid_argument_type_sig_element(sig)
	end

private
	def define_typed_method_to_proxy(owner, method_name, expected_args, expected_kwargs, return_sig)
		# `send` is faster than `method(...).call`
		owner.send(:_rtype_proxy).send :define_method, method_name do |*args, **kwargs, &block|
			if kwargs.empty?
				::Rtype::assert_arguments_type(expected_args, args)
				result = super(*args, &block)
			else
				::Rtype::assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
				result = super(*args, **kwargs, &block)
			end
			::Rtype::assert_return_type(return_sig, result)
			result
		end
		nil
	end
	
	def ordinalize_number(num)
	    if (11..13).include?(num % 100)
			"#{num}th"
	    else
			case num % 10
			when 1; "#{num}st"
			when 2; "#{num}nd"
			when 3; "#{num}rd"
			else "#{num}th"
			end
	    end
	end
public
	unless respond_to?(:valid?)
	# validate argument type
	def valid?(expected, value)
		case expected
		when Module
			value.is_a? expected
		when Symbol
			value.respond_to? expected
		when Regexp
			!!(expected =~ value.to_s)
		when Range
			expected.include?(value)
		when Hash
			return false unless value.is_a?(Hash)
			return false unless expected.keys == value.keys
			expected.all? { |k, v| valid?(v, value[k]) }
		when Array
			expected.any? { |e| valid?(e, value) }
		when Proc
			!!expected.call(value)
		when true
			!!value
		when false
			!value
		when Rtype::Behavior::Base
			expected.valid? value
		when nil
			value.nil?
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{expected}"
		end
	end
	end

	unless respond_to?(:assert_arguments_type)
	def assert_arguments_type(expected_args, args)
		e_len = expected_args.length
		# `length.times` is faster than `each_with_index`
		args.length.times do |i|
			break if i >= e_len
			expected = expected_args[i]
			value = args[i]
			unless valid?(expected, value)
				raise ArgumentTypeError, "#{arg_message(i)}\n" + type_error_message(expected, value)
			end
		end
	end
	end

	unless respond_to?(:assert_arguments_type_with_keywords)
	def assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
		e_len = expected_args.length
		# `length.times` is faster than `each_with_index`
		args.length.times do |i|
			break if i >= e_len
			expected = expected_args[i]
			value = args[i]
			unless valid?(expected, value)
				raise ArgumentTypeError, "#{arg_message(i)}\n" + type_error_message(expected, value)
			end
		end
		
		kwargs.each do |key, value|
			if expected_kwargs.key?(key)
				expected = expected_kwargs[key]
				unless valid?(expected, value)
					raise ArgumentTypeError, "#{kwarg_message(key)}\n" + type_error_message(expected, value)
				end
			end
		end
	end
	end

	unless respond_to?(:assert_return_type)
	def assert_return_type(expected, result)
		unless valid?(expected, result)
			raise ReturnTypeError, "for return:\n" + type_error_message(expected, result)
		end
	end
	end
end
