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
//
function isdeltastring(val) { return std::typeof(val) == "String"; }
function isdeltaobject(val) { return std::typeof(val) == "Object"; }
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

///////////////////////// No-inheritance, delegation classes with mix-in support //////////////////////
function mixin_state(state, mixin) {
	local indices = std::tabindices(mixin);
	foreach (index, indices)
		if (std::tabget(state, index))
			std::error("mixing in overwrites existing state\nstate: " + state + "\nmixin: " + mixin);
		else
			std::tabset(state, index, std::tabget(mixin, index));
}
// *** Class class - hand made
//     -----------------------
//     <^> Public methods
//         - createInstance( stateInitialiser, prototype )
//               stateInitialiser is called with arguments: the new object's state
//               and whatever other arguments are passed to the NEW class' createInstance().
//     <^> state fields
//         - stateInitialiser
//         - prototype
function Class {
	if (std::isundefined(static Class_prototype))
		Class_prototype = [
			// Public API
			method createInstance(...) {
				local stateInitialiser = ::dobj_get(self, #stateInitialiser);
				local prototype        = ::dobj_get(self, #prototype);
				assert(std::iscallable(stateInitialiser));
				assert(::isdeltaobject(prototype));
				newInstanceState = [];
				std::delegate(newInstanceState, prototype);
				stateInitialiser(newInstanceState, ...);
				return newInstanceState;
			}
		];
	if (std::isundefined(static class_Class)) {
		Class_state = [
			{ ::pfield(#stateInitialiser) : function (newClassInstance, stateInitialiser, prototype) {
				::dobj_set(newClassInstance, #stateInitialiser, stateInitialiser);
				::dobj_set(newClassInstance, #prototype       , prototype       );
			} },
			{ ::pfield(#prototype) : Class_prototype }
		];
		std::delegate(Class_state, Class_prototype);
	}
	return Class_state;
}

class_Class = Class();
class_Point = class_Class.createInstance(
	function (newPointInstance, x, y) {
		::dobj_set(newPointInstance, #x, x);
		::dobj_set(newPointInstance, #y, y);
	},
	[
		method print {
			local x = ::dobj_get(self, #x);
			local y = ::dobj_get(self, #y);
			::println("Point[", x, ",", y, "]");
		}
	]
);

point = class_Point.createInstance(12, 34);

point.print();
