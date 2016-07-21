class Object
	def and(*others)
		::Rtype::and(self, *others)
	end

	def nilable
		::Rtype::nilable(self)
	end
	alias_method :or_nil, :nilable

	def not
		::Rtype::not(self)
	end

	def xor(*others)
		::Rtype::xor(self, *others)
	end
end

class Array
	def self.of(type_sig)
		::Rtype::Behavior::TypedArray.new(type_sig)
	end
	
	def comb
		::Rtype::Behavior::And[*self]
	end
end
