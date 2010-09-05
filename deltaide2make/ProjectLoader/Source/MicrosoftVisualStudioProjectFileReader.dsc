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

function GetProjectTypeForConfiguration (projectXML) {
	
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
