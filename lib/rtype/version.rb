module Rtype
	VERSION = "0.6.4".freeze
	# rtype java extension version. nil If the extension is not used
	JAVA_EXT_VERSION = nil unless defined?(JAVA_EXT_VERSION)
	# rtype c extension version. nil If the extension is not used
	NATIVE_EXT_VERSION = nil unless defined?(NATIVE_EXT_VERSION)
end
