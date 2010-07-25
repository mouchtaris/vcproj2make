function False {
	return false;
}

function typeof(arg) {
	return std::typeof(arg);
}

function inspect(arg) {
	return "[" + ::typeof(arg) + "]{" + arg + "}";
}

// printing/inspecting/debugging utils
const nl = "
";
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
function print(...) {
	::foreacharg(arguments,
			function(arg){
				std::print(arg);
				return true;
			}
	);
}
function println(...) { ::print(..., ::nl); }
function printlns(...) {
	::foreacharg(arguments,
			function(arg) {
				::println(arg);
				return true;
			}
	);
}
function p(...) {
	::foreacharg(arguments,
		function(arg) {
			::print(::inspect(arg));
			return true;
		}
	);
}
function ENDL { return ::nl; }
function val(const_or_f) {
	if (std::iscallable(const_or_f))
		return const_or_f();
	else
		return const_or_f;
}

function printsec(...) { std::print(pref, ..., ::nl); }
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
// Functional games
function constantf(val) {
	return [ method @operator () { return @val; }, { #val: val } ];
}

// type games
function isdeltastring(val) { return ::typeof(val) == "String"; }
function isdeltaobject(val) { return ::typeof(val) == "Object"; }
function isdeltanumber(val) { return ::typeof(val) == "Number"; }
function isdeltaboolean(val){ return ::typeof(val) == "Bool"  ; }
function isdeltanil   (val) { return ::typeof(val) == "Nil"   ; }
function isdeltaundefined(val){return std::isundefined(val)   ; }
function isdeltacallable(va){ return std::iscallable(va)      ; }
function toboolean    (val) { if (val) return true; else return false; }
//
// assertion utils
function assert_notnil(val) {
	assert( not ::isdeltanil(val) );
}
function assert_notundef(val) {
	assert( not ::isdeltaundefined(val) );
}
function assert_str(val) {
	assert( ::isdeltastring(val) );
}
function assert_num(val) {
	assert( ::isdeltanumber(val) );
}
function assert_obj(val) {
	assert( ::isdeltaobject(val) );
}
function assert_eq(val1, val2) {
	assert( val1 == val2 );
}
function assert_ge(val1, val2) {
	assert( val1 >= val2 );
}
function assert_or(cond1, cond2) {
	assert( cond1 or cond2 );
}
function assert_gt_or_eq(val1, val2, val3, val4) {
	assert( val1 > val2 or val3 == val4 );
}
function assert_ge_or_eq(val1, val2, val3, val4) {
	assert( val1 >= val2 or val3 == val4 );
}
function assert_fail {
	assert( not "Assertion-failure requested" );
}
//
// "private field"
function pfield(field_name) {
	::assert_str(field_name);
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
	foreach (local val, dobj_other)
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
function dobj_checked_get(dobj, key) {
	local result = ::dobj_get(dobj, key);
	::assert_notnil(result);
	return result;
}
//
// Utilities for iterables
function iterable_contains(iterable, value) {
	foreach (local val, iterable)
		if (val == value)
			return true;
	return false;
}
function list_contains(iterable, value) {
	return ::iterable_contains(iterable, value);
}

function iterable_to_deltaobject(iterable) {
	local i = 0;
	local result = [];
	foreach (local something, iterable)
		result[i++] = something;
	return result;
}
function list_to_deltaobject(list) {
	return ::iterable_to_deltaobject(list);
}

function list_clone(iterable) {
	local result = std::list_new();
	foreach (local something, iterable)
		result.push_back(something);
	return result;
}

/// File utilities
function file_isreadable(filepath) {
	local fh = std::fileopen(filepath, "rt");
	local result = ::toboolean(fh);
	if (result)
		std::fileclose(fh);
	return result;
}
function file_isabsolutepath(filepath) {
	local result = nil;
	if (::islinux())
		result = std::strlen(filepath) > 0 and std::strchar(filepath, 0) == "/";
	else if (::iswin32())
		result = std::strlen(filepath) > 3 and std::strchar(filepath, 1) == ":" and std::strchar(filepath, 2) == "\\";
	return result;
}
function file_hidden(filename) {
	local result = nil;
	if (::iswin32())
		result = "_" + filename;
	else if (::islinux())
		result = "." + filename;
	return result;
}

/// delta strings utilities
function strslice(str, start_index, end_index) {
	local result = nil;
	if (start_index >= std::strlen(str))
		result = "";
	else if (start_index == end_index)
		result = std::strchar(str, start_index);
	else {
		::assert_gt_or_eq( end_index , start_index , end_index , 0 );
		result = std::strslice(str, start_index, end_index);
	}
	return result;
}
function strsubstr(str, start_index ...) {
	local result = nil;
	local end_index = nil;
	local length = nil;
	if (local arg3 = arguments[2]) {
		if ( not std::typeof(arg3) == "Number" )
			std::error("substring() expects length of type Number but " + arg3 + "(" + std::typeof(arg3) + ") given");
		length = arg3;
	}
	::assert_num(start_index);
	if ( start_index >= 0 ) {
		if (length) {
			::assert_num(length);
			::assert_ge( length , 0 );
			end_index = start_index + length;
		}
		else
			end_index = 0;
		::assert_ge_or_eq( end_index , start_index , end_index , 0 );
		result = ::strslice(str, start_index, end_index);
	}
	return result;
}
function strsub(string, pattern, replacement) {
	local result = string;
	local pattern_index = std::strsub(string, pattern);
	if (pattern_index >= 0) {
		::println("&&&strsub&&& looking for \"", pattern, "\" in \"", string, "\"");
		local initial_part = ::strslice(string, 0, pattern_index - 1);
		::assert_str(initial_part);
		local rest = ::strslice(string, pattern_index + std::strlen(pattern), 0);
		::assert_str(rest);
		result = initial_part + replacement + rest;
	}
	return result;
}
function strgsub(string, pattern, replacement) {
	::assert_str(pattern);
	if (pattern == "")
			return string;
	local string_to_check = string;
	local result = "";
	while ((local pattern_index = std::strsub(string_to_check, pattern)) >= 0) {
		local initial_part = nil;
		if (pattern_index == 0)
			initial_part = "";
		else
			initial_part = ::strslice(string_to_check, 0, pattern_index - 1);
		::assert_str(initial_part);
		string_to_check = ::strsubstr(string_to_check, pattern_index + std::strlen(pattern));
		::assert_str(string_to_check);

		result += initial_part + replacement;
	}
	return result + string_to_check;
}
function strrindex(hay, needle) {
	::assert_str(hay);
	::assert_str(needle);
	for (local i = std::strlen(hay); i >= 0 and std::strsub(::strsubstr(hay, i), needle) == -1; --i)
		;
	return i;
}
function strlength(str) {
	return std::strlen(str);
}
function strchar(str, charindex) {
	return std::strchar(str, charindex);
}

///////////////////////// No-inheritance, delegation classes with mix-in support //////////////////////
function mixin_state(state, mixin) {
	local indices = std::tabindices(mixin);
	foreach (local index, indices)
		if (std::tabget(state, index))
			std::error("mixing in overwrites existing state" + ::nl + "state: " + state + ::nl + "mixin: " + mixin);
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
	foreach (local objectClass, object.getClasses())
		if (::stateFieldsClash(objectClass.stateFields(), newMixInStateFields))
			return true;
	return false;
}
function prototypesClashForAnyMixIn(object, newMixInPrototype) {
	foreach (local objectClass, object.getClasses())
		if (::prototypesClash(objectClass.getPrototype(), newMixInPrototype))
			return true;
	return false;
}
function mixinRequirementsFulfilledByAnyMixIn(object, newMixInRequirements) {
	foreach (local objectClass, object.getClasses())
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
function Class_checkedStateInitialisation(newObjectInstance, validFieldsNames, fields) {
	local number_of_fields = std::tablength(validFieldsNames);
	::assert_eq( std::tablength(fields), number_of_fields );
	foreach (local validFieldName, validFieldsNames) {
		local value = std::tabget(fields, validFieldName);
		::assert_notundef( value );
		::assert_notnil( value );
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
function Object_stateFields {
	return [ #classes ];
}
function Object_stateInitialiser {
	if (std::isundefined(static stateInitialiser))
		stateInitialiser = (function (newObjectInstance) {
			::assert_obj( newObjectInstance );
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
				foreach (local class, classes)
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
	foreach (local field, objectValidStateFields)
		::dobj_set(instance, field, nil);
}

function Class {
	if (std::isundefined(static Class_prototype))
		Class_prototype = [
			// Public API
			method createInstance(...) {
				// Get the ingredients
				local stateInitialiser = ::dobj_get(self, #stateInitialiser);
				local prototype        = self.getPrototype();
				::assert_obj(prototype);
				local self_stateFields = self.stateFields();

				// New state
				newInstanceState = [];
				// initialise
				stateInitialiser(newInstanceState, self_stateFields, ...);
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
				foreach (local mixin_pair, ::dobj_get(self, #mixInRegistry)) {
					local mixin = mixin_pair.class;
					local createInstanceArgumentsFunctor = mixin_pair.args;
					local mixin_instance = mixin.createInstance(
							|createInstanceArgumentsFunctor(newInstanceState, self_stateFields, ...)|
					);
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
				foreach (local mixin_pair, ::dobj_get(self, #mixInRegistry))
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
							::assert_fail();
					else
						::assert_fail();
				else
					::assert_fail();
			},
			method getPrototype {
				return ::dobj_get(self, #prototype);
			},
			method stateFields {
				return std::tabcopy(::dobj_get(self, #stateFields));
			},
			method getClassName {
				local result = ::dobj_get(self, #className);
				::assert_str( result );
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
		::assert_obj( prototype );
		::assert_obj( mixInRequirements );
		::assert_obj( stateFields );
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



function TESTING_THE_CLASS_MODEL {
///////////// TESTING THE CLASS MODEL /////////////
// Class printable
function Printable() {
	if (std::isundefined(static Printable_class))
		Printable_class = ::Class().createInstance(
			// stateInitialiser
			function Printable_stateInitialiser(newPointInstance, validStateFieldsNames, prefix) {
				::assert_eq( std::tablength(validStateFieldsNames), 0 );
				if (prefix)
					::dobj_set(newPointInstance, #prefix, prefix);
			},
			// prototype
			[
				method print {
					local prefix = ::dobj_get(self, #prefix);
					::println(prefix, self.tostring());
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
				::assert_eq( std::tablength(validStateFieldsNames) , 0 );
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
// Class Point
function Point {
	Point_class_mixin_failure =
	//		"state clash"
	//		"proto clash"
	//		"requirement fail"
			nil
	;
	if (std::isundefined(static Point_class)) {
		Point_class = ::Class().createInstance(
			// stateInitialiser
			function Point_stateInitialiser(newPointInstance, validStateFieldsNames, x, y, printPrefix) {
				::assert_num( x );
				::assert_num( y );
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
		Point_class.mixIn(Printable(), [
			method @operator ()(newInstance, validStateFieldsNames, x, y, printPrefix) {
				::assert_eq( newInstance.getX(), x );
				::assert_eq( newInstance.getY(), y );
				::assert_str( printPrefix );
				return [printPrefix];
			}
		]);
		Point_class.mixIn(Serialisable(), ::constantf([]));
		// state clash
		if (Point_class_mixin_failure == "state clash")      Point_class.mixIn(Class().createInstance(function{},[            ],[         ],[#x],#Nothing), ::constantf([]));
		if (Point_class_mixin_failure == "proto clash")      Point_class.mixIn(Class().createInstance(function{},[{#getX:0}   ],[         ],[  ],#Nothing), ::constantf([]));
		if (Point_class_mixin_failure == "requirement fail") Point_class.mixIn(Class().createInstance(function{},[            ],[#Alalumpa],[  ],#Nothing), ::constantf([]));
	}
	return Point_class;
}

{
	local pclass = Point();
	local p = pclass.createInstance(3, 4, "Omphalus");
	p.serialise();
}

} // TESTING_THE_CLASS_MODEL




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////// VCPROJ 2 MAKE ////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Path {
	function isaPath(obj) {
		return ::Class_isa(obj, ::Path());
	}
	function fromPath(path) {
		local result = nil;
		if ( ::isdeltastring(path) )
			result = ::Path().createInstance(path, ::file_isabsolutepath(path));
		else if ( isaPath(path) )
			result = ::Path().createInstance(path.deltaString(), path.IsAbsolute());
		return result;
	}
	function castFromPath(path) {
		local result = nil;
		if ( ::isdeltastring(path) )
			result = fromPath(path);
		else if ( isaPath(path) )
			result = path;
		return result;
	}
	if (std::isundefined(static Path_class)) {
		Path_class = ::Class().createInstance(
			// stateInitialiser
			function Path_stateInitialiser(newPathInstance, validStateFieldsNames, path, isabsolute) {
				::assert_str( path );
				Class_checkedStateInitialisation(
					newPathInstance,
					validStateFieldsNames,
					[ { #Path_absolute: isabsolute }, { #Path_path: path } ]
				);
			},
			// prototype
			[
				method deltaString {
					local result = ::dobj_get(self, #Path_path);
					::assert_str( result );
					return result;
				},
				method IsAbsolute {
					local result = ::dobj_get(self, #Path_absolute);
					::assert_notnil( result );
					return result;
				},
				method IsRelative {
					return not self.IsAbsolute();
				},
				method Concatenate(another_relative_path) {
					local result = nil;
					if ( ::isdeltastring(another_relative_path) )
						result = self.Concatenate( fromPath(another_relative_path) );
					else {
						assert( isaPath(another_relative_path) );
						assert( another_relative_path.IsRelative() );
						result = fromPath(self.deltaString() + "/" + another_relative_path.deltaString());
					}
					return result;
				},
				method Extension {
					local path = ::dobj_get(self, #Path_path);
					::assert_str( path );
					local ext = ::strsubstr(path, ::strrindex(path, ".") + 1);
					::assert_str( ext );
					return ext;
				},
				method asWithExtension(newext) {
					::assert_str(newext);
					local pathstr = self.deltaString();
					local extindex = ::strrindex(pathstr, ".");
					pathstr = ::strsubstr(pathstr, 0, extindex);
					::assert_eq( extindex + 1 , ::strlength(pathstr) );
					::assert_eq( ::strchar(pathstr, ::strlength(pathstr) - 1), "." );
					::assert_eq( ::strsubstr(pathstr, extindex + 1), "" );
					pathstr = pathstr + newext;
					return ::Path().createInstance(pathstr, self.IsAbsolute());
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #Path_absolute, #Path_path ],
			// className
			#Path
		);
		Path_class.isaPath      = isaPath;
		Path_class.fromPath     = fromPath;
		Path_class.castFromPath = castFromPath;
	}
	return Path_class;
}
function Path_isaPath     (obj ) { return Path().isaPath     (obj ); }
function Path_fromPath    (path) { return Path().fromPath    (path); }
function Path_castFromPath(path) { return Path().castFromPath(path); }

function Locatable {
	if (std::isundefined(static Locatable_class))
		Locatable_class = Class().createInstance(
			// stateInitialiser
			function Locatable_stateInitialiser(newInstance, validStateFieldsNames, path) {
				local p = ::Path_fromPath(path);
				assert( p );
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[ { #Locatable_path: p } ]
				);
			},
			// prototype
			[
				method getLocation {
					local path = ::dobj_get(self, #Locatable_path);
					assert( ::Path_isaPath(path) );
					return path;
				},
				method setLocation(path) {
					local p = ::Path_fromPath(path);
					assert( p );
					return ::dobj_set(self, #Locatable_path, p);
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #Locatable_path ],
			// className
			#Locatable
		);
	return Locatable_class;
}


function Namable {
	if (std::isundefined(static Namable_class))
		Namable_class = ::Class().createInstance(
			// stateInitialiser
			function Namable_stateInitialiser(newInstance, validStateFieldsNames, name) {
				::assert_str( name );
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
					::assert_str( name );
					return name;
				},
				method setName(name) {
					::assert_str( name );
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
function ProjectType_isValid(type) {
	return
		   type == ::ProjectType_StaticLibrary
		or type == ::ProjectType_DynamicLibrary
		or type == ::ProjectType_Executable
		;
}
function ProjectType {
	if (std::isundefined(static projectTypeEnum))
		projectTypeEnum = [
			@StaticLibrary  : ::ProjectType_StaticLibrary,
			@DynamicLibrary : ::ProjectType_DynamicLibrary,
			@Executable     : ::ProjectType_Executable,
			@isValid        : ::ProjectType_isValid
		];
	return projectTypeEnum;
}

function CProject {
	if (std::isundefined(static CProject_class)) {
		CProject_class = ::Class().createInstance(
			// stateInitialiser
			function CProject_stateInitialiser(newInstance, validStateFieldsNames, projectType, path, projectName) {
				assert( ::ProjectType_isValid(projectType) );
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[
						{ #CProject_type                        : projectType     },
						{ #CProject_manifestationsConfigurations: []              },
						{ #CProject_sources                     : std::list_new() },
						{ #CProject_includes                    : std::list_new() },
						{ #CProject_subprojects                 : std::list_new() },
						{ #CProject_definitions                 : std::list_new() },
						{ #CProject_librariesPaths              : std::list_new() },
						{ #CProject_libraries                   : std::list_new() },
						{ #CProject_outputName                  : false           },
						{ #CProject_outputDirectory             : false           },
						{ #CProject_apidir                      : false           }
					]
				);
			},
			// prototype
			[
				method addSource(path) {
					local p = ::Path_castFromPath(path);
					assert( ::Path_isaPath(p) );
					::assert_eq( p.Extension(), self.SourceExtension() );
					::dobj_get(self, #CProject_sources).push_back(p);
				},
				method Sources {
					return ::list_clone(::dobj_get(self, #CProject_sources));
				},
				method addIncludeDirectory(path) {
					local p = ::Path_castFromPath(path);
					assert( ::Path_isaPath(p) );
					::dobj_get(self, #CProject_includes).push_back(p);
				},
				method IncludeDirectories {
					return ::list_clone(::dobj_get(self, #CProject_includes));
				},
				method addSubproject(project) {
					assert( ::Class_isa(project, ::CProject()) );
					::dobj_get(self, #CProject_subprojects).push_back(project);
				},
				method Subprojects {
					return ::list_clone(::dobj_get(self, #CProject_subprojects));
				},
				method addPreprocessorDefinition(definition) {
					::assert_str( definition );
					::dobj_get(self, #CProject_definitions).push_back(definition);
				},
				method PreprocessorDefinitions {
					return ::list_clone(::dobj_get(self, #CProject_definitions));
				},
				method addLibraryPath(path) {
					local p = ::Path_castFromPath(path);
					assert( ::Path_isaPath(p) );
					::dobj_get(self, #CProject_librariesPaths).push_back(p);
				},
				method LibrariesPaths {
					return ::list_clone(::dobj_get(self, #CProject_librariesPaths));
				},
				method addLibrary(path) {
					local p = ::Path_castFromPath(path);
					assert( ::Path_isaPath(p) );
					::dobj_get(self, #CProject_libraries).push_back(p);
				},
				method Libraries {
					return ::list_clone(::dobj_get(self, #CProject_libraries));
				},
				method setManifestationConfiguration(manifestationID, configuration) {
					::assert_str( manifestationID );
					local configs = ::dobj_get(self, #CProject_manifestationsConfigurations);
					::assert_obj( configs );
					configs[manifestationID] = configuration;
				},
				method getManifestationConfiguration(manifestationID) {
					::assert_str( manifestationID );
					local configs = ::dobj_get(self, #CProject_manifestationsConfigurations);
					::assert_obj( configs );
					local config = configs[manifestationID];
					::assert_notnil( config );
					return config;
				},
				method isStaticLibrary {
					local type = ::dobj_get(self, #CProject_type);
					assert( ::ProjectType_isValid(type));
					return type == ProjectType_StaticLibrary;
				},
				method isDynamicLibrary {
					local type = ::dobj_get(self, #CProject_type);
					assert( ::ProjectType_isValid(type));
					return type == ProjectType_DynamicLibrary;
				},
				method isExecutable {
					local type = ::dobj_get(self, #CProject_type);
					assert( ::ProjectType_isValid(type));
				},
				method isLibrary {
					return self.isDynamicLibrary() or self.isStaticLibrary();
				},
				method getOutputDirectory {
					local outputDirectory = ::dobj_get(self, #CProject_outputDirectory);
					assert( ::Path().isaPath(outputDirectory) );
					return outputDirectory;
				},
				method setOutputDirectory(pathable) {
					local path = ::Path().fromPath(pathable);
					assert( ::Path().isaPath(path) );
					::dobj_set(self, #CProject_outputDirectory, path);
				},
				method getOutputName {
					local name = ::dobj_get(self, #CProject_outputName);
					::assert_str( name );
					return name;
				},
				method setOutputName(name) {
					::assert_str( name );
					::dobj_checked_set(self, ::CProject().stateFields(), #CProject_outputName, name);
				},
				method setAPIDirectory(path) {
					local p = ::Path_fromPath(path);
					assert( ::Path_isaPath(p) );
					::dobj_set(self, #CProject_apidir, p);
				},
				method getAPIDirectory {
					local apidir = ::dobj_get(self, #CProject_apidir);
					assert( ::Path_isaPath(apidir) );
					return apidir;
				},
				method SourceExtension {
					return "cpp";
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #CProject_type, #CProject_manifestationsConfigurations, #CProject_sources, #CProject_includes,
			  #CProject_subprojects, #CProject_definitions, #CProject_librariesPaths, #CProject_libraries,
			  #CProject_outputDirectory, #CProject_outputName, #CProject_apidir],
			// className
			#CProject
		);
		CProject_class.mixIn(::Locatable(), [
			method @operator () (newInstance, validStateFieldsNames, projectType, path) {
				return [path];
			}
		]);
		CProject_class.mixIn(::Namable()  , [
			method @operator () (newInstance, validStateFieldsNames, projectType, path, projectName) {
				return [projectName];
			}
		]);
	}
	return CProject_class;
}
function CProject_isaCProject(obj) {
	return ::Class_isa(obj, ::CProject());
}

