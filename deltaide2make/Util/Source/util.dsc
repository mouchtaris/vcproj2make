const plat_win32 = "win32";
const plat_linux = "linux";
const conf_debug = "debug";
const conf_release = "release";
ManualConfigurations = [
		@win32_debug  : [ plat_win32, conf_debug   ],
		@win32_release: [ plat_win32, conf_release ],
		@linux_debug  : [ plat_linux, conf_debug   ],
		@linux_release: [ plat_linux, conf_release ]
];
function getManualConfigurations {
	if ( std::isundefined(static configs) )
		configs = std::tabindices(::ManualConfigurations);
	return std::tabcopy(configs);
}
// Flag for classic delta compatibility
ASsafe = nil;
ManualConfiguration = nil;
function setManualConfiguration (conf) {
	if ( std::isundefined(static ASsafe_struct) )
		ASsafe_struct = [
				{ "NotSafe" : (function Asafe_NotSafe(funcname) {
					// No error, just warn
					local warning = std::vmfuncaddr(std::vmthis(), #warning);
					warning().Important("Calling a non-AS-safe function (" + funcname + ") in a AS-safe configuration");
				})}
			];


	if ( conf )
		if ( not local manconf = ::ManualConfigurations[conf] )
			std::error("Configuration " + conf + " does not exist. Provide one from: " +
					::getManualConfigurations());
		else
			::ManualConfiguration = manconf;
	else
		::ManualConfiguration = nil;
	
	if (::ManualConfiguration)
		::ASsafe = ASsafe_struct;
	else
		::ASsafe = nil;

	return ::ASsafe;
}
function isASsafe {
	return not not ::ASsafe;
}
// A ManualConfiguration can be defined only when ASsafe is defined
(method {
	const bool = lambda(v) { not not v };
	assert( bool(ManualConfiguration) == bool(ASsafe) );
})();

ASsafeAlternatives = [
	{plat_win32: [
		{conf_debug: [
			{#platform        : lambda { plat_win32   }},
			{#getcwd          : lambda { "."          }},
			{#getconfiguration: lambda { conf_debug   }}
		]},
		{conf_release: [
			{#platform        : lambda { plat_win32   }},
			{#getcwd          : lambda { "."          }},
			{#getconfiguration: lambda { conf_release }}
		]}
	]},
	{plat_linux: [
		{conf_debug: [
			{#platform        : lambda { plat_linux   }},
			{#getcwd          : lambda { "."          }},
			{#getconfiguration: lambda { conf_debug }}
		]},
		{conf_release: [
			{#platform        : lambda { plat_linux   }},
			{#getcwd          : lambda { "."          }},
			{#getconfiguration: lambda { conf_release }}
		]}
	]}
];

function False {
	return false;
}

function typeof(arg) {
	return std::typeof(arg);
}

function inspect(arg) {
	return "[" + ::typeof(arg) + "]{" + arg + "}";
}

// type games
function isdeltastring(val) { return ::typeof(val) == "String"; }
function isdeltaobject(val) { return ::typeof(val) == "Object"; }
function isdeltatable (val) { return ::typeof(val) == "Table" ; }
function isdeltanumber(val) { return ::typeof(val) == "Number"; }
function isdeltaboolean(val){ return ::typeof(val) == "Bool"  ; }
function isdeltanil   (val) { return ::typeof(val) == "Nil"   ; }
function isdeltaundefined(val){return std::isundefined(val)   ; }
function isdeltacallable(va){ return std::iscallable(va)      ; }
function toboolean    (val) { if (val) return true; else return false; }
function tobool       (val) { return ::toboolean(val)         ; }
//
// assertion utils
function Assert(cond) {
	assert( cond );
}
function assert_notnil(val) {
	::Assert( not ::isdeltanil(val) );
}
function assert_notundef(val) {
	::Assert( not ::isdeltaundefined(val) );
}
function assert_str(val) {
	::Assert( ::isdeltastring(val) );
	return val;
}
function assert_num(val) {
	::Assert( ::isdeltanumber(val) );
}
function assert_obj(val) {
	::Assert( ::isdeltaobject(val) );
}
function assert_tbl(val) {
	::Assert( ::isdeltatable(val) );
}
function assert_clb(val) {
	::Assert( ::isdeltacallable(val) );
}
function assert_eq(val1, val2) {
	::Assert( val1 == val2 );
}
function assert_lt(val1, val2) {
	::Assert( val1 < val2 );
}
function assert_gt(val1, val2) {
	::Assert( val1 > val2 );
}
function assert_ge(val1, val2) {
	::Assert( val1 >= val2 );
}
function assert_or(cond1, cond2) {
	::Assert( cond1 or cond2 );
}
function assert_and(cond1, cond2) {
	::Assert( cond1 and cond2 );
}
function assert_gt_or_eq(val1, val2, val3, val4) {
	::Assert( val1 > val2 or val3 == val4 );
}
function assert_ge_or_eq(val1, val2, val3, val4) {
	::Assert( val1 >= val2 or val3 == val4 );
}
function assert_def(val) {
	::assert_and( not ::isdeltanil(val) , not ::isdeltaundefined(val) );
}
function assert_fail {
	::Assert( not "Assertion-failure requested" );
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
	::Assert( i == args_end );
	return i;
}
function argstostring(...) {
	::foreacharg(arguments, local stringtor = [
		@str: "",
		method @operator () (arg) {
			@str += arg;
			return true;
		}
	]);
	return stringtor.str;
}
function error {
	if (std::isundefined(static error))
		error = [
			@AddError: function error_AddError(...) {
				// just err and die
				std::error(::argstostring(...));
			},
			@UnknownPlatform: function error_UnknownPlatform
				{ error_AddError("Unknown platform: " + std::vmfuncaddr(std::vmthis(), #platform)()); },
			@UnfoundLibFunc: function error_UnfoundLibFunc(libfuncname, extraerrmsg)
				{ error_AddError("Could not find a *::" + libfuncname + " libfunc. " + extraerrmsg); },
			@UnknownConfiguration: function error_UnknownConfiguration
				{ error_AddError("Unknown configuration: " + std::vmfuncaddr(std::vmthis(), #deltaconfiguration)()); },
				
			@Die: function error_Die(...)
				{ error_AddError(...); }
		];
	return error;
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

function warning {
	if (std::isundefined(static warning))
		warning = [
			@Important: function warning_Important(msg) {
				::println("[WARNING]: " + msg);
			}
		];
	return warning;
}

//

local p__DoNotASsafeCall = (method(funcname, ns1, ns2, args, extraerrmsg) {
	local result = nil;
	if (::ASsafe) {
		::ASsafe.NotSafe(funcname);
		// Perform alternative according to manual configuration
		local conf = ManualConfiguration;
		local alt = ::ASsafeAlternatives[ conf[0] ][ conf[1] ][ funcname ];
		result = alt(args);
	}
	else
		if ((local func = std::libfuncget(ns1 + "::" + funcname)) or func = std::libfuncget(ns2 + "::" + funcname))
			result = func(|args|);
		else
			::error().UnfoundLibFunc(funcname, extraerrmsg);
	return result;
});

// NOT an as-safe function
function platform {
	return ::p__DoNotASsafeCall(#platform, #isi, #std, [], "");
}
// NOT an as-safe function
function deltaconfiguration {
	return ::p__DoNotASsafeCall(#getconfiguration, #isi, #std, [], "");
}
function iswin32  { return ::platform() == "win32"; }
function islinux  { return ::platform() == "linux"; }
function isdebug  { return ::deltaconfiguration() == "debug"  ; }
function isrelease{ return ::deltaconfiguration() == "release"; }
function del(delegator, delegate) { std::delegate(delegator, delegate); }
function libifyname(filename) {
	local result = nil;
	if (::iswin32())
		result = filename + ".dll";
	else if (::islinux())
		result = "lib" + filename + ".so";
	else
		::error().AddError("Unknown platform for libifyname(): " + ::platform());
	return result;
}
private__loadlibsStaticData = [];
const private__DELTA_DLL_INSTALLATION_FUNCTION_NAME = "Install";
function loadlibs {
	function loadlib(basename) {
		::assert_str( basename );
		local configuration_basename = ( method (basename) {
			local suffix = nil;
			if (::isdebug())
				suffix = "D";
			else if (::isrelease())
				suffix = "";
			else
				::error().UnknownConfiguration();
			local result = nil;
			if ( ::isdeltastring(suffix) )
				result = basename + suffix;
			return result;
		})(basename);
		::assert_str( configuration_basename );
		local libname = libifyname(configuration_basename);
		local have_error = not libname;
		
		local result = nil;
		if (not have_error) {
			dll = std::dllimport(libname, private__DELTA_DLL_INSTALLATION_FUNCTION_NAME);
			if (dll)
				result = true;
			else {
				::error().AddError("Could not load library: " + libname);
				have_error = true;
			}
		}
		return result;
	}
	return ::private__loadlibsStaticData.libsloaded = 
			loadlib("XMLParser")                                           and
			(((not ::isASsafe()) and loadlib("VCSolutionParser")) or true) and
			true
	;
}
function libsloaded {
	return ::private__loadlibsStaticData.libsloaded;
}
// NOT an as-safe function
function getcwd {
	return p__DoNotASsafeCall(#getcwd, #isi, #std, [], "");
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
	return not ::isdeltanil(dobj[key]);
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
	::Assert( ::dobj_contains(validKeys, key) );
	return ::dobj_set(dobj, key, val);
}
function dobj_checked_get(dobj, validKeys, key) {
	::Assert( ::dobj_contains(validKeys, key) );
	local result = ::dobj_get(dobj, key);
	::assert_notnil(result);
	return result;
}
function dobj_length(dobj) {
	return std::tablength(dobj);
}
function dobj_keys(dobj) {
	return std::tabindices(dobj);
}
function dobj_empty(dobj) {
	return ::dobj_length(dobj) == 0;
}
function dobj_copy (dobj) {
	return std::tabcopy(dobj);
}
function dobj_replace (dobj, index, newval) {
	local prev = dobj[index];
	dobj[index] = newval;
	return prev;
}

//
// Functional games
function constantf(val) {
	return [ method @operator () { return @val; }, @val: val ];
}
function argspopback(args, popnum) {
	::assert_tbl(args);
	::assert_num(args.start);
	::assert_num(args.total);
	::assert_lt( popnum , ::dobj_length(args) - 2 );
	args.total -= popnum;
	return args;
}
function argspopfront(args, popnum) {
	::argspopback(args, popnum).start += popnum;
	return args;
}
function bindfront(f ...) {
	return [
		method @operator () (...) {
			return @f(|@args|, ...);
		},
		@f:    f,
		@args: argspopfront(arguments, 1)
	];
}
function bindback(f ...) {
	return [
		method @operator () (...) {
			return @f(..., |@args|);
		},
		@f:    f,
		@args: argspopfront(arguments, 1)
	];
}
function fcomposition (f1, f2) {
	return [
		method @operator () (...) {
			return @f1(@f2(...));
		},
		@f1: f1,
		@f2: f2
	];
}
function membercalltransformation(object, membername, args) {
	return object[membername](|args|);
}
function membercalltransformer(membername, args) {
	::assert_str( membername );
	return [
		method @operator () (obj){
			return obj[@membername](|@args|);
		},
		@membername : membername,
		@args       : args
	];
}
function equals(val1, val2) {
	return val1 == val2;
}
function equalitypredicate(val) {
	return ::bindfront(::equals, val);
}
function nothing {
}
function nothingf {
	return ::nothing;
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
function iterable_map(iterable, mapf) {
	local result = std::list_new();
	foreach (local el, iterable)
		std::list_push_back(result, mapf(el));
	return result;
}
function iterable_find(iterable, predicate) {
	local result = nil;
	foreach (local val, iterable)
		if (predicate(val)) {
			result = val;
			break;
		}
	return result;
}
function iterable_get(iterable, index) {
	foreach (local el, iterable)
		if (not index--)
			return el;
	return nil;
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
function strindex(hay, needle) {
	return std::strsub(hay, needle);
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
function strmul(str, times) {
	return std::strrep(str, times);
}
function strsplit(str, pattern, max) {
	::assert_str( str );
	::assert_str( pattern );
	::assert_num( max );
	
	local pattern_length = ::strlength(pattern);
	local pieces_index = 0;
	local result = [];
	local times_left = max;
	local done = false;
	local search_in = str;
	while ( not done and search_in != "" and (times_left-- > 0 or max <= 0)) {
		local end = ::strindex(search_in, pattern);
		// if pattern found
		if ( not ( done = (end < 0)) ) {
			if ( end > 0 )
				--end;
			result[pieces_index++] = ::strsubstr(search_in, 0, end);
			search_in = ::strsubstr(search_in, end + 1 + pattern_length);
		}
	}
	// Append rest of the string as a piece
	result[pieces_index++] = search_in;
	::assert_eq( pieces_index, ::dobj_length(result) );
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
		result =
				(std::strlen(filepath) > 3 and std::strchar(filepath, 1) == ":" and std::strchar(filepath, 2) == "\\")
				or
				(std::strlen(filepath) > 1 and std::strchar(filepath, 0) == "\\")
		;
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
function file_separator {
	local result = nil;
	if (::iswin32())
		result = "\\";
	else if (::islinux())
		result = "/";
	else
		::error().AddError("unknown platform: ", ::platform());
	return result;
}
function file_pathconcatenate(...) {
	::foreacharg(arguments, local path_concatenator = [
		@sep : ::file_separator(),
		@path: "",
		method @operator () (arg) {
			::assert_str( arg );
			@path += arg;
			@path += @sep;
			return true;
		}
	]);
	return path_concatenator.path;
}
function file_basename(filepath) {
	::assert_str( filepath );
	local result = nil;
	foreach (local separator, [ "\\", "/" ]) {
		local last_index = ::strrindex(filepath, separator);
		if (last_index >= 0)
			break;
	}
	if (last_index >= 0)
		result = ::strsubstr(filepath, 0, last_index);
	return result;
}
function file_copy(src, dst) {
	local result = nil;
	if (local fin = std::fileopen(src, "rb")) {
		if (local fout = std::fileopen(dst, "wb")) {
			local reader = std::reader_fromfile(fin);
			local writer = std::writer_fromfile(fout);
			local feof = false;
			while ( not feof ) {
				feof = true;
				local eof = false;
				local inbuf = std::reader_read_buffer(reader, 1024*16);
				local buffedreader = std::reader_frominputbuffer(inbuf);
				while ( not (eof = std::inputbuffer_eof(inbuf)) ) {
					feof = false;
					local deltastring = std::reader_read_string(buffedreader);
					assert( deltastring );
					std::writer_write_string(writer, deltastring);
				}
			}
			std::fileclose(fin);
			std::fileclose(fout);
			result = true;
		}
		else
			::error().AddError("Could not open file \"" + dst + "\" for writing.");
	}
	else
		::error().AddError("Could not open file \"" + src + "\" for reading.");

	return result;
}
function shell(command) {
	return std::fileexecute(command);
}
function shellcopy(srcpath, destpath) {
	if (::iswin32())
		result = ::shell("copy \"" + srcpath + "\" \"" + destpath + "\"");
	else if (::islinux())
		result = ::shell("cp '" + srcpath + "' '" + destpath + "'");
	else
		::error().AddError("Unknown platform: " + ::platform());
	return result;
}

//////////////////////
// flow/program structure utilities
// ---------
function orval(val1, val2) {
	local result = nil;
	if (val1)
		result = val1;
	else
		result = val2;
	return result;
}
function ternary (cond, val1, val2) {
	if (cond)
		return val1;
	else
		return val2;
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
	local number_of_fields = ::dobj_length(validFieldsNames);
	local fields_len = ::dobj_length(fields);
	if ( fields_len != number_of_fields ) {
		::error().AddError("Invalid number of fields: ", fields_len, ". Should be: ", number_of_fields);
		return;
	}
	::assert_eq( fields_len , number_of_fields );
	foreach (local validFieldName, validFieldsNames) {
		local value = std::tabget(fields, validFieldName);
		if ( ::isdeltanil(value) or ::isdeltaundefined(value) ) {
			::error().AddError("Field name \"", validFieldName,
					"\" has not been found in the "
					"provided field names initialisations");
			break;
		}
		::assert_notundef( value );
		::assert_notnil( value );
		::dobj_set(newObjectInstance, validFieldName, value);
	}
}
function Class_isa(obj, a_class) {
	return ::isdeltaobject(obj) and ::dobj_contains(obj.getClasses(), a_class);
}
function Class_classRegistry {
	if (std::isundefined(static classRegistry) )
		classRegistry = [
			{ ::pfield(#list) : std::list_new() },
			method add(class) {
				::Assert( not ::list_contains(::dobj_get(self, #list), class) );
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
	::Assert( not ::stateFieldsClash( Object_stateFields(), newInstanceStateFields ) );
	::Assert( not ::prototypesClash( Object_prototype(), newInstancePrototype ) );
	::Assert(     ::mixinRequirementsFulfilled(newInstancePrototype, Object_mixinRequirements()) );
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
					::Assert( not ::stateFieldsClashForAnyMixIn( newInstanceState, mixin.stateFields() ) );
					::Assert( not ::prototypesClashForAnyMixIn( newInstanceState, mixin.getPrototype()) );
					::Assert(     ::mixinRequirementsFulfilledByAnyMixIn(newInstanceState, mixin.mixInRequirements()) );
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
				::Assert( ::Class_isa(a_mixin, Class()) ); // assert tha a_mixin is a class
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
				::Assert( ::Class_isa(another_class, ::Class()) );
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


p__classyClasses = true;
function becomeClassy {
	::p__classyClasses = true;
}
function becomeLean {
	::p__classyClasses = false;
}
function beClassy {
	return ::p__classyClasses;
}
function beLean {
	return not ::beClassy();
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
	static classy_Path_class;
	static light_Path_class;
	if (std::isundefined(static static_variables_undefined)) {
		static_variables_undefined = true;
		//
		classy_Path_class = ::Class().createInstance(
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
						::Assert( isaPath(another_relative_path) );
						::Assert( another_relative_path.IsRelative() );
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
					local pathstr = ::strsubstr(pathstr, 0, extindex);
					::assert_eq( extindex + 1 , ::strlength(pathstr) );
					::assert_eq( ::strchar(pathstr, ::strlength(pathstr) - 1), "." );
					::assert_eq( ::strsubstr(pathstr, extindex + 1), "" );
					pathstr = pathstr + newext;
					return ::Path().createInstance(pathstr, self.IsAbsolute());
				},
				method basename {
					return ::file_basename(self.deltaString());
				},
				method Append(str) {
					::assert_str( str );
					local pathstr = self.deltaString();
					::dobj_checked_set(self, ::Path().stateFields(), #Path_path, pathstr + str);
					return self;
				},
				// NOT API related
				method @ {
					return "path:" + self.deltaString();
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #Path_absolute, #Path_path ],
			// className
			#Path
		);
		classy_Path_class.isaPath      = isaPath;
		classy_Path_class.fromPath     = fromPath;
		classy_Path_class.castFromPath = castFromPath;
		//
		light_Path_class = [
			method createInstance (path, absolute) {
				return [
					@path: path, @absolute: absolute,
					method deltaString { return @path; },
					method IsAbsolute { return @absolute; },
					method IsRelative { return not @absolute; },
					method Concatenate (path) { return ::Path().createInstance(@path + "/" + path, @absolute); },
					method Extension { return ::strsubstr(@path, ::strrindex(@path, ".") + 1); },
					method asWithExtension (newext) { return ::Path().createInstance(::strsubstr(@path, 0, ::strrindex(@path, ".")) + newext, @absolute); },
					method Append (extrapath) { @path += extrapath; return self; },
					method basename { return ::file_basename(@path); }
				];
			},
			method isaPath (obj) { return self."$___CLASS_LIGHT___" == "Path"; },
			@fromPath: fromPath,
			@castFromPath: castFromPath
		];
	}
	
	return ::ternary(::beClassy(),
			classy_Path_class,
			light_Path_class
	);
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
				::Assert( p );
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
					::Assert( ::Path_isaPath(path) );
					return path;
				},
				method setLocation(path) {
					local p = ::Path_fromPath(path);
					::Assert( p );
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

// IDable
function IDable {
	if (std::isundefined(static IDable_class))
		IDable_class = ::Class().createInstance(
			// stateInitialiser
			function IDable_stateInitialiser(newIDableInstance, validFieldsNames, id) {
				::assert_str( id );
				::Class_checkedStateInitialisation(
					newIDableInstance,
					validFieldsNames,
					[ { #IDable_id: id } ]
				);
			},
			// prototype
			[
				method getID {
					return ::dobj_checked_get(self, ::IDable().stateFields(), #IDable_id);
				},
				method setID(id) {
					::assert_str(id);
					return ::dobj_checked_set(self, ::IDable().stateFields(), #IDable_id, id);
				}
			],
			// mixinRequirements
			[],
			// stateFields
			[ #IDable_id ],
			// Class name
			#IDable
		);
	return IDable_class;
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

// CProject
function CProject {
	if (std::isundefined(static CProject_class)) {
		CProject_class = ::Class().createInstance(
			// stateInitialiser
			function CProject_stateInitialiser(newInstance, validStateFieldsNames, projectType, path, projectName) {
				::Assert( ::ProjectType_isValid(projectType) );
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[
						{ #CProject_type                        : projectType     },
						{ #CProject_manifestationsConfigurations: []              },
						{ #CProject_sources                     : std::list_new() },
						{ #CProject_includes                    : std::list_new() },
						{ #CProject_dependencies                : std::list_new() },
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
					::Assert( ::Path_isaPath(p) );
					::assert_eq( p.Extension(), self.SourceExtension() );
					::dobj_get(self, #CProject_sources).push_back(p);
				},
				method Sources {
					return ::list_clone(::dobj_get(self, #CProject_sources));
				},
				method addIncludeDirectory(path) {
					local p = ::Path_castFromPath(path);
					::Assert( ::Path_isaPath(p) );
					::dobj_get(self, #CProject_includes).push_back(p);
				},
				method IncludeDirectories {
					return ::list_clone(::dobj_get(self, #CProject_includes));
				},
				method addDependency(project) {
					::Assert( ::Class_isa(project, ::CProject()) );
					::dobj_get(self, #CProject_dependencies).push_back(project);
				},
				method Dependencies {
					return ::list_clone(::dobj_get(self, #CProject_dependencies));
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
					::Assert( ::Path_isaPath(p) );
					::dobj_get(self, #CProject_librariesPaths).push_back(p);
				},
				method LibrariesPaths {
					return ::list_clone(::dobj_get(self, #CProject_librariesPaths));
				},
				method addLibrary(libname) {
					::assert_str( libname );
					::dobj_get(self, #CProject_libraries).push_back(libname);
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
					::Assert( ::ProjectType_isValid(type));
					return type == ProjectType_StaticLibrary;
				},
				method isDynamicLibrary {
					local type = ::dobj_get(self, #CProject_type);
					::Assert( ::ProjectType_isValid(type));
					return type == ProjectType_DynamicLibrary;
				},
				method isExecutable {
					local type = ::dobj_get(self, #CProject_type);
					::Assert( ::ProjectType_isValid(type));
					return type == ProjectType_Executable;
				},
				method isLibrary {
					return self.isDynamicLibrary() or self.isStaticLibrary();
				},
				method getOutputDirectory {
					local outputDirectory = ::dobj_get(self, #CProject_outputDirectory);
					::Assert( ::Path().isaPath(outputDirectory) );
					return outputDirectory;
				},
				method setOutputDirectory(pathable) {
					local path = ::Path().fromPath(pathable);
					::Assert( ::Path().isaPath(path) );
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
					::Assert( ::Path_isaPath(p) );
					::dobj_set(self, #CProject_apidir, p);
				},
				method getAPIDirectory {
					local apidir = ::dobj_get(self, #CProject_apidir);
					::Assert( ::Path_isaPath(apidir) );
					return apidir;
				},
				method SourceExtension {
					return "cpp";
				},
				method ObjectExtension {
					return "thingamajig";
				},
				method DependencyExtension {
					return "mannerism";
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #CProject_type, #CProject_manifestationsConfigurations, #CProject_sources, #CProject_includes,
			  #CProject_dependencies, #CProject_definitions, #CProject_librariesPaths, #CProject_libraries,
			  #CProject_outputDirectory, #CProject_outputName, #CProject_apidir],
			// className
			#CProject
		);
		CProject_class.mixIn(::Locatable(), [
			method @operator () (newInstance, validStateFieldsNames, projectType, path, projectName) {
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
function CProject_depthFirstForeachSubproject(proj, f) {
	function impl(proj, f, keep_going) {
		::Assert( ::CProject_isaCProject(proj) );
		if (keep_going.val) {
			foreach (local subproj, proj.Subprojects()) {
				@lambda(subproj, f, keep_going);
				if (keep_going.val and not f(subproj)) {
					keep_going.val = false;
					break;
				}
			}
		}
	}
	impl(proj, f, [@val: true]);
}


// CSolution
function CSolution {
	if (std::isundefined(static CSolution_class)) {
		// createInstance( solutionPath:Path_fromPath(), solutionName:deltastring )
		CSolution_class = ::Class().createInstance(
			// stateInitialiser
			function CSolution_stateInitialiser(newInstance, validStateFieldsNames, solutionPath, solutionName) {
				Class_checkedStateInitialisation(
					newInstance,
					validStateFieldsNames,
					[
						{ #CSolution_projects: std::list_new() }
					]
				);
			},
			// prototype
			[
				method findProject(projectName) {
					::assert_str( projectName );
					local projects = ::dobj_checked_get(self, ::CSolution().stateFields(), #CSolution_projects);
					local result = ::iterable_find(
							projects,
							fcomposition(
									::equalitypredicate(projectName),
									::bindback(::membercalltransformation, #getName, [])
							)
						)
					;
					return result;
				},
				method addProject(project) {
					::Assert( ::CProject_isaCProject(project) );
					local projects = ::dobj_checked_get(self, ::CSolution().stateFields(), #CSolution_projects);
					if (self.findProject(project.getName())) {
						::error().AddError("Project with name ", project.getName(), " already exists "
								"in solution ", self.getName());
						return;
					}
					std::list_push_back(projects, project);
				},
				method Projects {
					return ::list_clone(
						::dobj_checked_get(self, ::CSolution().stateFields(), #CSolution_projects)
					);
				}
			],
			// mixInRequirements
			[],
			// stateFields
			[ #CSolution_projects],
			// className
			#CSolution
		);
		CSolution_class.mixIn(::Locatable(), [
			method @operator () (newInstance, validStateFieldsNames, solutionPath, solutionName) {
				return [solutionPath];
			}
		]);
		CSolution_class.mixIn(::Namable()  , [
			method @operator () (newInstance, validStateFieldsNames, solutionPath, solutionName) {
				return [solutionName];
			}
		]);
	}
	return CSolution_class;
}
function CSolution_isaCSolution(object) {
	return ::Class_isa(object, ::CSolution());
}


// IDableHolder template class for mixing-in
function IDableHolder (holdingItemName) {
	if (std::isundefined(static Holder_classes))
		Holder_classes = [];
	else
		Holder_classes = Holder_classes;

	// Meta-class class generation utils
	function holderClassName (holdingItemName)
		{ return holdingItemName + "Holder"; }
	//
	function holderFieldPrefix (holdingItemName)
		{ return holderClassName(holdingItemName) + "_"; }
	//
	function holderFieldName (holdingItemName)
		{ return holderFieldPrefix(holdingItemName) + holdingItemName + "s"; }
	function holderItemNameMetafieldName (holdingItemName)
		{ return holderFieldPrefix(holdingItemName) + "holdingItemName"; }
	//
	function holderAddMethodName (holdingItemName)
		{ return "add" + holdingItemName; }
	function holderRetrieveMethodName (holdingItemName)
		{ return holdingItemName + "s"; }
	//

	if (not (local holder_class = Holder_classes[holdingItemName]) ) {
		holder_class = Holder_classes[holdingItemName] = [];
		holder_class.stateFields = [
			holderFieldName(holdingItemName),
			holderItemNameMetafieldName(holdingItemName)
		];
		holder_class.class = ::Class().createInstance(
			// state initialiser
			[
				method @operator () (newHolderInstance, validFieldsNames) {
					::Class_checkedStateInitialisation(
						newHolderInstance,
						validFieldsNames,
						[
							{ holderFieldName(@itemName): [] },
							{ holderItemNameMetafieldName(@itemName): @itemName}
						]
					);
				},
				@itemName: holdingItemName
			],
			// prototype
			[
				{ holderAddMethodName(holdingItemName): [ method @operator () (idable) {
					local result = nil;
					if (not ::Class_isa(idable, ::IDable()))
						::error().AddError("Not an IDable: ", idable);
					else if ((local holder = self[holderFieldName(@itemName)])[local id = idable.getID()])
						::error().AddError("IDable already added in holder: ", idable);
					else
						result = ::tobool(holder[id] = idable);
					return result;
				}, @itemName: holdingItemName] },
				{ holderRetrieveMethodName(holdingItemName): [ method @operator () {
					local holder = self[holderFieldName(@itemName)];
					local result = ::dobj_copy(holder);
					return result;
				}, @itemName: holdingItemName] }
			],
			// mix in requirements
			[],
			// state fields
			holder_class.stateFields,
			// class name
			holderClassName(holdingItemName)
		);
	}

	return holder_class.class;
}


////////////////////////
// xml utilities
////////////////////////
xmlload_LibFunc         = #xmlload;
xmlparse_LibFunc        = #xmlparse;
xmlloadgeterror_LibFunc = #xmlloadgeterror;
xmlparsegeterror_LibFunc= #xmlloadgeterror;
function xmlload(filename_str) {
	::Assert( ::libsloaded() );
	local xmlload = std::libfuncget(::xmlload_LibFunc);
	local result = xmlload(filename_str);
	return result;
}
function xmlloaderror {
	::Assert( ::libsloaded() );
	local xmlloadgeterror = std::libfuncget(::xmlloadgeterror_LibFunc);
	local result = xmlloadgeterror();
	return result;
}
function xmlparse(str) {
	::Assert( ::libsloaded() );
	local xmlparse = std::libfuncget(::xmlparse_LibFunc);
	local result = xmlparse(str);
	return result;
}
function xmlparseerror {
	::Assert( ::libsloaded() );
	local xmlparsegeterror = std::libfuncget(::xmlparsegeterror_LibFunc);
	local result = xmlparsegeterror();
	return result;
}


////////////////////////////////////////
// Logging
////////////////////////////////////////
function log (from ...) {
	local str = ::argstostring("[", from, "]: ", |::argspopfront(arguments, 1)|);
	::println(str);
}