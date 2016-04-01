module Rtype
	module Behavior
		class Nilable < Base
			def initialize(type)
				@type = type
			end

			def valid?(value)
				value.nil? || Rtype::valid?(@type, value)
			end

			def error_message(value)
				Rtype::type_error_message(@type, value) + "\nOR " + Rtype::type_error_message(nil, value)
			end
		end
	end

	def nilable(*args)
		Behavior::Nilable[*args]
	end
end