module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end
Any = BasicObject

class Object
	include ::Rtype::MethodAnnotator
end

module Kernel
private
	def _rtype_proxy
		unless @_rtype_proxy
			@_rtype_proxy = ::Rtype::RtypeProxy.new
			prepend @_rtype_proxy
		end
		@_rtype_proxy
	end

	def rtype(method_name=nil, type_sig_info)
		if is_a?(Module)
			if method_name.nil?
				::Rtype::assert_valid_type_sig(type_sig_info)
				_rtype_proxy.annotation_mode = true
				_rtype_proxy.annotation_type_sig = type_sig_info
			else
				::Rtype::define_typed_method(self, method_name, type_sig_info)
			end
		else
			if method_name.nil?
				raise ArgumentError, "Annotation mode not working out of module"
			else
				rtype_self(method_name, type_sig_info)
			end
		end
	end

	def rtype_self(method_name, type_sig_info)
		::Rtype.define_typed_method(singleton_class, method_name, type_sig_info)
	end

	def rtype_accessor(accessor_name, type_behavior)
		accessor_name = accessor_name.to_sym
		if !respond_to?(accessor_name) || !respond_to?(:"#{accessor_name}=")
			attr_accessor accessor_name
		end

		if is_a?(Module)
			::Rtype::define_typed_accessor(self, accessor_name, type_behavior)
		else
			rtype_accessor_self(accessor_name, type_behavior)
		end
	end

	def rtype_accessor_self(accessor_name, type_behavior)
		accessor_name = accessor_name.to_sym
		if !respond_to?(accessor_name) || !respond_to?(:"#{accessor_name}=")
			singleton_class.send(:attr_accessor, accessor_name)
		end
		::Rtype::define_typed_accessor(singleton_class, accessor_name, type_behavior)
	end
end

class Method
	def typed?
		!!::Rtype.type_signatures[owner][name]
	end

	def type_signature
		::Rtype.type_signatures[owner][name]
	end

	def type_info
		::Rtype.type_signatures[owner][name].info
	end

	def argument_type
		::Rtype.type_signatures[owner][name].argument_type
	end

	def return_type
		::Rtype.type_signatures[owner][name].return_type
	end
end

class Array
	def comb
		::Rtype::Behavior::And[*self]
	end
end
