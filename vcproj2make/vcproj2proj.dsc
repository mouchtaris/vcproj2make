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
	
	local result = nil;
	::util.assert_str( solutionFilePath_str );
	::util.assert_str( solutionName );
	
	if (not local solutionData = loadSolutionDataFromSolutionFile(solutionFilePath_str))
		return nil;
	result = solutionData;
	return result;
}