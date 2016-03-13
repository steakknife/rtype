module Rtype
	module Behavior
		class Xor < Base
			def initialize(*types)
				@types = types
			end

			def valid?(value)
				result = @types.map do |e|
					Rtype::valid? e, value
				end
				result.count(true) == 1
			end

			def error_message(value)
				arr = @types.map { |e| Rtype::type_error_message(e, value) }
				arr.join "\nXOR "
			end
		end
	end

	def self.xor(*args)
		Behavior::Xor[*args]
	end
end