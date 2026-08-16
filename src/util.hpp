#ifndef GODOTPD_UTIL_HPP
#define GODOTPD_UTIL_HPP

#include <godot_cpp/variant/string.hpp>
#include <string>

// Pd deals in UTF-8 byte strings; String(const char *) would decode latin-1
// and garble any non-ASCII symbol or print message, so decode explicitly.
inline godot::String godot_string_from(const std::string &from) {
	return godot::String::utf8(from.c_str());
}

inline std::string std_string_from(const godot::String &from) {
	return from.utf8().get_data();
}

#endif
