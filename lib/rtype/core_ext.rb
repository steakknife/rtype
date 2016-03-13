module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end
Any = BasicObject

module Kernel
private
	def _rtype_proxy
		unless @_rtype_proxy
			@_rtype_proxy = Module.new
			prepend @_rtype_proxy
		end
		@_rtype_proxy
	end

	def rtype(method_name, type_sig_info)
		if is_a?(Module)
			::Rtype::define_typed_method(self, method_name, type_sig_info)
		else
			rtype_self(method_name, type_sig_info)
		end
	end

	def rtype_self(method_name, type_sig_info)
		::Rtype.define_typed_method(singleton_class, method_name, type_sig_info)
	end

	def rtype_accessor(accessor_name, type_behavior)
		if is_a?(Module)
			::Rtype::define_typed_accessor(self, accessor_name, type_behavior)
		else
			rtype_accessor_self(accessor_name, type_behavior)
		end
	end

	def rtype_accessor_self(accessor_name, type_behavior)
		::Rtype::define_typed_accessor(singleton_class, accessor_name, type_behavior)
	end
end

class Method
	def type_signature
		::Rtype.type_signatures[owner][name]
	end

	def type_info
		type_signature.info
	end

	def argument_type
		type_signature.argument_type
	end

	def return_type
		type_signature.return_type
	end
end

class Fixnum
	def ordinalize
	    if (11..13).include?(self % 100)
			"#{self}th"
	    else
			case self % 10
			when 1; "#{self}st"
			when 2; "#{self}nd"
			when 3; "#{self}rd"
			else "#{self}th"
			end
	    end
	end
end