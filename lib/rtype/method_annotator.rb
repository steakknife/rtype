module Rtype
	module MethodAnnotator
		def self.included(base)
			base.extend ClassMethods
		end

		module ClassMethods
			def method_added(name)
				if @_rtype_proxy
					proxy = _rtype_proxy
					if proxy.annotation_mode
						::Rtype::define_typed_method(self, name, proxy.annotation_type_sig)
						proxy.annotation_mode = false
						proxy.annotation_type_sig = nil
					end
				end
			end

			def singleton_method_added(name)
				if @_rtype_proxy
					proxy = _rtype_proxy
					if proxy.annotation_mode
						::Rtype::define_typed_method(singleton_class, name, proxy.annotation_type_sig)
						proxy.annotation_mode = false
						proxy.annotation_type_sig = nil
					end
				end
			end
		end
	end
end