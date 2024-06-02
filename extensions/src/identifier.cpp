#include "identifier.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Identifier::_bind_methods() {
}

Identifier::Identifier() {
	valid = false;
}

Identifier::Identifier(String _group, String _name) {
	if (_group == ""){
		_group = "openchamp";
	
	}
        
    if (_name == "") {
		valid = false;
		return;
	}

    group = _group;
    name = _name;
}

Identifier::~Identifier() {}
