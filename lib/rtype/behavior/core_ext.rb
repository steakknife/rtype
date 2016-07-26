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

class Num
	# @param [Numeric] x
	# @return [Proc]
	def self.>(x)
		lambda { |obj| obj.is_a?(Numeric) && obj > x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.>=(x)
		lambda { |obj| obj.is_a?(Numeric) && obj >= x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<(x)
		lambda { |obj| obj.is_a?(Numeric) && obj < x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<=(x)
		lambda { |obj| obj.is_a?(Numeric) && obj <= x }
	end
	
	# @param [Numeric] x
	# @return [Proc]
	def self.==(x)
		lambda { |obj| obj.is_a?(Numeric) && obj == x }
	end
end

class Int
	# @param [Numeric] x
	# @return [Proc]
	def self.>(x)
		lambda { |obj| obj.is_a?(Integer) && obj > x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.>=(x)
		lambda { |obj| obj.is_a?(Integer) && obj >= x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<(x)
		lambda { |obj| obj.is_a?(Integer) && obj < x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<=(x)
		lambda { |obj| obj.is_a?(Integer) && obj <= x }
	end
	
	# @param [Numeric] x
	# @return [Proc]
	def self.==(x)
		lambda { |obj| obj.is_a?(Integer) && obj == x }
	end
end

class Flo
	# @param [Numeric] x
	# @return [Proc]
	def self.>(x)
		lambda { |obj| obj.is_a?(Float) && obj > x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.>=(x)
		lambda { |obj| obj.is_a?(Float) && obj >= x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<(x)
		lambda { |obj| obj.is_a?(Float) && obj < x }
	end

	# @param [Numeric] x
	# @return [Proc]
	def self.<=(x)
		lambda { |obj| obj.is_a?(Float) && obj <= x }
	end
	
	# @param [Numeric] x
	# @return [Proc]
	def self.==(x)
		lambda { |obj| obj.is_a?(Float) && obj == x }
	end
end
