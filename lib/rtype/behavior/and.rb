module Rtype
	module Behavior
		class And < Base
			def initialize(*types)
				@types = types
			end

			def valid?(value)
				@types.all? do |e|
					Rtype::valid? e, value
				end
			end

			def error_message(value)
				arr = @types.map { |e| Rtype::type_error_message(e, value) }
				arr.join "\nAND "
			end
		end
	end

	def self.and(*args)
		Behavior::And[*args]
	end
end