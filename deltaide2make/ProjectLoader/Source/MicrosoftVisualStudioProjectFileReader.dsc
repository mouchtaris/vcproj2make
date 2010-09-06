u = std::libs::import("util");
assert( u );

////////////////////////////
// Module private
const MSVS_ProjectType_ConsoleApplication = 1;
const MSVS_ProjectType_DynamicLibrary     = 2;
const MSVS_ProjectType_StaticLibrary      = 4;
local ProjectTypes = u.ProjectType();
ProjectTypeMappings = [
	{MSVS_ProjectType_ConsoleApplication: ProjectTypes.Executable},
	{MSVS_ProjectType_DynamicLibrary    : ProjectTypes.DynamicLibrary},
	{MSVS_ProjectType_StaticLibrary     : ProjectTypes.StaticLibrary}
];
function p_xpath (xml ...) {
	function xpathFolder (xml, child) {
		local result = xml[child];
		if (u.isdeltanil(result))
			u.error().AddError("Fail key in xpath: ", child, ". XML: ", xml);
		return result;
	}
	return u.fold(u.Iterable_fromArguments(arguments), xpathFolder);
}
function p_getConfiguration (projectXML, config) {
	foreach (local configuration, p_xpath(projectXML, "Configurations", 0, "Configuration"))
		if (configuration.Name == config)
			return configuration;
	return nil;
}

function Trim (projectXML) {
	local x = projectXML;
	// Layer 0
	x.Globals                = nil;
	x.Keyword                = nil;
	x.Platforms              = nil;
	x.ProjectType            = nil;
	x.TargetFrameworkVersion = nil;
	x.ToolFiles              = nil;
	x.Version                = nil;
	x."$Name"                = nil;
	return x;
}

function GetProjectTypeForConfiguration (projectXML, projectConfiguration) {
	local configuration = p_getConfiguration(projectXML, projectConfiguration);
	assert( u.isdeltaobject(configuration) );
	local configurationType = std::strtonum(p_xpath( configuration, "ConfigurationType"));
	assert( u.isdeltanumber(configurationType) );
	local result = ::ProjectTypeMappings[ configurationType ];
	assert( result );
	return result;
}

function GetProjectName (projectXML) {
	local result = p_xpath(projectXML, "Name");
	assert( u.isdeltastring(result) );
	return result;
}


////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("ProjectLoader/MicrosoftVisualStudioProjectReader", nil, nil);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////
