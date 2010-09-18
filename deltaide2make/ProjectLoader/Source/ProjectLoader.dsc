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
	function evaluateVariables (str, variableEvaluator) {
		function tokenise (str) { // => [ [ .var: boolean, .name: str ], ... ]
			local result = [];
			local resulti= 0;
			local restString = str;
			local varBeginIndex = u.strindex(str, "$");
			while (varBeginIndex >= 0) {
				assert( u.strchar(restString, varBeginIndex) == "$" ); // TODO if the "varBeginIndex" variable at the end of this while loop is declared as "local", then at this line the debugger evaluates "varBeginIndex" as "undefined"
				assert( u.strchar(restString, varBeginIndex + 1) == "(" );
				local beforeVarBeginLength = varBeginIndex;
				local beforeVarBegin = u.strsubstr(restString, 0, beforeVarBeginLength);
				if (u.strlength(beforeVarBegin))
					result[resulti++] = [ {.var: false}, {.name: beforeVarBegin} ];
				local substrWithoutVarBegin = u.strsubstr(restString, varBeginIndex + 2);
				local varEndIndex = u.strindex(restString, ")");
				assert( varEndIndex > varBeginIndex + 3 );
				assert( u.strchar(restString, varEndIndex) == ")" );
				local variableNameLength = varEndIndex - varBeginIndex - 2;
				local variableName = u.strsubstr(substrWithoutVarBegin, 0, variableNameLength);
				assert( u.strlength(variableName) > 0 );
				result[resulti++] = [ {.var: true}, {.name: variableName} ];
				//
				restString = u.strsubstr(restString, varEndIndex + 1);
				varBeginIndex = u.strindex(restString, "$");
			}
			if (u.strlength(restString) > 0)
				result[resulti++] = [ {.var: false}, {.name: restString} ];
			assert( resulti == u.dobj_length(result) );
			return result;
		}

		local result = "";
		local tokens = tokenise(str);
		local tokens_length = u.dobj_length(tokens);
		for (local token = tokens[local i = 0]; i < tokens_length; token = tokens[++i])
			if (token.var)
				result += variableEvaluator.eval(token.name);
			else
				result += token.name;
		return result;
	}
	function loadProject (solutionBasedirPath, projectPathMaybe, projectConfiguration, variableEvaluator) {
		local eval = u.bindback(evaluateVariables, variableEvaluator);
		local projectPath = u.Path_castFromPath(projectPathMaybe, false);
		local projectFilePath = solutionBasedirPath.Concatenate(projectPath);
		local projectXML = pr.Trim(u.xmlload(projectFilePath.deltaString()));
		local projectType = pr.GetProjectTypeForConfiguration(projectXML, projectConfiguration);
		local projectName = pr.GetProjectName(projectXML);
		local project = u.CProject().createInstance(projectType, projectPath, projectName);
		// Sources
		foreach (local src_relpath, u.list_to_stdlist(pr.GetProjectSourceFiles(projectXML)))
			project.addSource(u.Path_fromPath(src_relpath, true));
		// Output Directory
		project.setOutputDirectory(eval("$(SolutionDir)/$(ConfigurationName)")); // TODO do real
		// Output Name
		project.setOutputName("OutputName"); // TODO do real
		// API Directory
		project.setAPIDirectory(u.Path_fromPath("../Include", false)); // TODO do real
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
	local configurationManager  = solutionData.ConfigurationManager            ;
	local projectEntryHolder    = solutionData.ProjectEntryHolder              ;
	local solutionDirectory     = solutionData.SolutionDirectory               ;
	local solutionDirectoryPath = u.Path_castFromPath(solutionDirectory, false);
	local solutionName          = solutionData.SolutionName                    ;
	//
	foreach (local configuration, configurationManager.Configurations()) {
		log("Creating a Solution for configuration ", configuration);
		//
		local variableEvaluator = sl_ve.VariableEvaluator().createInstance(solutionDirectoryPath);
		variableEvaluator.setConfigurationName(configuration);
		//
		result[configuration] = local csol = u.CSolution().createInstance(
				u.Path_fromPath(solutionDirectory, false),
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
						u.Path_castFromPath(solutionDirectoryPath.basename(), false), projectEntry.getLocation(),
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
