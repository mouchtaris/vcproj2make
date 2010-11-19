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
const RootNode_Name = "VisualStudioProject";
const RootNode_NameAttribute_Name = "Name";

p__xpath = [
	// noChildFailureHandler: called with args ()
	method pathImpl (args, noChildFailureHandler) {
		if (std::isundefined(static NotFound))
			static NotFound = [];
		else
			NotFound = NotFound;
		function childGetter (xml, child, childLookupFailureHandler) {
			local result;
			if (u.dobj_equal(xml, NotFound))
				result = NotFound;
			else if (u.isdeltanumber(child)) {
				assert( u.dobj_hasOnlyNumericKeys(xml) );
				result = xml[child];
				assert( u.XML().isanXMLObject(result) or u.isdeltanil(result) );
			}
			else if (u.isdeltastring(child)) {
				assert( u.XML().isanXMLObject(xml) );
				result = xml.getChild(child);
				assert( u.dobj_hasOnlyNumericKeys(result) or u.isdeltanil(result) );
			}

			if (u.isdeltanil(result)) {
				childLookupFailureHandler(xml, child);
				result = NotFound;
			}
			return result;
		}
		local childGetterClosure = [
			method @operator () (xml, child) {
				return childGetter(xml, child, @noChildFailureHandler);
			},
			@noChildFailureHandler: noChildFailureHandler
		];
		local result = u.fold(u.Iterable_fromArguments(args), childGetterClosure);
		if (u.dobj_equal(result, NotFound))
			result = nil;
		return result;
	}
];

function p_xpathIfExists (xml ...) {
	local result = ::p__xpath.pathImpl(arguments, u.nothing);
	return result;
}
function p_xpath (xml ...) {
	local result = ::p__xpath.pathImpl(arguments, function FailOnChildLookupFailureHandler (xml, child) {
		u.error().AddError("Fail key in xpath: ", child, ". XML: ", xml);
	});
	return result;
}

function p_xConfiguration (projectXML) {
	const Configurations_Name = "Configurations";
	const Configuration_Name = "Configuration";
	local result = ::p_xpath(projectXML, Configurations_Name, 0, Configuration_Name);
	return result;
}
const p_xName_Name = "Name";
function p_xName (projectXML) {
	assert( u.XML().isanXMLObject(projectXML) );
	local result = projectXML.getAttribute(::p_xName_Name); 
	assert( u.isdeltastring(result) );
	return result;
}
const p_xFiles_Name = "Files";
function p_xFiles (projectXML) {
	local result = ::p_xpath(projectXML, ::p_xFiles_Name);
	return result;
}
const p_xFilter_Name = "Filter";
function p_xFilter (projectXML) {
	local result = ::p_xpath(::p_xFiles(projectXML), 0, ::p_xFilter_Name);
	return result;
}

function p_getConfiguration (projectXML, config) {
	foreach (local configuration, ::p_xConfiguration(projectXML)) {
		assert( u.XML().isanXMLObject(configuration) );
		if (configuration.attrgetter().Name == config)
			return configuration;
	}
	return nil;
}

const p_ReferencesName = "References";
function p_xReferences (projectXML) {
	assert( u.XML().isanXMLObject(projectXML) );
	local references = projectXML.getChild(p_ReferencesName);
	return references;
}

function p_getToolFromConfiguration (configuration, toolName) {
	const Tool_Name = "Tool";
	const Name_Name = "Name";
	local result = nil;
	foreach (local toolNode, ::p_xpath(configuration, Tool_Name)) {
		local name = toolNode.getAttribute(Name_Name);
		assert( u.isdeltastring(name) );
		if (u.strequal(name, toolName)) {
			result = toolNode;
			break;
		}
	}
	return result;
}

function Trim (projectXML) {
	local x = projectXML;
	// Layer 0
	x.Globals                = nil;
	x.Platforms              = nil;
	x.ToolFiles              = nil;
	local y = x."$Attributes";
	y.Keyword                = nil;
	y.ProjectType            = nil;
	y.TargetFrameworkVersion = nil;
	y.Version                = nil;
	return x;
}

function GetProjectTypeForConfiguration (projectXML, projectConfiguration) {
	const ConfigurationType_Name = "ConfigurationType";
	local configuration = ::p_getConfiguration(projectXML, projectConfiguration);
	assert( u.XML().isanXMLObject(configuration) );
	local configurationTypeString = configuration.getAttribute(ConfigurationType_Name);
	assert( u.isdeltastring(configurationTypeString) );
	local configurationType = std::strtonum(configurationTypeString);
	assert( u.isdeltanumber(configurationType) );
	local result = ::ProjectTypeMappings[ configurationType ];
	assert( result );
	return result;
}

function GetProjectName (projectXML) {
	local name = ::p_xName(projectXML);
	assert( u.isdeltastring(name) );
	return name;
}

