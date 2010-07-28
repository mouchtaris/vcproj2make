util = std::vmget(#util);
if (not util) {
    util = std::vmload("util.dbc", #util);
    std::vmrun(util);
}
assert( util );

// Adaptors to CProject and CSolution
// --------------------
// They create CProject and CSolution instances from 
// Visual Studio projects and Solutions
function VisualStudioProjectAdaptor(vcproj_filepath_str) {
    vcproj_data = xmlload(vcproj_filepath_str);
    
}
