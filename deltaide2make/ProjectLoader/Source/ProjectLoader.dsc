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
	function loadProject (solutionBasedirPath, projectPathMaybe, projectConfiguration, variableEvaluator, out_References) {
		function makeProjectPropertyFromSheetXml (sheetXml) {
			local includeDirs = pr.GetProjectIncludeDirectoriesFromPropertySheet(sheetXml);
			local projprops = u.CProjectProperties().createInstance();
			foreach (local includeDir, u.list_to_stdlist(includeDirs))
				projprops.addIncludeDirectory(includeDir);
			return projprops;
		}
		local tick = [ // TODO remove tick and stuff
			method @operator () {
				local now = std::currenttime();
				local prev = @prev;
				local diff = now - prev;
				local total = @total + diff;
				local diffs = @diffs;
				local diffs_i = @diffs_i;
				diffs[diffs_i] = diff;
				u.println(" --- tick --- [", diffs_i, "] ", diff, "msec    (", total, "msec)");
				// update self
				@prev = now, @total = total; ++@diffs_i;
			},
			method max {
				local max = [ @diff: 0 ];
				foreach (local diff_i, u.dobj_keys(local diffs = @diffs))
					if ((local diff = diffs[diff_i]) > max.diff)
						max = [ @diff: diff, @diff_i: diff_i ];
				return max;
			},
			@total: 0, @diffs: [], @diffs_i: 0, @prev: 0
		];
		function preproOutputFile (outFileStr) {
			local result = u.Path_castFromPath(outFileStr).filename();
			assert( u.isdeltastring(result) );
			return result;
		}
		function loadXMLFromPath (filePath, withTrimming) {
			local xml = u.xmlload(filePath.deltaString());
			if (u.isdeltanil(xml))
				u.error().AddError("Could not load xml from path \"",
						filePath.deltaString(), "\" xmlerror: \"",
						u.xmlloaderror());
			else if (withTrimming)
				xml = pr.Trim(xml);
			xml = u.XML().createFromXMLRoot(xml);
			return xml;
		}
		tick.prev = std::currenttime();
		local eval = u.bindback(evaluateVariables, variableEvaluator);
		tick(); // 0
		local projectPath = u.Path_castFromPath(projectPathMaybe, false);
		tick(); // 1
		local projectFilePath = solutionBasedirPath.Concatenate(projectPath);
		tick(); // 2
		local projectXML = loadXMLFromPath(projectFilePath, true);
		tick(); // 3
		local projectPropertySheetsPathsStrings = pr.GetProjectPropertySheetsForConfiguration(projectXML, projectConfiguration);
		tick(); // 4
		local projectDirectory = u.Path_castFromPath(projectFilePath.basename(), false);
		tick(); // 5
		local projectSheetsXmls = u.iterable_map_to_std_list(u.list_to_stdlist(projectPropertySheetsPathsStrings), [
				method @operator () (sheetPathMaybe) {
					local sheetPath = u.Path_castFromPath(sheetPathMaybe, true);
					assert( sheetPath.IsRelative() );
					local fullSheetPathString = @projectDirectory.Concatenate(sheetPath.deltaString());
					local sheetXml = loadXMLFromPath(fullSheetPathString, false);
					return sheetXml;
				},
				@projectDirectory: projectDirectory
			]);
		tick(); // 4
		local projectType = pr.GetProjectTypeForConfiguration(projectXML, projectConfiguration);
		tick(); // 5
		local projectName = pr.GetProjectName(projectXML);
		tick(); // 6
		local outputDirectory = pr.GetProjectOutputDirectoryForConfiguration(projectXML, projectConfiguration);
		tick(); // 7
		local outputFile = pr.GetProjectOutputForConfiguration(projectXML, projectConfiguration, projectType);
		tick(); // 8
		local includeDirs = pr.GetProjectIncludeDirsForConfiguration(projectXML, projectConfiguration);
		tick(); // 9
		local project = u.CProject().createInstance(projectType, projectPath, projectName);
		tick(); // 10
		// Enrich variableEvaluator
		variableEvaluator.setProjectName(projectName);
		tick(); // 11
		variableEvaluator.setOutdir(eval(outputDirectory));
		tick(); // 12
		//
		local outputFilePath = u.Path_castFromPath(eval(outputFile), true);
		tick(); // 13
		// Sources
		foreach (local src_relpath, u.list_to_stdlist(pr.GetProjectSourceFiles(projectXML)))
			project.addSource(u.Path_fromPath(src_relpath, true));
		tick(); // 14
		// Output Directory
		project.setOutputDirectory(outputFilePath.basename());
		tick(); // 15
		// Output Name
		project.setOutputName(outputFilePath.filename());
		tick(); // 16
		// API Directory
		project.setAPIDirectory(u.Path_fromPath("../../Include", false));
		tick(); // 17
		// Set this project's properties
		local projprops = u.CProjectProperties().createInstance();
		tick(); // 18
		foreach (local includeDir, u.list_to_stdlist(includeDirs))
			projprops.addIncludeDirectory(includeDir);
		tick(); // 19
		project.addProjectProperties(projprops);
		tick(); // 20
		foreach (local sheetXml, projectSheetsXmls) {
			local prop = makeProjectPropertyFromSheetXml(sheetXml);
			project.addProjectProperties(prop);
		}
		tick(); // 21
		// Load this project's references
		local references = pr.GetProjectReferences(projectXML);
		tick(); // 22
		u.dval_copy_into(out_References, references);
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
		tick(); // 23
		u.println(tick.max());

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
	local solutionBaseDirectory = solutionData.SolutionBaseDirectory           ;
	assert( not u.file_looksLikeWindowsPath(solutionBaseDirectory) );
	local solutionBaseDirectoryPath = u.Path_castFromPath(solutionBaseDirectory, false);
	local solutionName          = solutionData.SolutionName                    ;
	//
	foreach (local configuration, configurationManager.Configurations()) {
		log("Creating a Solution for configuration ", configuration);
		//
		result[configuration] = local csol = u.CSolution().createInstance(
				u.Path_fromPath(solutionDirectory, false),
				solutionName + "_" + configuration);
		// storing buildable projects and mapping their IDs to their Names
		// in order to resolve dependencies after all CProjects have been created.
		local buildableProjects = []; // [ projid => [.name => projName, .references => [(as returned by GetProjectReferences)]], ... ]
		local projectsBuildInfos = configurationManager.Projects(configuration);
		local iterable           = u.Iterable_fromDObj(projectsBuildInfos);
		// foreach projectInfo
		for (local ite = iterable.iterator(); not ite.end(); ite.next()) {
			local projectID            = ite.key();
			local projectBuildInfo     = ite.value();
			local projectConfiguration = projectBuildInfo.config;
			local projectBuildable     = projectBuildInfo.buildable;
			if (projectBuildable) {
				assert( configurationManager.isBuildable(configuration, projectID) );
				local projectEntry = projectEntryHolder.getProjectEntry(projectID);
				log(configuration, ": Creating a project for ", projectID, "/", projectEntry.getName());
				//
				local variableEvaluator = sl_ve.VariableEvaluator().createInstance(
						solutionBaseDirectoryPath, solutionDirectoryPath, solutionName);
				variableEvaluator.setConfigurationName(configuration);
				//
				local references = []; // will be filled by loadProject()
				local time0 = std::currenttime(); // TODO remove
				local cproj = loadProject(
						u.Path_castFromPath(solutionDirectoryPath.basename(), false), projectEntry.getLocation(),
						projectConfiguration,
						variableEvaluator,
						references // result destination
				);
				assert( u.CProject_isaCProject(cproj) );
				csol.addProject(cproj);
				local time1 = std::currenttime();
				log("addProject(loadProject()) takes ", time1 - time0, " msec (??)");
				buildableProjects[projectID] = [
						{ .name      : cproj.getName() },
						{ .references: references      }
					];
			}
			else
				log("Project ", projectID, " not buildable");
		}
		// Add dependencies
		foreach (local buildableProjectId, local buildableProjectsIds = u.dobj_keys(buildableProjects)) {
			local buildableProjectInfo = buildableProjects[buildableProjectId];
			local buildableProjectName = buildableProjectInfo.name;
			local references           = buildableProjectInfo.references;
			assert( configurationManager.isBuildable(configuration, buildableProjectId) );
			local project = csol.findProject(buildableProjectName);
			assert( u.CProject_isaCProject(project) );
			local projectEntry = projectEntryHolder.getProjectEntry(buildableProjectId);
			local projectDependencies = projectEntry.Dependencies();
			log("Adding dependencies (", u.list_cardinality(projectDependencies), "/", u.dobj_length(references), ") for ", buildableProjectId, " ...");
			foreach (local depId, u.list_to_stdlist(projectDependencies)) {
				assert( configurationManager.isBuildable(configuration, depId) );
				local dependencyProjectName = buildableProjects[depId].name;
				assert( u.isdeltastring(dependencyProjectName) );
				local dependencyProject = csol.findProject(dependencyProjectName);
				assert( u.CProject_isaCProject(dependencyProject) );
				project.addDependency(dependencyProject);
				log("        ", depId, "/", dependencyProjectName);
			}
			// also add project references
			foreach (local depId, local depIds = u.dobj_keys(references)) {
				assert( configurationManager.isBuildable(configuration, depId) );
				local depInfo = references[depId];
				local depPath = depInfo.path;
				assert( u.Path_isaPath(depPath) );
				local depName = buildableProjects[depId].name;
				assert( u.isdeltastring(depName) );
				local depProj = csol.findProject(depName);
				assert( u.CProject_isaCProject(depProj) );
				// TODO normalise paths for this comparison to work
				// assert( depPath.equals(depProj.getLocation()) );
				project.addDependency(depProj);
				log("        ", depId, "/", depName, "  (from reference)");
			}
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