// returns a wrapped list with the relative paths of source files
function GetProjectSourceFiles (projectXML) {
	const Filtre_Name = "Filter";
	const File_Name         = "File";
	const Name_AttributeName = "Name";
	function filtreIsSourceFilesFiltre (filtreXML) {
		assert( u.XML().isanXMLObject(filtreXML) );
		local filtersString = filtreXML.getAttribute(Filtre_Name);
		local extensions = u.strsplit(filtersString, ";", 0);
		assert( u.dobj_length(extensions) > 0 );
		local result = u.iterable_find(extensions,
				u.equalitypredicate("cpp"));
		return result;
	}
	const RelativePath_Name = "RelativePath";
	function getRelativePathName (file) {
		assert( u.XML().isanXMLObject(file) );
		local result = file.getAttribute(RelativePath_Name);
		return result;
	}


	function exploreFileFiltreSubtree (xml) {
		assert( u.XML().isanXMLObject(xml) );
		local stack = (function makeStack { return [@list: u.list_new(),
			method push (o) { u.list_push_back(@list, o); },
			method pop   { return u.list_pop_back(@list); },
			method empty { return u.list_empty(@list);    }   ]; })();
		// 
		local closure = [@stack:stack, @xml: xml, @filtrePath: makeStack(), @pathRemover: [], @result: [],
			method addSelfToStack { @stack.push(@xml); },
			method getTopNode { @top = @stack.pop(); },
			method pushChildren {
				foreach (local childName, (local top = @top).ChildrenNames())
					foreach (local child, local children = top.getChild(childName))
						@stack.push(child);
			},
			method topNodeName { return @top.Name(); },
			method topNameAttr { return @top.getAttribute(Name_AttributeName); },
			method addNameToPath { @filtrePath.push(@topNameAttr()); },
			method topIsFiltre { return @topNodeName() == Filtre_Name; },
			method topIsFile { return @topNodeName() == File_Name; },
			method addFileToResult { @result[getRelativePathName(@top)] = @pathSnapshot(); },
			method pathSnapshot { return u.dval_copy(@filtrePath.list); },
			method pushPathRemover { @stack.push(@pathRemover); },
			method topIsPathRemover { return u.dobj_equal(@top, @pathRemover); },
			method removeLastPathElement { @filtrePath.pop(); },
			method getResult { return @result; }
		];
		local addSelfToStack        = closure.addSelfToStack;
		local getTopNode            = closure.getTopNode;
		local pushPathRemover       = closure.pushPathRemover;
		local pushChildren          = closure.pushChildren;
		local topIsFiltre           = closure.topIsFiltre;
		local addNameToPath         = closure.addNameToPath;
		local topIsFile             = closure.topIsFile;
		local addFileToResult       = closure.addFileToResult;
		local topIsPathRemover      = closure.topIsPathRemover;
		local removeLastPathElement = closure.removeLastPathElement;
		local topNodeName           = closure.topNodeName;
		local getResult             = closure.getResult;
		
		addSelfToStack();
		while ( not stack.empty() ) {
			getTopNode();
			if (topIsPathRemover())
				removeLastPathElement();
			else if (topIsFiltre()) {
				pushPathRemover();
				pushChildren();
				addNameToPath();
			}
			else if (topIsFile()) {
				addFileToResult();
				assert( closure.top.NumberOfChildren() == 0 );
			}
			else
				u.error().AddError("Unknown Node found in File/Filtre subtree: ", topNodeName());
		}

		return getResult();
	}
	local results = u.list_new();
	foreach (local filtre, local filters = ::p_xFilter(projectXML))
		if (filtreIsSourceFilesFiltre(filtre))
				u.list_push_back(results, exploreFileFiltreSubtree(filtre));
	
	local result = u.list_new();
	// Throw away filtre-path info, keep source files
	foreach (local oneresult, u.list_to_stdlist(results))
		foreach (local srcrelpath, u.dobj_keys(oneresult))
			u.list_push_back(result, srcrelpath);
	return result;
}

function GetProjectOutputDirectoryForConfiguration (projectXML, projectConfiguration) {
	const OutputDirectory_Name = "OutputDirectory";
	local configuration = ::p_getConfiguration(projectXML, projectConfiguration);
	assert( u.isdeltaobject(configuration) );
	local outputDirectory = configuration.getAttribute(OutputDirectory_Name);
	assert( u.strlength(outputDirectory) > 0 );
	return outputDirectory;
}

function GetProjectOutputForConfiguration (projectXML, projectConfiguration, projectType) {
	const DefaultOutputFile = "$(OutDir)\$(ProjectName)";
	const LinkerToolName = "VCLinkerTool";
	const OutputFile_Name = "OutputFile";
	local configuration = ::p_getConfiguration(projectXML, projectConfiguration);
	assert( u.isdeltaobject(configuration) );
	local tool = ::p_getToolFromConfiguration(configuration, LinkerToolName);
	assert( tool or projectType == ::ProjectTypes.StaticLibrary);
	if (not (tool and local outputFile = tool[OutputFile_Name]))
		outputFile = DefaultOutputFile;
	assert( u.strlength(outputFile) > 0 );
	return outputFile;
}

