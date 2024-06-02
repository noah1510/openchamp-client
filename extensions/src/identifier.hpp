#pragma once

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class Identifier : public Object {
	GDCLASS(Identifier, Object)

private:
	String group;
	String name;

	bool valid = true;

protected:
	static void _bind_methods();

public:
	Identifier();
	Identifier(String _group, String _name);
	~Identifier();

	static Identifier from_string(String id_str){
		String _group = "openchamp";
    	String _name = id_str;

		int colon = id_str.find(":");
		if (colon != -1){
			_group = id_str.substr(0, colon);
			_name = id_str.substr(colon + 1);
		}

		return Identifier{_group, _name};
	}
};

} //namespace godot
