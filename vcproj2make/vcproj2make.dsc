const nl = "\n";
const pref = " ****** ";
function foreacharg(args, f) {
	local args_start = args.start;
	local args_total = args.total;
	local args_end   = args_start + args_total;
	local cont       = true;
	for (local i = args_start; cont and i < args_end; ++i)
		cont = f(args[i]);
	assert( i == args_end );
	return i;
}
function println(...) { std::print(..., ::nl); }
function printlns(...) {
	::foreacharg(arguments,
			function(arg) {
				::println(arg);
				return true;
			}
	);
}
// work around linux compiler crash 
//function printsec(...) { std::print(pref, ..., ::nl); }
function printsec(...) { local nl = ::nl; std::print(pref, ..., nl); }
function platform {
	local result = nil;
	if (local platform = std::libfuncget("std::platform"))
		result = platform();
	else if (platform = std::libfuncget("isi::platform"))
		result = platform();
	else
		std::error("could not find a *::platform() libfunc");
	return result;
}
function iswin32  { return ::platform() == "win32"; }
function islinux  { return ::platform() == "linux"; }
function del(delegator, delegate) { std::delegate(delegator, delegate); }
function loadlibs {
	local xmldll = nil;
	if (::iswin32())
		xmldll = std::dllimport("XMLParser.dll", "Install");
	else if (::islinux())
		xmldll = std::dllimport("libXMLParser-linux.so", "Install");
	else		
		std::error("unknown platform: " + ::platform());
		
	if (not xmldll)
		std::error("could not load xml parser lib");
	return true;
}
//
function isdeltastring(val) { return std::typeof(val) == "String"; }
function isdeltaobject(val) { return std::typeof(val) == "Object"; }
function isdeltanumber(val) { return std::typeof(val) == "Number"; }
//
// "private field"
function pfield(field_name) {
	assert(::isdeltastring(field_name));
	return "$_" + field_name;
}
// "delta object", "field name"
// get and set locally (on object) private members
function dobj_get(dobj, fname) {
	return std::tabget(dobj, ::pfield(fname));
}
function dobj_set(dobj, fname, val) {
	return std::tabset(dobj, ::pfield(fname), val);
}
//
function dobj_contains(dobj, val) {
	local contains = false;
	local ite = std::tableiter_new();
	for (std::tableiter_setbegin(ite, dobj); not contains and not std::tableiter_checkend(ite, dobj); std::tableiter_fwd(ite))
		contains = std::tableiter_getval(ite) == val;
	return contains;
}
function dobj_contains_key(dobj, key) {
	return dobj[key] != nil;
}
function dobj_contains_any(dobj, dobj_other) {
	foreach (val, dobj_other)
		if (::dobj_contains(dobj, val))
			return true;
	return false;
}
function dobj_contains_any_key(dobj, keys) {
	return ::dobj_contains_any(std::tabindices(dobj), keys);
}
function dobj_contains_any_key_from(dobj, dobj_other) {
	return ::dobj_contains_any_key(dobj, std::tabindices(dobj_other));
}
//
function dobj_checked_set(dobj, validKeys, key, val) {
	assert( ::dobj_contains(validKeys, key) );
	return ::dobj_set(dobj, key, val);
}

