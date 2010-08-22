u = std::libs::import("util");
assert( u );

function ProjectLoader_loadProject (projectPath, variableEvaluator) {
	if (local projectXML = u.xmlload(projectPath)) {
		u.println(projectXML);
	}
	else
		u.error().AddError("Could not load project file (XML) from ", projectPath);
}


////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("ProjectLoader", nil, nil);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////
