# true or false
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

	# Makes the method typed
	# 
	# With 'annotation mode', this method works for both instance method and singleton method (class method).
	# Without it (specifying method name), this method only works for instance method.
	# 
	# @param [#to_sym, nil] method_name The name of method. If nil, annotation mode works
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @note Annotation mode doesn't work in the outside of module
	# @raise [ArgumentError] If method_name is nil in the outside of module
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype(method_name=nil, type_sig_info)
		if is_a?(Module)
			if method_name.nil?
				::Rtype::assert_valid_type_sig(type_sig_info)
				_rtype_proxy.annotation_mode = true
				_rtype_proxy.annotation_type_sig = type_sig_info
				nil
			else
				::Rtype::define_typed_method(self, method_name, type_sig_info)
			end
		else
			if method_name.nil?
				raise ArgumentError, "Annotation mode doesn't work in the outside of module"
			else
				rtype_self(method_name, type_sig_info)
			end
		end
	end

	# Makes the singleton method (class method) typed
	# 
	# @param [#to_sym] method_name
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @raise [ArgumentError] If method_name is nil
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype_self(method_name, type_sig_info)
		::Rtype.define_typed_method(singleton_class, method_name, type_sig_info)
	end
	
	# Makes the accessor methods (getter and setter) typed
	# 
	# @param [Array<#to_sym>] accessor_names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If accessor_names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype
	def rtype_accessor(*accessor_names, type_behavior)
		accessor_names.each do |accessor_name|
			raise ArgumentError, "accessor_names contains nil" if accessor_name.nil?
			
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
		nil
	end
	
	# Makes the accessor methods (getter and setter) typed
	# 
	# @param [Array<#to_sym>] accessor_names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If accessor_names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_accessor_self(*accessor_names, type_behavior)
		accessor_names.each do |accessor_name|
			raise ArgumentError, "accessor_names contains nil" if accessor_name.nil?
			
			accessor_name = accessor_name.to_sym
			if !respond_to?(accessor_name) || !respond_to?(:"#{accessor_name}=")
				singleton_class.send(:attr_accessor, accessor_name)
			end
			::Rtype::define_typed_accessor(singleton_class, accessor_name, type_behavior)
		end
		nil
	end
end

class Method
	# @return [Boolean] Whether the method is typed with rtype
	def typed?
		!!::Rtype.type_signatures[owner][name]
	end

	# @return [TypeSignature]
	def type_signature
		::Rtype.type_signatures[owner][name]
	end

	# @return [Hash]
	# @see TypeSignature#info
	def type_info
		::Rtype.type_signatures[owner][name].info
	end
	
	# @return [Array, Hash]
	def argument_type
		::Rtype.type_signatures[owner][name].argument_type
	end

	# @return A type behavior
	def return_type
		::Rtype.type_signatures[owner][name].return_type
	end
end
