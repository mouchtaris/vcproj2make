u = std::libs::import("util");
assert( u );

function ProjectLoader_loadProjectsFromSolutionData (solutionData) {
	local result = [];
	local configurationManager = solutionData.ConfigurationManager;
	foreach (local configuration, configurationManager.Configuration()) {
		//result[configuration] = local csol = u.CSolution().
		foreach (local projectID, configurationManager.Projects(configuration)) {
			if (configurationManager.isBuildable(configuration, projectID)) {
				
			}
		}
	}
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
