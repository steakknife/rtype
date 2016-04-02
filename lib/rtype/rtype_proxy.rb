module Rtype
	class RtypeProxy < Module
		attr_accessor :annotation_mode
		attr_accessor :annotation_type_sig
		def initialize
			@annotation_mode = false
			@annotation_type_sig = nil
		end
	end
end