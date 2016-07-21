module Rtype
	module Behavior
		class TypedArray < Base
			def initialize(type_sig)
				@type_sig = type_sig
				Rtype.assert_valid_argument_type_sig_element(@type_sig)
			end

			def valid?(value)
				if value.is_a?(Array)
					any = value.any? do |e|
						!Rtype::valid?(@type_sig, e)
					end
					!any
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be a array with type #{@type_sig.inspect}"
			end
		end
	end
end
