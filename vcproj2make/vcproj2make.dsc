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
//
// Utilities for iterables
function iterable_contains(iterable, value) {
	foreach (val, iterable)
		if (val == value)
			return true;
	return false;
}
function list_contains(iterable, value) {
	return ::iterable_contains(iterable, value);
}

function list_clone(iterable) {
	local result = std::list_new();
	foreach (something, iterable)
		result.push_back(something);
	return result;
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
function stateFieldsClashForAnyMixIn(object, newMixInStateFields) {
	foreach (objectClass, object.getClasses())
		if (::stateFieldsClash(objectClass.stateFields(), newMixInStateFields))
			return true;
	return false;
}
function prototypesClashForAnyMixIn(object, newMixInPrototype) {
	foreach (objectClass, object.getClasses())
		if (::prototypesClash(objectClass.getPrototype(), newMixInPrototype))
			return true;
	return false;
}
function mixinRequirementsFulfilledByAnyMixIn(object, newMixInRequirements) {
	foreach (objectClass, object.getClasses())
		if (::mixinRequirementsFulfilled(objectClass.getPrototype(), newMixInRequirements))
			return true;
	return false;
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
function Class_classRegistry {
	if (std::isundefined(static classRegistry) )
		classRegistry = [
			{ ::pfield(#list) : std::list_new() },
			method add(class) {
				assert( not ::list_contains(::dobj_get(self, #list), class) );
				::dobj_get(self, #list).push_back(class);
			}
		];
	return classRegistry;
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
function unmixinObject(instance) {
	local objectValidStateFields = Object_stateFields();
	foreach (field, objectValidStateFields)
		::dobj_set(instance, field, nil);
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
//         - mixIn(anotherClass, createInstanceArguments)
//               registers a class to be mixed in when a new object of this calss is
//               created. If the "anotherClass" cannot be mixed-in this one (due to
//               common state entries or not fulfilling requirements) nil is returned.
//               Otherwise, a "true" evaluating value is returned.
//               "createInstanceArguments" is a delta object with arguments passed
//               to the given class' "createInstance()" method in order to create an object
//               for merging with a new object of this class.
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
					// We can perform assertions concerning clashes, since _newInstanceState_ 
					// is a fully functioning object and classes can be registered as its mixins,
					// as well as be queried about what classes are mixed-into it.
					assert( not ::stateFieldsClashForAnyMixIn( newInstanceState, mixin.stateFields() ) );
					assert( not ::prototypesClashForAnyMixIn( newInstanceState, mixin.getPrototype()) );
					assert(     ::mixinRequirementsFulfilledByAnyMixIn(newInstanceState, mixin.mixInRequirements()) );
					// remove Object-state from the mixin_instance
					::unmixinObject(mixin_instance);
					::mixin(newInstanceState, mixin_instance, mixin.getPrototype());
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
				assert( ::Class_isa(a_mixin, Class()) ); // assert tha a_mixin is a class
				local myPrototype = self.getPrototype();
				local mixInRequirements = a_mixin.mixInRequirements();
				local mixInRegistry = ::dobj_get(self, #mixInRegistry);
				local req_ite = std::tableiter_new();
				local mixin_ite = std::listiter_new();
				local singleRequirement = [];
				local allFulfilled = true;
				for (std::tableiter_setbegin(req_ite, mixInRequirements); allFulfilled and not std::tableiter_checkend(req_ite, mixInRequirements); std::tableiter_fwd(req_ite)) {
					singleRequirement[0] = std::tableiter_getval(req_ite);
					allFulfilled = false;
					for (mixin_ite.setbegin(mixInRegistry); not allFulfilled and not mixin_ite.checkend(mixInRegistry); mixin_ite.fwd())
						allFulfilled = ::mixinRequirementsFulfilled( mixin_ite.getval().class.getPrototype(), singleRequirement);
					allFulfilled = allFulfilled or ::mixinRequirementsFulfilled(myPrototype, singleRequirement);
				}
				return allFulfilled;
			},
			method stateFieldsClash(another_class) {
				local another_class_stateFields = another_class.stateFields();
				foreach (mixin_pair, ::dobj_get(self, #mixInRegistry))
					if (::stateFieldsClash(another_class_stateFields, mixin_pair.class.stateFields()))
						return true;
				return ::stateFieldsClash(another_class_stateFields, self.stateFields());
			},
			method prototypesClash(another_class) {
				return ::prototypesClash(self.getPrototype(), another_class.getPrototype());
			},
			method mixIn(another_class, createInstanceArguments) {
				// assert that given class is a class indeed
				assert( ::Class_isa(another_class, ::Class()) );
				// Make sure that we fulfil the requirements to mix in the other_class
				// and that the another_class' state does not interfer with ours
				if (self.fulfillsRequirements(another_class))
					if (not self.stateFieldsClash(another_class))
						if (not self.prototypesClash(another_class)) {
							local mixInRegistry = ::dobj_get(self, #mixInRegistry);
							std::list_push_back(mixInRegistry, [@class:another_class,@args:createInstanceArguments]);
						}
						else
							assert(false);
					else
						assert(false);
				else
					assert(false);
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
			},
			//
			// Delta overloadings -- NOT related to API
			method @{
				return "Class " + self.getClassName();
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
		// TODO restore to original after bug has been fixed
		// original
//		newClassInstance."____SOMETHING___USELESS___" = std::tabmethodonme(newClassInstance, method {
//			return "Class " + self.getClassName();
//		});
		// work-around
		newClassInstance."____SOMETHING___USELESS___" = std::tabmethodonme(newClassInstance, [method {
			return "Class " + self.getClassName();
		}][0]);
		// TODO move this tostring() overloading to the Class class' prototype
		
		// Register class
		::Class_classRegistry().add(newClassInstance);
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



///////////// TESTING THE CLASS MODEL /////////////
// Class printable
function Printable() {
	if (std::isundefined(static Printable_class))
		Printable_class = ::Class().createInstance(
			// stateInitialiser
			function Printable_stateInitialiser(newPointInstance, validStateFieldsNames) {
				assert( std::tablength(validStateFieldsNames) == 0 );
			},
			// prototype
			[
				method print {
					::println(self.tostring());
				}
			],
			// mixInRequirements
			[ #tostring ],
			// stateFields
			[],
			// className
			#Printable
		);
	return Printable_class;
}

function Serialisable {
	if (std::isundefined(static Serialisable_class))
		Serialisable_class = ::Class().createInstance(
			// stateInitialiser
			function Serialisable_stateInitialiser(newInstance, validStateFieldsNames) {
				assert( std::tablength(validStateFieldsNames) == 0 );
			},
			// prototype
			[
				method serialise {
					self.print();
				}
			],
			// mixInRequirements
			[ #print ],
			// stateFields
			[],
			// className
			#Serialisable
		);
	return Serialisable_class;
}
Point_class_mixin_failure = 
//		"state clash"
//		"proto clash"
//		"requirement fail"
		nil
;
// Class Point
function Point {
	if (std::isundefined(static Point_class)) {
		Point_class = ::Class().createInstance(
			// stateInitialiser
			function Point_stateInitialiser(newPointInstance, validStateFieldsNames, x, y) {
				assert( ::isdeltanumber(x) );
				assert( ::isdeltanumber(y) );
				Class_checkedStateInitialisation(
					newPointInstance,
					validStateFieldsNames,
					[ { #x: x }, { #y: y } ]
				);
			},
			// prototype
			[
				method tostring {
					return "[" + self.getX() + "," + self.getY() + "]";
				},
				method getX {
					return ::dobj_get(self, #x);
				},
				method getY {
					return ::dobj_get(self, #y);
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #x, #y ],
			// className
			#Point
		);
		Point_class.mixIn(::Printable(), []);
		Point_class.mixIn(::Serialisable(), []);
		// state clash
		if (::Point_class_mixin_failure == "state clash")      Point_class.mixIn(Class().createInstance(function{},[],[],[#x],#Nothing), []);
		if (::Point_class_mixin_failure == "proto clash")      Point_class.mixIn(Class().createInstance(function{},[{#getX:0}],[],[],#Nothing), []);
		if (::Point_class_mixin_failure == "requirement fail") Point_class.mixIn(Class().createInstance(function{},[],[#Alalumpa],[],#Nothing), []);
	}
	return Point_class;
}

{
	pclass = Point();
	p = pclass.createInstance(3, 4);
	p.serialise();
}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////// VCPROJ 2 MAKE ////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////
// *** String class
//     Has a location on the file system.
//     -----------------------
//     <^> createInstance( val:string )
//     <^> Public methods
//         - deltaString
//               returns this String's value as a delta string
//         - String_clone
//               returns an identical new instance (deep copy)
//     <^> state fields
//         - String_deltaStringValue
//function String {
//	if (std::isundefined(static String_class))
//		String_class = Class().createInstance(
//			// stateInitialiser
//			function String_stateInitialiser(newInstance, validStateFieldsNames, val) {
//				assert( ::isdeltastring(val) );
//				Class_checkedStateInitialisation(
//					newInstance,
//					validStateFieldsNames,
//					[ { #String_deltaStringValue: val } ]
//				);
//			},
//			//prototype
//			[
//				method deltaString {
//					local result = ::dobj_get(self, #String_deltaStringValue);
//					assert( ::isdeltastring(result) );
//					return result;
//				},
//				method String_clone {
//					return String().createInstance(self.deltaString());
//				}
//			],
//			//mixInRequirements
//			[],
//			//stateFields
//			[ #String_deltaStringValue ],
//			//className
//			#String
//		);
//	return String_class;
//}
//function String_isaString(something) {
//	return ::Class_isa(something, String());
//}
//function String_fromString(val) {
//	local result = nil;
//	if ( ::isdeltastring(val) )
//		result = String().createInstance(val);
//	else if (String_isaString(val))
//		result = val.String_clone();
//	return result;
//}

//////////////////////////////
// *** Locatable class
//     Has a location on the file system.
//     -----------------------
//     <^> createInstance( location:deltastring )
//     <^> Public methods
//         - get/setLocation (location:deltastring)
//               gets/sets this locatable's location
//     <^> state fields
//         - location
function Locatable {
	if (std::isundefined(static Locatable_class))
		Locatable_class = Class().createInstance(
			// stateInitialiser
			function Locatable_stateInitialiser(newInstance, validStateFieldsNames, location) {
				assert( ::isdeltastring(location) );
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[ { #location: location } ]
				);
			},
			// prototype
			[
				method getLocation {
					local location = ::dobj_get(self, #location);
					assert( ::isdeltastring(location) );
					return location;
				},
				method setLocation(location) {
					assert( ::isdeltastring(location) );
					return ::dobj_set(self, #location, location);
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #location ],
			// className 
			#Locatable
		);
	return Locatable_class;
}

//////////////////////////////
// *** Namable class
//     A mix-in so that objects have names.
//     -----------------------
//     <^> createInstance( name:string )
//     <^> Public methods
//         - get/seName
//               gets/sets this object's name.
//     <^> state fields
//         - Namable_name
function Namable {
	if (std::isundefined(static Namable_class))
		Namable_class = ::Class().createInstance(
			// stateInitialiser
			function Namable_stateInitialiser(newInstance, validStateFieldsNames, name) {
				assert( ::isdeltastring(name) );
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[ { #Namable_name: name } ]
				);
			},
			// prototype
			[
				method getName {
					local name = ::dobj_get(self, #Namable_name);
					assert( ::isdeltastring(name) );
					return name;
				},
				method setName(name) {
					assert( ::isdeltastring(name) );
					return ::dobj_set(self, #Namable_name, name);
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #Namable_name ],
			// className
			#Namable
		);
	return Namable_class;
}

// ProjectType
const ProjectType_StaticLibrary  = 1;
const ProjectType_DynamicLibrary = 2;
const ProjectType_Executable     = 3;
//////////////////////////////
// *** CProject class
//       A programming project, containing source fileds, include directories, subprojects.
//     Subproject's location is interpreted as relative to this project's location.
//     The building order (for the various generated project files) is as follows:
//         - building every subproject, in order of addition to this project
//         - building this project
//       "Project manifestation" (or simply "manifestation") is the concept of this 
//     projet object manifesting as a series of files on the filesystem which
//     represent "project files" of a building system or another. Manifestations are
//     identified by string identifiers (for e.x., Makefile, VS, etc).
//       Each project object can hold an arbitrary object which represents
//     manifestation-specific extra options or configuration. These are understanble only by
//     the specific manifestation they refer to.
//       Subprojects referred to by this project are automtically added to this project's
//     dependencies according to the manifestation. They are also automatically included in
//     this project's building process, according to their type. Executable projects are generally
//     ignored in the building process (they are still built before this project though).
//     -----------------------
//     <^> createInstance( projectType:ProjectType )
//     <^> Mixs in: Locatable, Namable
//     <^> Public methods
//         - addSource(filepath:deltastring)
//               adds a source file to this project. The filepath is relative to
//               the project's location.
//         - Sources
//               returns an std::list with all the sources that belong to this project.
//         - addIncludeDirectory(filepath:deltastring)
//               adds an include path to this project. The filepath is relative to
//               the project's location.
//         - IndluceDirectories
//               returns an std::list with all the include directories of this project.
//         - addSubproject(subproject:Project)
//               adds a project as a subproject of this projet. The subproject's
//               paths is interpreted as relative to this project's path.
//         - Subprojects
//               return an std::list with the subprojects' objects' instances.
//         - addPreprocessorDefinition(def:deltastring)
//               adds a preprocessor definition to be defined in all compilation units
//               for this project.
//         - PreprocessorDefinitions
//               returns a delta object with all the extra preprocessor defnitions.
//         - addLibraryPath(filepath:deltastring)
//               adds a library-search path for this project's building.
//         - LibraryPaths
//               returns an std::list with the library search paths for this project's building.
//         - addLibrary(library_name:deltastring)
//               adds an extra library file name to be included in this project's building
//               process.
//         - Libraries
//               returns an std::list with all the extra libraries to be included in this project's
//               building process.
//         - setManifestationConfiguration(manifestation_id:deltasting, config:delta object)
//               sets the manifestation specific options for the given manifestation.
//               Any previous configuration added for this manifestation is overwritten.
//         - getManifestationConfiguration(manifestation_id:deltastring)
//               returns this project's configuration (delta) object for the given
//               manifestation.
//         - isStaticLibrary
//         - isDynamicLibrary
//         - isExecutable
//               return true if this project's type is StaticLibrary, DynamicLibrary or
//               Executable, respectively.
//         - set/getOutput (output_filepath:deltastring)
//               sets/gets this projects output filepath. When this is a library project,
//               this is the produced library file's filepath. When this is an executable
//               project, this will be the produced executable's filepath.
//     <^> state fields
//          1. CProject_type
//          2. CProject_manifestationsConfigurations
//          3. CProject_sources
//          4. CProject_includes
//          5. CProject_subprojects
//          6. CProject_definitions
//          7. CProject_librariesPaths
//          8. CProject_libraries
//          9. CProject_output
//         10. 



















































// TODO think about:
// - is delegator-reference a reason to stay alive (not be collected)? Does this happen?
//   (if delegators are not collected, then maybe manual reference counting has to be
//    implemented -- and the global assignment operatator overloading should be user)
// Bug-reports
// - When a function returns nothing, the error message is confusing
//   Illegal use of '::Locatable()' as an object (type is ').
{
	::println(::Locatable().createInstance("something").getLocation());
}

// Show all classes
{
	::println("----");
	local reg = ::dobj_get(Class_classRegistry(), #list);
	foreach (class, reg)
		::println(class);
	::println("----");
}

{
	::println("----");
	c = [method@{return #c;}];
	b = [method@{return #b;}];
	a=[];
	::println("A before delegation: ", a);
	std::delegate(a, b);
	::println("A delegated to b: ", a);
	std::undelegate(a, b);
	std::delegate(a, c);
	::println("A delegated to c: ", a);
	std::undelegate(a, c);
	std::delegate(a, b);
	std::delegate(a, c);
	::println("A delegated to b, c: ", a);
	std::undelegate(a, c);
	std::undelegate(a, b);
	std::delegate(a, c);
	std::delegate(a, b);
	::println("A delegated to c, b: ", a);
	::println("----");
}