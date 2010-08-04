if (not (util = std::vmload("../../Util/Lib/util.dbc", "util")))
	std::error("Could not load util library");
std::vmrun(util);
if ( not util.loadlibs() )
	std::error("Could not load libs");