function p__getListAttributeValueFromToolParent (parentXml, toolName, attributeName, valueTransformation) {
	local tool = ::p_getToolFromConfiguration(parentXml, toolName);
	local valueString= tool.getAttribute(attributeName);
	local result;
	if (u.isdeltanil(valueString))
		result = u.list_new();
	else {
		local values = u.strsplit(valueString, ";", 0);
		result = u.iterable_map_to_list(values, valueTransformation);
	}
	return result;
}

function preprocessorDefinitionProcessor (preprocessorDefinitionString) {
	local definitionNameValuePair = u.strsplit(preprocessorDefinitionString, "=", 1);
	local name = definitionNameValuePair[0];
	local result = name;
	if (not u.isdeltanil(local valueUnprocessed = definitionNameValuePair[1])) {
		local value = u.strgsub(valueUnprocessed, "\\\"", "\"");
		result += "=" + value;
	}
	return result;
}

const CompilerToolName = "VCCLCompilerTool";
const IncludeDirectoriesName = "AdditionalIncludeDirectories";
const PreprocessorDefinitionsName = "PreprocessorDefinitions";
function p__getIncludeDirectoriesFromCompilerToolParent (parentXml) {
	local result =
		::p__getListAttributeValueFromToolParent(parentXml, CompilerToolName, IncludeDirectoriesName, u.bindback(u.Path_castFromPath, true));
	return result;
}

function p__getPreprocessorDefinitionsFromCompilerToolParent (parentXml) {
	local result =
		::p__getListAttributeValueFromToolParent(parentXml, CompilerToolName, PreprocessorDefinitionsName, preprocessorDefinitionProcessor);
	return result;
}

function GetProjectIncludeDirsForConfiguration (projectXML, configurationName) {
	local configuration = ::p_getConfiguration(projectXML, configurationName);
	local result = ::p__getIncludeDirectoriesFromCompilerToolParent(configuration);
	return result;
}

function GetProjectIncludeDirectoriesFromPropertySheet (pSheetXml) {
	local result = ::p__getIncludeDirectoriesFromCompilerToolParent(pSheetXml);
	return result;
}

function GetProjectPreprocessorDefinitionsForConfiguration (projectXml, configurationName) {
	local configuration = ::p_getConfiguration(projectXml, configurationName);
	local result = ::p__getPreprocessorDefinitionsFromCompilerToolParent(configuration);
	return result;
}

function GetProjectPreprocessorFromPropertySheet (pSheetXml) {
	local result = ::p__getPreprocessorDefinitionsFromCompilerToolParent(pSheetXml);
	return result;
}

const InheritedPropertySheetsName = "InheritedPropertySheets";
function GetProjectPropertySheetsForConfiguration (projectXml, configurationName) {
	local configuration = ::p_getConfiguration(projectXml, configurationName);
	local sheets_str = configuration.getAttribute(InheritedPropertySheetsName);
	if (u.isdeltanil(sheets_str))
		local result = u.list_new();
	else {
		local sheets = u.strsplit(sheets_str, ";", 0);
		result = u.iterable_map_to_list(sheets, u.bindback(u.Path_castFromPath, true));
	}
	return result;
}

const p_ProjectReference_ReferencedProjectIdentifierName = "ReferencedProjectIdentifier";
const p_ProjectReference_RelativePathToProjectName       = "RelativePathToProject"      ;
const p_ProjectReference_ProjectReferenceName            = "ProjectReference"           ;
// @return [refProjId => [path => path(..)], ...]
function GetProjectReferences (projectXML) {
	local isXMLObject = u.XML().isanXMLObject;
	local references = [];
	local referencesXML_all = ::p_xReferences(projectXML);
	assert( u.dobj_length(referencesXML_all) == 1 );
	local referencesXML = referencesXML_all[0];
	assert( isXMLObject(referencesXML) );
	if (local referencesXMLs = referencesXML.getChild(::p_ProjectReference_ProjectReferenceName))
		foreach (local referenceProjectXMLKey, local referenceProjectsXMLsKeys = u.dobj_keys(referencesXMLs)) {
			assert( u.isdeltanumber(referenceProjectXMLKey) );
			local referenceProjectXML = referencesXMLs[referenceProjectXMLKey];
			assert( isXMLObject(referenceProjectXML) );
			local refId = referenceProjectXML.getAttribute(p_ProjectReference_ReferencedProjectIdentifierName);
			assert( u.isdeltastring(refId) );
			local refPath = referenceProjectXML.getAttribute(p_ProjectReference_RelativePathToProjectName);
			assert( u.isdeltastring(refPath) );
			refPath = u.Path_castFromPath(refPath, true);
			assert( u.Path_isaPath(refPath) );
			references[refId] = local refInfo = [];
			refInfo.path = refPath;
		}
	return references;
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
