u = std::libs::import("util");
assert( u );
sl_ve = std::libs::import("SolutionLoader/VariableEvaluator");
assert( sl_ve );
pr = std::libs::import("ProjectLoader/MicrosoftVisualStudioProjectReader");
assert( pr );


////////////////////////////
// Module private

//////////////////////////////
// Public
function ProjectLoader_loadProjectsFromSolutionData (solutionData, outer_log) {
	function loadProject (solutionBasedirPath, projectPathMaybe, projectConfiguration, variableEvaluator) {
		local projectPath = u.Path_castFromPath(projectPathMaybe);
		local projectFilePath = solutionBasedirPath.Concatenate(projectPath);
		local projectXML = pr.Trim(u.xmlload(projectFilePath.deltaString()));
		local projectType = pr.GetProjectTypeForConfiguration(projectXML, projectConfiguration);
		local projectName = pr.GetProjectName(projectXML);
		local project = u.CProject().createInstance(projectType, projectPath, projectName);
		// Sources
		foreach (local src_relpath, u.list_to_stdlist(pr.GetProjectSourceFiles(projectXML)))
			project.addSource(u.assert_str(src_relpath));
		// Output Directory
		project.setOutputDirectory("./output/"); // TODO do real
		// Output Name
		project.setOutputName("OutputName"); // TODO do real
		// API Directory
		project.setAPIDirectory("../Include"); // TODO do real
		// Manifestation configurations
		project.setManifestationConfiguration(#Makefile,
			[
				@CPPFLAGS_pre : [],
				@CPPFLAGS_post: [],
				@LDFLAGS_pre  : [],
				@LDFLAGS_post : [],
				@CXXFLAGS_pre : [],
				@CXXFLAGS_post: [],
				@ARFLAGS_pre  : [],
				@ARFLAGS_post : []
			]
		);

		return project;
	}

	local log = [
		method @operator () (...) {
			@l(u.argstostring(|arguments|));
		},
		@l: outer_log
	];
	//
	local result = [];
	//
	local configurationManager  = solutionData.ConfigurationManager     ;
	local projectEntryHolder    = solutionData.ProjectEntryHolder       ;
	local solutionDirectory     = solutionData.SolutionDirectory        ;
	local solutionDirectoryPath = u.Path_castFromPath(solutionDirectory);
	local solutionName          = solutionData.SolutionName             ;
	//
	local variableEvaluator     = sl_ve.VariableEvaluator().createInstance(solutionDirectoryPath);
	//
	foreach (local configuration, configurationManager.Configurations()) {
		log("Creating a Solution for configuration ", configuration);
		result[configuration] = local csol = u.CSolution().createInstance(
				u.Path_fromPath(solutionDirectory),
				solutionName + "_" + configuration);
		local projectsBuildInfos = configurationManager.Projects(configuration);
		local iterable           = u.Iterable_fromDObj(projectsBuildInfos);
		// foreach projectInfo
		for (local ite = iterable.iterator(); not ite.end(); ite.next()) {
			local projectID            = ite.key();
			local projectBuildInfo     = ite.value();
			local projectConfiguration = projectBuildInfo.buildable;
			local projectBuildable     = projectBuildInfo.config;
			if (projectBuildable) {
				assert( configurationManager.isBuildable(configuration, projectID) );
				local projectEntry = projectEntryHolder.getProjectEntry(projectID);
				log(configuration, ": Creating a project for ", projectID, "/", projectEntry.getName());
				csol.addProject(local cproj = loadProject(
						u.Path_castFromPath(solutionDirectoryPath.basename()), projectEntry.getLocation(),
						projectConfiguration,
						variableEvaluator
				));
			}
			else
				log("Project ", projectID, " not buildable");
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
