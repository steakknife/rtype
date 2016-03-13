module Rtype
	module Behavior
		class Base
			def self.[](*vals)
				new(*vals)
			end

			def valid?(value)
				raise NotImplementedError, "Abstract method"
			end

			def error_message(value)
				raise NotImplementedError, "Abstract method"
			end
		end
	end
end