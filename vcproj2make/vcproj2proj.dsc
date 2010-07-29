util = std::vmget(#util);
if (not util) {
	util = std::vmload("util.dbc", #util);
	std::vmrun(util);
}
assert( util );

function xmlload(filename_str) {
	return ::util.xmlload(filename_str);
}
function xmlloadgeterror {
	return ::util.xmlloadgeterror();
}

// Adaptors to CProject and CSolution
// --------------------
// They create CProject and CSolution instances from 
// Visual Studio projects and Solutions
function VisualStudioProjectAdaptor(vcproj_filepath_str) {
	local vcproj_data = xmlload(vcproj_filepath_str);
	local vcproj_loaderror = xmlloadgeterror();
	::util.println(::util.orval(vcproj_data, vcproj_loaderror));
}