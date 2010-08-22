// Get util library
u  = std::libs::import("util");
sd = std::libs::import("SolutionLoader/SolutionData");
rg = std::libs::import("ReportGenerator");
if (not u or not sd or not rg)
	std::error("Could not acquire necessary VMs");

function SolutionLoader_LoadSolution (solutionXML) {
	
	
	/////////////////////////////////////////////////////////////////
	// Various constants
	// --------------------------------------------------------------
	const VCPROJ_Extension                                  = "vcproj";
	//
	const Global_ElementName                                = "Global";
	const GlobalSection_ElementName                         = "GlobalSection";
	const SolutionConfigurationPlatforms_TypeAttributeValue = "SolutionConfigurationPlatforms";
	//
	const ProjectConfigurationPlatforms_TypeAttributeValue  = "ProjectConfigurationPlatforms";
	const Project_ElementName                               = "Project";
	const ProjectSection_ElementName                        = "ProjectSection";
	const ProjectDependencies_TypeAttributeValue            = "ProjectDependencies";
	//
	const Pair_ElementName                                  = "Pair";
	//
	const WebsiteProperties_TypeAttributeValue              = "WebsiteProperties";
	const SolutionItems_TypeAttributeValue                  = "SolutionItems";
	
	
	
	/////////////////////////////////////////////////////////////////
	// Private module utilities
	// --------------------------------------------------------------
	function log (...) {
		u.log("SolutionLoader", ...);
	}
	
	
	
	/////////////////////////////////////////////////////////////////
	// Utilities for XML nodes
	// --------------------------------------------------------------
	function xmlgetchild (parent, childindex) {
		u.Assert( parent );
		u.assert_def( childindex );
		local child = parent[childindex];
		u.Assert( child );
		return child;
	}
	function xmlhaschild (parent, childindex) {
		return u.toboolean(parent[childindex]);
	}
	function xmlgetchildwithindex (parent, childindex) {
		return [ childindex, xmlgetchild(parent, childindex) ];
	}
	// f(parent, childindex, child, childismany) => keep_iterating
	function xmlforeachchild (parent, childindex, f) {
		foreach (local key, u.dobj_keys(local children = xmlgetchild(parent, childindex)))
			if (not f(children, key, children[key], true))
				break;
	}
	
	
	
	/////////////////////////////////////////////////////////////////
	// Errors, error messages, error reporting
	// --------------------------------------------------------------
	function E_NoSolutionConfigurationPlatformsElementFound (SolConfPlats) {
		u.error().AddError("No /Global/GlobalSection/ with type=\"" + SolConfPlats + "\"");
	}
	function E_NoProjectConfigurationPlatformsElementFound (ProjConfPlats) {
		u.error().AddError("No /Global/GlobalSection/ with type=\"" + ProjConfPlats + "\"");
	}
	
	
	
	/////////////////////////////////////////////////////////////////
	// Utilities for abstracted and quick access to standard XPATHs
	// --------------------------------------------------------------
	function xfree (parent, childindex) {
		u.Assert( xmlgetchild(parent, childindex) == parent[childindex] );
		parent[childindex] = nil;
	}
	// --------------------------------------------------------------
	function xGlobal_parent (solutionXML) {
		return solutionXML;
	}
	function xGlobal (solutionXML) {
		local Global_elements = xmlgetchild(xGlobal_parent(solutionXML), Global_ElementName);
		// there is supposed to be only one <Global> element
		assert( u.dobj_length(Global_elements) == 1);
		return u.assert_def(Global_elements[0]);
	}
	function xfreeGlobal (solutionXML) {
		xfree(xGlobal_parent(solutionXML), Global_ElementName);
	}
	// --------------------------------------------------------------
	function xGlobalSection_parent (solutionXML) {
		return xGlobal(solutionXML);
	}
	function xGlobalSection (solutionXML) {
		return xmlgetchild(xGlobal(solutionXML), GlobalSection_ElementName);
	}
	function xGlobalSectionOfType_WithIndex (solutionXML, type) {
		xmlforeachchild( xGlobalSection_parent(solutionXML), GlobalSection_ElementName, local resulter = [
			method @operator () (parent, childindex, globalSectionElement, ismany) {
				local keep_iterating = false;
				if (globalSectionElement.type == @type)
					@result = [ childindex, globalSectionElement ];
				else
					keep_iterating = true;
				return keep_iterating;
			},
			@type: type
		]);
		return resulter.result;
	}
	function xGlobalSectionOfType_parent (solutionXML) { // parent for GlobalSection-s of a specific type
		return xGlobalSection(solutionXML);
	}
	// --------------------------------------------------------------
	function xSolutionConfigurationPlatforms_parent (solutionXML) {
		return xGlobalSectionOfType_parent(solutionXML);
	}
	function xSolutionConfigurationPlatforms_WithIndex (solutionXML) {
		if (not local result = xGlobalSectionOfType_WithIndex(solutionXML, SolutionConfigurationPlatforms_TypeAttributeValue))
			E_NoSolutionConfigurationPlatformsElementFound(SolutionConfigurationPlatforms_TypeAttributeValue);
		return result;
	}
	function xSolutionConfigurationPlatforms (solutionXML) {
		local result = xSolutionConfigurationPlatforms_WithIndex(solutionXML);
		if (result)
			result = result[1];
		return result;
	}
	function xfreeSolutionConfigurationPlatforms (solutionXML) {
		local confPlatsAndKey = xSolutionConfigurationPlatforms_WithIndex(solutionXML);
		local key             = confPlatsAndKey[0];
		xfree(xSolutionConfigurationPlatforms_parent(solutionXML), key);
	}
	// --------------------------------------------------------------
	function xProjectConfigurationPlatforms_parent (solutionXML) {
		return xGlobalSectionOfType_parent(solutionXML);
	}
	function xProjectConfigurationPlatforms_WithIndex (solutionXML) {
		if (not local result = xGlobalSectionOfType_WithIndex(solutionXML, ProjectConfigurationPlatforms_TypeAttributeValue))
			E_NoProjectConfigurationPlatformsElementFound(ProjectConfigurationPlatforms_TypeAttributeValue);
		return result;
	}
	function xProjectConfigurationPlatforms (solutionXML) {
		local result = xProjectConfigurationPlatforms_WithIndex(solutionXML);
		if (result)
			result = result[1];
		return result;
	}
	function xfreeProjectConfigurationPlatforms (solutionXML) {
		local confPlatsAndKey = xProjectConfigurationPlatforms_WithIndex(solutionXML);
		local key             = confPlatsAndKey[0];
		xfree(xProjectConfigurationPlatforms_parent(solutionXML), key);
	}
	// --------------------------------------------------------------
	function xProject_parent (solutionXML) {
		return solutionXML;
	}
	function xProject (solutionXML) {
		return xmlgetchild(solutionXML, Project_ElementName);
	}
	function xfreeProject (solutionXML) {
		return xfree(solutionXML, Project_ElementName);
	}
	// --------------------------------------------------------------
	// ==============================================================
	
	
	
	/////////////////////////////////////////////////////////////////
	// XML data (pre)processing, filtering, trimming
	// --------------------------------------------------------------
	function trimGlobalSections (solutionXML, log) {
		if (std::isundefined(static interesting_global_section_types))
			interesting_global_section_types = [
					SolutionConfigurationPlatforms_TypeAttributeValue,
					ProjectConfigurationPlatforms_TypeAttributeValue];;
		
		xmlforeachchild(xGlobalSection_parent(solutionXML), GlobalSection_ElementName, [
			method UselessGlobalSectionTrimmer (parent, childindex, globalSectionElement, ismany) {
				u.Assert( xmlgetchild(parent, childindex) == globalSectionElement );
				u.Assert( childindex == GlobalSection_ElementName or (ismany and u.isdeltanumber(childindex)) );
				if ( not u.dobj_contains(interesting_global_section_types, globalSectionElement.type) ) {				
					u.Assert( not u.dobj_contains(interesting_global_section_types, xmlgetchild(parent, childindex).type) );
					@log("Deleting <GlobalSection> of type \"", globalSectionElement.type, "\"");
					xfree(parent, childindex);
				}
				return true; //keep iterating
			},
			@log: log
		].UselessGlobalSectionTrimmer);
	}
	// --------------------------------------------------------------
	function trimProjectSections (solutionXML, log) {
		if (std::isundefined(static uninteresting_project_section_types ))
			uninteresting_project_section_types = [
					WebsiteProperties_TypeAttributeValue,
					SolutionItems_TypeAttributeValue];
				
		xmlforeachchild(xProject_parent(solutionXML), Project_ElementName, [
			method NonBuildableProjectTrimmer (parent_solutionXML, childindex, child_project, ismany) {
				u.Assert( xmlgetchild(parent_solutionXML, childindex) == child_project );
				u.Assert( childindex == Project_ElementName or (ismany and u.isdeltanumber(childindex)) );
				if (local projsect = child_project[ProjectSection_ElementName]) {
					// if it has a ProjectSection, then...
					// ... foreach ProjectSection
					xmlforeachchild(child_project, ProjectSection_ElementName, [
						method @operator () (parent, childindex, child_projectSection, ismany) {
							u.Assert( xmlgetchild(parent, childindex) == child_projectSection );
							u.Assert( childindex == ProjectSection_ElementName or (ismany and u.isdeltanumber(childindex)) );
							u.Assert( child_projectSection.type );
							if ( u.dobj_contains(uninteresting_project_section_types, child_projectSection.type) ) {
								u.Assert( u.dobj_contains(uninteresting_project_section_types, xmlgetchild(parent, childindex).type) );
								// delete a "WebsiteProperties" or "SolutionItems" ProjectSection
								local proj = @proj;
								@log("Trimming <ProjectSection> of type \"", child_projectSection.type, "\" "
										"for project ", proj.name, ", ", proj.id, ", ", proj.path);
								xfree(parent, childindex);
							}
							return true;
						},
						@log  : @log,
						@proj : child_project
					]);
					
					// kill an alltogethere empty ProjectSection
					if (u.dobj_empty(projsect)) {
						@log("Deleting an all-together empty <ProjectSection>");
						xfree(child_project, ProjectSection_ElementName);
					}
				}

				return true;
			},
			@log: log
		].NonBuildableProjectTrimmer);
	}
	// --------------------------------------------------------------
	function trimFakeProjects (solutionXML, log) {
		xmlforeachchild(solutionXML, Project_ElementName, [
			method NonProjectProjectEntryRemover
				(parent, childindex, projelem, ismany)
			{
				local path = u.Path_castFromPath(projelem.path);
				if (path.Extension() != VCPROJ_Extension) {
					u.assert_eq( projelem.name , projelem.path );
					@l("Deleting nonProject project: ", projelem.name, ", ",
							projelem.id, ", ", projelem.path);
					xfree(parent, childindex);
				}
				return true; //keep iterating
			},
			@l: log
		].NonProjectProjectEntryRemover);
	}
	// --------------------------------------------------------------
	function trim (solutionXML) {
		local outer_log = log;
		local log = u.bindfront(outer_log, "Trimmer: ");
		
		
		// Remove useless "GlobalSection"s
		log("removing useless GlobalSection-s");
		trimGlobalSections(solutionXML, log);
		
		// Remove useless <ProjectSection type="WebsiteProperties"> from projects
		// foreach Project element
		log("removing \"WebsiteProperties\" ProjectSection-s");
		trimProjectSections(solutionXML, log);
		
		// Remove "project" entries which are not real projects but some
		// else and useless, like filtres and such.
		log("removing non-project Project-s");
		trimFakeProjects(solutionXML, log);
	}
	
	
	
	/////////////////////////////////////////////////////////////////
	// Data extraction from XML elements
	// --------------------------------------------------------------
	function dexSolutionConfigurations (solutionXML, log, configurationManager) {
		u.Assert( sd.ConfigurationManager_isaConfigurationManager(configurationManager) );
		local configurations_element = xSolutionConfigurationPlatforms(solutionXML);
		u.assert_eq( configurations_element.type , SolutionConfigurationPlatforms_TypeAttributeValue );
		xmlforeachchild(configurations_element, Pair_ElementName, [
			method @operator () (parent, childindex, pair, ismany) {
				u.assert_eq( pair.left , pair.right );
				@configurationAdder(local solconf = pair.right);
				@l("Adding solution configuration ", solconf);
				return true;
			},
			@configurationAdder: configurationManager.addConfiguration,
			@l: u.bindfront(log, "Solution Configuration Extractor: ")
		]);
		// Free this element
		xfreeSolutionConfigurationPlatforms(solutionXML);
	}
	function dexProjectsConfigurations (solutionXML, log, configurationManager) {
		u.Assert( sd.ConfigurationManager_isaConfigurationManager(configurationManager) );
		local configurations_XMLelement = xProjectConfigurationPlatforms(solutionXML);
		u.Assert( configurations_XMLelement.type == ProjectConfigurationPlatforms_TypeAttributeValue );
		xmlforeachchild(configurations_XMLelement, Pair_ElementName, [
			method @operator () (parent, childindex, pair_element, ismany) {
				local config_elems = u.strsplit(pair_element.left, ".", 0);
				local proj_config = pair_element.right;
				//
				local projid          = config_elems[0];
				local solution_config = config_elems[1];
				//
				function isEntryBuildable (config_elems) { return config_elems[2] == "Build" and config_elems[3] == "0"; }
				if (not @hasProject(solution_config, projid)) {
					// Should register project first
					@log("Registering project ", projid, ":", proj_config, " under solution configuration ", solution_config);
					@registerProject(solution_config, projid, proj_config);
				}
				if (isEntryBuildable(config_elems)) {
					@log("Marking ", projid, " as buildable under solution configuration ", solution_config);
					@markBuildable(solution_config, projid);
				}
				return true;
			},
			@registerProject     : configurationManager.registerProjectConfiguration,
			@log                 : u.bindfront(log, "Configuration Extractor: "),
			@hasProject          : configurationManager.hasProject,
			@markBuildable       : configurationManager.markBuildable
		]);
		// Free this element
		xfreeProjectConfigurationPlatforms(solutionXML);
		return true;
	}
	function dexProjectEntry (solutionXML, log, configurationManager, projectEntryHolder, addNonBuildables) {
		if ( not sd.ConfigurationManager_isaConfigurationManager(configurationManager) )
			u.error().AddError("Not a ConfigurationManager: ", configurationManager);
		else if ( not sd.ProjectEntryHolder_isaProjectEntryHolder(projectEntryHolder) )
			u.error().AddError("Not a ProjectEntryHolder: ", projectEntryHolder);
		else
			xmlforeachchild(xProject_parent(solutionXML), Project_ElementName, [
				method @operator () (parent, childindex, projectElement, ismany) {
					if (std::isundefined(static runcounter))
						runcounter = 1;
					else
						runcounter = runcounter;
					u.Assert( ismany ); // it is unlikely that we would have a solution with one project only
					@log("Analysing project data for /Project[", childindex, "]  (", runcounter++, "/",
						(function(parent, childindex, projectElement, ismany){if(ismany)return u.dobj_length(parent);else return(1);})
								(parent, childindex, projectElement, ismany), ")");
					//
					local id              = projectElement.id;
					local name            = projectElement.name;
					local parentReference = projectElement.parentref;
					local path            = projectElement.path;
					//
					if ((local buildable = @isBuildable(id)) or @addNonBuildables) {
						local projectEntry = sd.ProjectEntry().createInstance();
						projectEntry.setID(id);
						projectEntry.setName(name);
						projectEntry.setLocation(path);
						projectEntry.setParentReference(parentReference);
						//
						if (xmlhaschild(projectElement, ProjectSection_ElementName)) {
							// foreach ProjectSection (there should be only one, but is left over of many, so this is more conventient, as it abstracts whethere something is/was one or many)
							xmlforeachchild(projectElement, ProjectSection_ElementName, [
								method @operator () (parent, childindex, projectSectionElement, ismany) {
									// It has to be a project dependencies node
									u.assert_eq( projectSectionElement.type , ProjectDependencies_TypeAttributeValue );
									// foreach pair
									xmlforeachchild(projectSectionElement, Pair_ElementName, [
										method @operator () (parent, childindex, pairElement, ismany) {
											u.assert_eq( pairElement.left , pairElement.right );
											// add dependency
											@addDependency(pairElement.right);
											return true; // keep iterating
										},
										@addDependency: @addDependency
									]);
									
									return true; // keep iterating
								},
								@addDependency: projectEntry.addDependency
							]);

							// kill all ProjectSections
							xfree(projectElement, ProjectSection_ElementName);
						}
						// add project data to holder
						@holder.addProjectEntry(projectEntry);
						@log("Added " + (function(buildable){
							if (buildable) local result = ""; else result = " (non-buildable) ";
							return result;
						})(buildable) + "ProjectEntry ", projectEntry, " for ", id, ", ", name, ", ", path);
					}
					else  { // a non-buildable project has been encountered
						u.Assert( @isNonBuildable(id) );
						@log("Ignoring unbuildable project ", id, ", ", name, ", ", path);
					}
					
					// keep iterating
					return true;
				},
				@holder           : projectEntryHolder,
				@isBuildable      : configurationManager.isBuildableInAnyConfiguration,
				@isNonBuildable   : configurationManager.isNonBuildableInEveryConfiguration,
//				@hasProject       : configurationManager.hasProjectInAnyConfiguration,
				@log              : u.bindfront(log, "ProjectExtractor: "),
				@addNonBuildables : addNonBuildables
			]);
		
		xfreeProject(solutionXML);
	}
	
	
	// Data and holders
	local configurationManager = sd.ConfigurationManager().createInstance();
	local projectEntryHolder   = sd.ProjectEntryHolder().createInstance();
	// Trim and extract data
	trim(solutionXML);
	dexSolutionConfigurations(solutionXML, log, configurationManager);
	dexProjectsConfigurations(solutionXML, log, configurationManager);
	xfreeGlobal(solutionXML);
	dexProjectEntry(solutionXML, log, configurationManager, projectEntryHolder, (function addNonBuildables{return true;})());

	// return solution data
	return [
		@ConfigurationManager: configurationManager,
		@ProjectEntryHolder:   projectEntryHolder
	];
}


////////////////////////////////////////////////////////////////////////////////////
// Module Initialisation and clean up
////////////////////////////////////////////////////////////////////////////////////
init_helper = u.InitialisableModuleHelper("SolutionLoader", nil, nil);

function Initialise {
	return ::init_helper.Initialise();
}

function CleanUp {
	return ::init_helper.CleanUp();
}
////////////////////////////////////////////////////////////////////////////////////


