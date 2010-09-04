u = std::libs::import("util");
assert( u );
sl_ve = std::libs::import("SolutionLoader/VariableEvaluator");
assert( sl_ve );

function ProjectLoader_loadProjectsFromSolutionData (solutionData) {
	function loadProject (projectFilePath, variableEvaluator) {
		local projectXML = u.xmlload(projectFilePath.deltaString());
		local project = u.CProject().createInstance(
				u.ProjectType().Executable,
				projectFilePath,
				"I don't know your naaaaame, any mooooreee"
		);
		return project;
	}

	local result = [];
	local configurationManager  = solutionData.ConfigurationManager     ;
	local projectEntryHolder    = solutionData.ProjectEntryHolder       ;
	local solutionDirectory     = solutionData.SolutionDirectory        ;
	local solutionDirectoryPath = u.Path_castFromPath(solutionDirectory);
	local solutionName          = solutionData.SolutionName             ;
	//
	local variableEvaluator     = sl_ve.VariableEvaluator().createInstance(solutionDirectoryPath);
	//
	foreach (local configuration, configurationManager.Configurations()) {
		result[configuration] = local csol = u.CSolution().createInstance(
				u.Path_fromPath(solutionDirectory),
				solutionName + "_" + configuration);
		foreach (local projectID, configurationManager.Projects(configuration))
			if (configurationManager.isBuildable(configuration, projectID)) {
				local projectEntry = projectEntryHolder.getProjectEntry(projectID);
				csol.addProject(loadProject (
						u.Path_castFromPath(solutionDirectoryPath.basename()).Concatenate(projectEntry.getLocation()),
						variableEvaluator
				));
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
