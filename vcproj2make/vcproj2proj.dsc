util = std::vmget(#util);
if (not util) {
	util = std::vmload("util.dbc", #util);
	std::vmrun(util);
}
assert( util );

function xmlload(filename_str) {
	return ::util.xmlload(filename_str);
}
// Should only be called if xmlload returns falsy
function xmlloaderror {
	local error_message = ::util.xmlloaderror();
	if ( not error_message )
		::util.error().AddError("No error message returned from XML loader");
	return error_message;
}

///////////// TODO temporary code, for reference //////////////////////
function{
// Adaptors to CProject and CSolution
// --------------------
// They create CProject and CSolution instances from 
// Visual Studio projects and Solutions


function VisualStudioProjectAdaptor(vcproj_filepath_str) {
	local vcproj_data = xmlload(vcproj_filepath_str);
	local vcproj_loaderror = ::xmlloaderror();
	if (vcproj_data) {
		::util.Assert( not vcproj_loaderror );
		::util.println( ::util.dobj_keys(vcproj_data) );
	}
	else {
		::util.Assert( vcproj_loaderror );
		::util.p(vcproj_loaderror);
	}
}
///////////////////////////////////////////////////////////////////////
}

function CSolutionFromVCSolution(solutionFilePath_str, solutionName) {
	
	function loadSolutionDataFromSolutionFile(solutionFilePath_str) {
		::util.assert_str( solutionFilePath_str );
		local data = xmlload(solutionFilePath_str);
		if (not data)
			::util.error().AddError(::xmlloaderror());
		return data;
	}
	
	/////////////////////////////////////////////////////////////////
	// Various constants
	// --------------------------------------------------------------
	const SolutionConfigurationPlatforms_TypeAttributeValue = "SolutionConfigurationPlatforms";
	const ProjectConfigurationPlatforms_TypeAttributeValue  = "ProjectConfigurationPlatforms";
	
	/////////////////////////////////////////////////////////////////
	// Errors, error messages, error reporting
	// --------------------------------------------------------------
	function E_NoSolutionConfigurationPlatformsElementFound(SolConfPlats) {
		::util.error().AddError("No /Global/GlobalSection/ with type=\"" + SolConfPlats + "\"");
	}
	
	
	/////////////////////////////////////////////////////////////////
	// XML data (pre)processing
	// --------------------------------------------------------------
	function xppRemoveUninterestingFields(solutionXML) {
		local keys_to_die = std::list_new();
		local interesting_global_section_types = [
				SolutionConfigurationPlatforms_TypeAttributeValue,
				ProjectConfigurationPlatforms_TypeAttributeValue];
		// Remove useless "GlobalSection"s
		foreach (local key, ::util.dobj_keys(local gsects = solutionXML.Global.GlobalSection)) {
			local gsect = gsects[key];
			if ( not ::util.dobj_contains(interesting_global_section_types, gsect.type) )
				gsects[key] = nil;
		}
	}
	
	/////////////////////////////////////////////////////////////////
	// Utilities for quick access to standard XPATHs
	// --------------------------------------------------------------
	function xGlobalSectionWithType(solutionXML, type) {
		foreach (local xGlobalSection, solutionXML.Global.GlobalSection)
			if (xGlobalSection.type == type)
				return xGlobalSection;
		return nil;
	}
	function xSolutionConfigurationPlatforms(solutionXML) {
		if (not local result = xGlobalSectionWithType(solutionXML, SolutionConfigurationPlatforms_TypeAttributeValue))
			E_NoSolutionConfigurationPlatformsElementFound(SolutionConfigurationPlatforms_TypeAttributeValue);
		return result;
	}
	
	/////////////////////////////////////////////////////////////////
	// Data extraction from XML elements
	// --------------------------------------------------------------
	function dexSolutionConfigurations(configurations_element) {
		::util.Assert( configurations_element.type == SolutionConfigurationPlatforms_TypeAttributeValue );
		local configurations = [];
		foreach (local pair, configurations_element.Pair) {
			::util.Assert( pair.left == pair.right );
			configurations[pair.left] = pair.right;
		}
		return configurations;
	}
	
	local result = nil;
	::util.assert_str( solutionFilePath_str );
	::util.assert_str( solutionName );
	
	if (not local solutionData = loadSolutionDataFromSolutionFile(solutionFilePath_str))
		return nil;
		
	// Test code
	xppRemoveUninterestingFields(solutionData);
	local xsolconfplats = xSolutionConfigurationPlatforms(solutionData);
	local confsdata     = dexSolutionConfigurations(xsolconfplats);
	
	return result = solutionData;
}