module Rtype
	module Behavior
		class Not < Base
			def initialize(*types)
				@types = types
			end

			def valid?(value)
				@types.all? do |e|
					!Rtype::valid?(e, value)
				end
			end

			def error_message(value)
				arr = @types.map { |e| "NOT " + Rtype::type_error_message(e, value) }
				arr.join "\nAND "
			end
		end
	end

	def self.not(*args)
		Behavior::Not[*args]
	end
end