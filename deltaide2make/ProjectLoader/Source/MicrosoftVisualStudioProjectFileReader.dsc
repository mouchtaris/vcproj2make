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
	function childGetter (xml, child) {
		local result = xml[child];
		if (u.isdeltanil(result))
			u.error().AddError("Fail key in xpath: ", child, ". XML: ", xml);
		return result;
	}
	return u.fold(u.Iterable_fromArguments(arguments), childGetter);
}
function p_xfree (parent, child) {
	assert( parent[child] );
	parent[child] = nil;
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
	const ConfigurationType_Name = "ConfigurationType";
	local configuration = ::p_getConfiguration(projectXML, projectConfiguration);
	assert( u.isdeltaobject(configuration) );
	local configurationType = std::strtonum(::p_xpath(configuration, ConfigurationType_Name));
	if (configurationType) 
		::p_xfree(configuration, ConfigurationType_Name);
	assert( u.isdeltanumber(configurationType) );
	local result = ::ProjectTypeMappings[ configurationType ];
	assert( result );
	return result;
}

function GetProjectName (projectXML) {
	const Name_Name = "Name";
	local result = ::p_xpath(projectXML, Name_Name); 
	if (result)
		::p_xfree(projectXML, Name_Name);
	assert( u.isdeltastring(result) );
	return result;
}

// returns a wrapped list with the relative paths of source files
function GetProjectSourceFiles (projectXML) {
	function filtreIsSourceFilesFiltre (filtreXML) {
		const Filtre_Name = "Filter";
		local filtersString = ::p_xpath(filtreXML, Filtre_Name);
		local extensions = u.strsplit(filtersString, ";", 0);
		assert( u.dobj_length(extensions) > 0 );
		local result = u.iterable_find(extensions,
				u.equalitypredicate("cpp"));
		return result;
	}

	local result = u.list_new();
	const Files_Name        = "Files";
	const Filter_Name       = "Filter";
	const File_Name         = "File";
	const RelativePath_Name = "RelativePath";
	foreach (local filtre, local filters = ::p_xpath(projectXML, Files_Name, 0, Filter_Name))
		if (filtreIsSourceFilesFiltre(filtre))
			foreach (local file, local files = ::p_xpath(filtre, File_Name))
				u.list_push_back(result,
						u.assert_str(local relpath = ::p_xpath(file, RelativePath_Name)));
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
