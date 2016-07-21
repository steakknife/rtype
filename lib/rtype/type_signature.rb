module Rtype
	class TypeSignature
		attr_accessor :argument_type, :return_type
		
		# @return [Hash] A type signature
		def info
			{argument_type => return_type}
		end
	end
end
