u = std::libs::import("util");
assert( u );

function ProjectLoader_loadProjectsFromSolutionData (solutionData) {
	local result = [];
	local configurationManager = solutionData.ConfigurationManager;
	foreach (local configuration, configurationManager.Configurations()) {
		result[configuration] = local csol = u.CSolution().createInstance(
				u.Path_fromPath(solutionData.SolutionDirectory),
				solutionData.SolutionName + "_" + configuration);
		foreach (local projectID, configurationManager.Projects(configuration))
			if (configurationManager.isBuildable(configuration, projectID)) {
				
			}
	}
	return result;
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
