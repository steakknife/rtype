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

	def or(*others)
		::Rtype::or(self, *others)
	end

	def xor(*others)
		::Rtype::xor(self, *others)
	end
end