///////////////////////// No-inheritance, delegation classes with mix-in support //////////////////////
function mixin_state(state, mixin) {
	local indices = std::tabindices(mixin);
	foreach (index, indices)
		if (std::tabget(state, index))
			std::error("mixing in overwrites existing state\nstate: " + state + "\nmixin: " + mixin);
		else
			std::tabset(state, index, std::tabget(mixin, index));
}
function stateFieldsClash(fields1, fields2) {
	return ::dobj_contains_any(fields1, fields2);
}
function prototypesClash(proto1, proto2) {
	return ::dobj_contains_any_key_from(proto1, proto2);
}
function mixinRequirementsFulfilled(prototype, requirements) {
	local requirementsFulfilled = true;
	local ite = std::tableiter_new();
	for (std::tableiter_setbegin(ite, requirements); requirementsFulfilled and not std::tableiter_checkend(ite, requirements); std::tableiter_fwd(ite))
		requirementsFulfilled = ::dobj_contains_key(prototype, std::tableiter_getval(ite));
	return requirementsFulfilled;
}
function mixin(newInstanceState, mixin_instance, mixin_prototype) {
	::mixin_state(newInstanceState, mixin_instance);
	std::delegate(newInstanceState, mixin_prototype);
}
// Class class utility (static) methods
//
// Class_checkedStateInitialisation(newObjectInstance, validFieldsNames, fields) 
// //    newObjectInstance: the new object instance whose state will be initialised
// //    validFieldsNames : a delta object with all the valid fields' names (in normal form)
// //    fields           : a delta object which maps field-names to values
function Class_checkedStateInitialisation(newObjectInstance, validFieldsNames, fields) {
	local number_of_fields = std::tablength(validFieldsNames);
	assert( std::tablength(fields) == number_of_fields );
	foreach (validFieldName, validFieldsNames) {
		local value = std::tabget(fields, validFieldName);
		assert( not std::isundefined(value) );
		assert( value != nil );
		::dobj_set(newObjectInstance, validFieldName, value);
	}
}
function Class_isa(obj, a_class) {
	return ::dobj_contains(obj.getClasses(), a_class);
}
// Object-class-elements
// for use in Class-class implementation (since it cannot use the Object class as a complete class)
// *** Object mixin
//     -----------------------
//     <^> createInstance( )
//     <^> Public methods
//         - getClasses()
//           returns a delta object containing references to all the classes
//           mixed-in into this object.
//         - addClass(class)
//           adds a class to the registery of classes mixed-in into this Object.`
//     <^> state fields
//         - classes : std::list
function Object_stateFields {
	return [ #classes ];
}
function Object_stateInitialiser {
	if (std::isundefined(static stateInitialiser))
		stateInitialiser = (function (newObjectInstance) {
			assert( ::isdeltaobject(newObjectInstance) );
			Class_checkedStateInitialisation(
				newObjectInstance,
				Object_stateFields(),
				[ { #classes: std::list_new() } ]
			);
		});
	return stateInitialiser;
}
function Object_prototype {
	if (std::isundefined(prototype))
		prototype = [
			method getClasses {
				local classes = ::dobj_get(self, #classes);
				local result = [];
				local i = 0;
				foreach (class, classes)
					result[i++] = class;
				return result;
			},
			method addClass(class) {
				local classes = ::dobj_get(self, #classes);
				std::list_push_back(classes, class);
			}
		];
	return prototype;
}
function Object_mixinRequirements {
	return [];
}
function mixinObject(newInstance, newInstanceStateFields, newInstancePrototype) {
	// manually mix-in the object class (by default)
	assert( not ::stateFieldsClash( Object_stateFields(), newInstanceStateFields ) );
	assert( not ::prototypesClash( Object_prototype(), newInstancePrototype ) );
	assert(     ::mixinRequirementsFulfilled(newInstancePrototype, Object_mixinRequirements()) );
	objectInstance = [];
	Object_stateInitialiser()(objectInstance);
	std::delegate(objectInstance, Object_prototype());
	::mixin(newInstance, objectInstance, Object_prototype());
}
//////////////////////////////
// *** Class class - hand made
//     -----------------------
//     <^> createInstance( stateInitialiser, prototype, mixInRequirements, stateFields, className )
//     <^> Public methods
//         - createInstance( ... )
//               stateInitialiser is called with arguments: the new object's state, a delta object
//               with all the valid state member names
//               and whatever other arguments are passed to createInstance().
//         - mixInRequirements
//               returns a delta object which contains strings that denote public methods
//               which should exist in an object that is trying to mix in this class.
//               If there are no mix-in requiremens this method may return [] or nil.
//         - fulfillsRequirements(a_mixin)
//               This method returns true if its prototype implements fully the requirements
//               set by the provided mixin.
//         - stateFieldsClash(a_mixin)
//               Checks if this class' state fields (non-private-name-form) clash with the given
//               mixin's.
//         - prototypesClash(another_class)
//               Checks if this class' prototype and the given prototype have some common
//               members (public API methods).
//         - mixIn(anotherClass)
//               registers a class to be mixed in when a new object of this calss is
//               created. If the "anotherClass" cannot be mixed-in this one (due to
//               common state entries or not fulfilling requirements) nil is returned.
//               Otherwise, a "true" evaluating value is returned.
//         - getPrototype
//               returns this class' prototype for inspection and possible alteration.
//         - stateFields
//               returns a delta object with this class' state fields (not in their private-field-name form)
//         - get/setClassName
//               gets/sets this class' name
//     <^> state fields
//         - stateInitialiser
//         - prototype
//         - mixInRequirements
//         - stateFields
//         - mixInRegistry
//         - className
function Class {
	if (std::isundefined(static Class_prototype))
		Class_prototype = [
			// Public API
			method createInstance(...) {
				// Get the ingredients
				local stateInitialiser = ::dobj_get(self, #stateInitialiser);
				local prototype        = self.getPrototype();
				assert(std::iscallable(stateInitialiser));
				assert(::isdeltaobject(prototype));

				// New state
				newInstanceState = [];
				// initialise
				stateInitialiser(newInstanceState, self.stateFields(), ...);
				// Link to prototype
				std::delegate(newInstanceState, prototype);
				// new instance is initialised and linked to its original class,
				// so the class' API can be used after this point.
				////
				// manually mix-in the object class (by default)
				::mixinObject(newInstanceState, self.stateFields(), prototype);
				// no need to register the "object" class in the classes list. (we also cannot do it)
				//
				// now the new object is also an Object, we can register ourselves and mix-ins as its classes.
				newInstanceState.addClass(self);
				// perform mixins
				foreach (mixin_pair, ::dobj_get(self, #mixInRegistry)) {
					local mixin = mixin_pair.class;
					local createInstanceArguments = mixin_pair.args;
					local mixin_instance = mixin.createInstance(|createInstanceArguments|);
					assert( not ::stateFieldsClash( mixin.stateFields(), prototype.stateFields() ) );
					assert( not ::prototypesClash( mixin.getPrototype(), prototype.getPrototype() ) );
					assert(     ::mixinRequirementsFulfilled(prototype, mixin.mixInRequirements()) );
					::mixin(newInstanceState, mixin_instance, mixin);
					// now we CAN register the mixed-in class
					// since "newInstanceState" "is-an" Object (we manually mixed it in already)
					// and we have a reference to the mix-in class.
					newInstanceState.addClass(mixin);
				}
				return newInstanceState;
			},
			method mixInRequirements {
				return ::dobj_get(self, #mixInRequirements);
			},
			method fulfillsRequirements(a_mixin) {
				assert( ::Class_isa(a_mixin, self) ); // assert tha a_mixin is a class
				local mixInRequirements = a_mixin.mixInRequirements();
				local myPrototype = self.getPrototype();
				return ::mixinRequirementsFulfilled(myPrototype, mixInRequirements);
			},
			method stateFieldsClash(another_class) {
				return ::stateFieldsClash(another_class.stateFields(), self.stateFields());
			},
			method prototypesClash(another_class) {
				return ::prototypesClash(self.getPrototype(), another_class.getPrototype());
			},
			method mixIn(another_class, createInstanceArguments) {
				// assert that given class is a class indeed
				assert( ::Class_isa(another_class, self) );
				// Make sure that we fulfil the requirements to mix in the other_class
				// and that the another_class' state does not interfer with ours
				if (self.fulfillsRequirements(another_class.mixInRequirements()) and not self.stateFieldsClash(another_class)) {
					local mixInRegistry = ::dobj_get(self, #mixInRegistry);
					std::list_push_back(mixInRegistry, [@class:another_class,@args:createInstanceArguments]);
				}
			},
			method getPrototype {
				return ::dobj_get(self, #prototype);
			},
			method stateFields {
				return std::tabcopy(::dobj_get(self, #stateFields));
			},
			method getClassName {
				local result = ::dobj_get(self, #className);
				assert( ::isdeltastring(result) );
				return result;
			},
			method setClassName(className) {
				return ::dobj_checked_set(self, self.stateFields(), #className, className);
			}
		];
	if (std::isundefined(static Class_stateFields))
		Class_stateFields = [#stateInitialiser, #prototype, #mixInRequirements, #stateFields, #mixInRegistry, #className];
	function Class_stateInitialiser(newClassInstance, validStateFieldsNames, stateInitialiser, prototype, mixInRequirements, stateFields, className) {
		assert( std::iscallable(stateInitialiser) );
		assert( ::isdeltaobject(prototype) );
		assert( ::isdeltaobject(mixInRequirements) );
		assert( ::isdeltaobject(stateFields) );
		Class_checkedStateInitialisation(
			newClassInstance,
			validStateFieldsNames,
			[ 
				{ #stateInitialiser : stateInitialiser  },
				{ #prototype        : prototype         },
				{ #mixInRequirements: mixInRequirements },
				{ #stateFields      : stateFields       },
				{ #mixInRegistry    : std::list_new()   },
				{ #className        : className         }
			]
		);
		// Add custom delta-object overloadings
		// TODO check bug
		// work around
//		tostring_method = (method {
//			return "class " + self.getclassname();
//		});
//		newclassinstance."tostring()" = std::tabmethodonme(newclassinstance, tostring_method);
		// original
		newClassInstance."tostring()" = std::tabmethodonme(newClassInstance, method {
			return "Class " + self.getClassName();
		});
	}
	if (std::isundefined(static Class_state)) {
		Class_state = [];
		Class_stateInitialiser(Class_state, Class_stateFields, Class_stateInitialiser, Class_prototype, [], Class_stateFields, #Class);
		std::delegate(Class_state, Class_prototype);
		// mix-in object
		::mixinObject(Class_state, Class_stateFields, Class_prototype);
		// add "self" as this class' class.
		Class_state.addClass(Class_state);
	}
	return Class_state;
}


Point_class = Class().createInstance(
	// state initialiser
	function (newPointInstance, validStateFieldsNames, x, y) {
		assert( ::isdeltanumber(x) );
		assert( ::isdeltanumber(y) );
		Class_checkedStateInitialisation(
			newPointInstance,
			validStateFieldsNames,
			[ { #x: x}, { #y: y} ]
		);
	},
	// prototype
	[
		method show { ::println("Point[", ::dobj_get(self, #x), ",", ::dobj_get(self, #y), "]"); }
	],
	// mixin requirements
	[],
	// state fields
	[#x, #y],
	// Class Name
	#Point
);

point = Point_class.createInstance(12, 45);

point.show();
::println(point.getClasses());


