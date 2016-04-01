module Rtype
	module Behavior
		class Or < Base
			def initialize(*types)
				@types = types
			end

			def valid?(value)
				@types.any? do |e|
					Rtype::valid? e, value
				end
			end

			def error_message(value)
				arr = @types.map { |e| Rtype::type_error_message(e, value) }
				arr.join "\nOR "
			end
		end
	end

	def or(*args)
		Behavior::Or[*args]
	end
end