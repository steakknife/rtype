module Rtype
	class TypeSignature
		attr_accessor :argument_type, :return_type

		def info
			{argument_type => return_type}
		end
	end
end