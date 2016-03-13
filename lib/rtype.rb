require_relative 'rtype/core_ext'
require_relative 'rtype/version'
require_relative 'rtype/type_signature_error'
require_relative 'rtype/argument_type_error'
require_relative 'rtype/return_type_error'
require_relative 'rtype/type_signature'
require_relative 'rtype/behavior'

module Rtype
	# This is just the 'information'
	# Any change of this doesn't affect type checking
	@@type_signatures = Hash.new({})

	class << self
		def define_typed_method(owner, method_name, type_sig_info)
			raise TypeSignatureError, "Invalid type signature" unless valid_type_sig_info_form?(type_sig_info)
			method_name = method_name.to_sym
			raise ArgumentError, "method_name is nil" if method_name.nil?

			el = type_sig_info.first
			arg_sig = el[0]
			return_sig = el[1]

			if arg_sig.is_a?(Array)
				expected_args = arg_sig
				if expected_args.last.is_a?(Hash)
					expected_kwargs = expected_args.pop
				else
					expected_kwargs = {}
				end
			elsif arg_sig.is_a?(Hash)
				expected_args = []
				expected_kwargs = arg_sig
			end

			expected_args.each { |e| valid?(e, nil) }
			if expected_kwargs.keys.any? { |e| !e.is_a?(Symbol) }
				raise TypeSignatureError, "Invalid type signature: keyword arguments contain non-symbol key"
			end
			expected_kwargs.each_value { |e| valid?(e, nil) }
			valid?(return_sig, nil) unless return_sig.nil?

			sig = TypeSignature.new
			sig.argument_type = arg_sig
			sig.return_type = return_sig
			@@type_signatures[owner][method_name] = sig

			# `send` is faster than `method(...).call`
			owner.send(:_rtype_proxy).send :define_method, method_name do |*args, **kwargs, &block|
				if kwargs.empty?
					::Rtype.assert_arguments_type(expected_args, args)
					result = super(*args, &block)
				else
					::Rtype.assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
					result = super(*args, **kwargs, &block)
				end
				::Rtype.assert_return_type(return_sig, result)
				result
			end
		end

		def define_typed_accessor(owner, accessor_name, type_behavior)
			getter = accessor_name.to_sym
			setter = :"#{accessor_name}="
			valid?(type_behavior, nil)
			define_typed_method owner, getter, [] => type_behavior
			define_typed_method owner, setter, [type_behavior] => Any
		end

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
			when Array
				return false unless value.is_a?(Array)
				return false unless expected.length == value.length
				idx = -1
				expected.all? { |e| idx += 1; valid?(e, value[idx]) }
			when Proc
				!!expected.call(value)
			when true
				!!value
			when false
				!value
			when Rtype::Behavior::Base
				expected.valid? value
			else
				raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{expected}"
			end
		end

		def type_signatures
			@@type_signatures
		end

		def assert_arguments_type(expected_args, args)
			# `length.times` is faster than `each_with_index`
			args.length.times do |i|
				expected = expected_args[i]
				value = args[i]
				unless expected.nil?
					unless valid?(expected, value)
						raise ArgumentTypeError, "for #{(idx+1).ordinalize} argument:\n" + type_error_message(expected, value)
					end
				end
			end
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
		def assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
			# `length.times` is faster than `each_with_index`
			args.length.times do |i|
				expected = expected_args[i]
				value = args[i]
				unless expected.nil?
					unless valid?(expected, value)
						raise ArgumentTypeError, "for #{(idx+1).ordinalize} argument:\n" + type_error_message(expected, value)
					end
				end
			end
			kwargs.each do |key, value|
				expected = expected_kwargs[key]
				unless expected.nil?
					unless valid?(expected, value)
						raise ArgumentTypeError, "for '#{key}' argument:\n" + type_error_message(expected, value)
					end
				end
			end
		end

		def assert_return_type(expected, result)
			if expected.nil?
				unless result.nil?
					raise ReturnTypeError, "for return:\n" + type_error_message(expected, result)
				end
			else
				unless valid?(expected, result)
					raise ReturnTypeError, "for return:\n" + type_error_message(expected, result)
				end
			end
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
				if value.is_a?(Array)
					arr = expected.map.with_index do |e, idx|
						if e.is_a?(Array)
							"- [#{idx}] index : {\n" + type_error_message(e, value[idx]) + "\n}"
						else
							"- [#{idx}] index : " + type_error_message(e, value[idx])
						end
					end
					"Expected #{value.inspect} to be an array with #{expected.length} elements:\n" + arr.join("\n")
				else
					"Expected #{value.inspect} to be an array"
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

	private
		def valid_type_sig_info_form?(hash)
			return false unless hash.is_a?(Hash)
			arg_sig = hash.first[0]
			arg_sig.is_a?(Array) || arg_sig.is_a?(Hash)
		end
	end
end