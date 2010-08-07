// Get util library
u = std::vmget("util");
sd = std::vmget("SolutionData");
if (not u or not sd)
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
	function xmlismultiple (element) {
		// only mutiple elements will have arithmetic indeces.
		// Arithmetic indeces have no way of being produced from
		// normal XML parsing.
		return u.isdeltanumber(u.dobj_keys( element )[0]);
	}
	function xmlchildismultiple (parent, childindex) {
		return xmlismultiple(xmlgetchild(parent, childindex));
	}
	// f(parent, childindex, child, childismany) => keep_iterating
	function xmlforeachchild (parent, childindex, f) {
		if (local childismultiple = xmlchildismultiple(parent, childindex)) {
			foreach (local key, u.dobj_keys(local children = xmlgetchild(parent, childindex)))
				if (not f(children, key, children[key], childismultiple))
					break;
		}
		else
			f(parent, childindex, parent[childindex], childismultiple);
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
		return xmlgetchild(xGlobal_parent(solutionXML), Global_ElementName);
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
		local parent = nil;
		local globalSectionElement = xGlobalSection(solutionXML);
		if (xmlismultiple(globalSectionElement))
			parent = globalSectionElement;
		else
			parent = xGlobalSection_parent(solutionXML);
		return parent;
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

	

	/////////////////////////////////////////////////////////////////
	// report generation
	// --------------------------------------------------------------
	function generateReport (outer_log, configurationManager, projectEntryHolder) {
		const report_file_path = "SolutionLoaderReport.xhtml";
		local log = u.bindfront(outer_log, "ReportGenerator: ");
		if ( local fh = std::fileopen(report_file_path, "wt") ) {
			log("Generating results report...");
			
			local append = [ 
				method @operator () (str) {
					std::filewrite(@outf, str);
				},
				@buf: "",
				@outf: fh,
				@log: log
			];
			local conclude = [
				method @operator () { std::filewrite(@outfile, @appender.buf); },
				@outfile: fh,
				@appender: append
			];
			local isBuildable = configurationManager.isBuildable;
			
			append("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
		\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">

	<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
				<head>
					<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
					<style type=\"text/css\" media=\"all\">
/*<![CDATA[*/
					body {
						background-color: #000000;
						font-family: \"verdana\", \"deja-vu sans\", sans-serif;
						font-size: 11px;
						color: #c0c0c0;
						text-wrap: unrestricted;
					}
					table {
						position: relative;
						width: 60%;
						max-width: 60%;
						left: 20%;
						border: 3px double #303030;
						border-collapse: collapse;
						background-color: #101010;
						margin: 2em 0 2em 0;
					}
					td, th {
						padding: .3em;
					}
					thead th {
						border-color: #505050;
						background-color: #301010;
					}
					.separator th, .separator td {
						border-top: 5px double #303030;
					}
					.buildable {
						background-color: #101810;
					}
					.projname {
						letter-spacing: .2em;
					}
					.projid {
						font-family: monospace;
					}
					.infopost_buildable, .infopost_id, .infopost_path, .infopost_deps, .infopost_rdeps {
						color: #a0a0a0;
						font-size: .85em;
						border-left: 1px solid #303030;
						text-align: right;
					}
					.infopost_buildable, .infopost_id, .infopost_path, .infopost_deps,
					.projid, .projpath, .projbuildable, .projdeps {
						border-bottom: 1px dotted #303030;
					}
					.buildable .projname, .nonbuildable .projname, .projdep_buildable, .projdep_nonbuildable  {
						padding-left: 20px;
						background-position: left center;
						background-repeat: no-repeat;
					}
					.buildable .projname, .projdep_buildable {
						background-image: url('resources/icons/icon16_tick.png');
					}
					.nonbuildable .projname {
						background-image: url('resources/icons/icon-minus (1).png');
					}
					
					.projdep_buildable {
						color: #a0c0a0;
					}
					
					.projdep_nonbuildable {
						color: #f00000;
						background-image: url('resources/icons/iconExclamation.png');
						font-weight: bold;
					}
					
					a.projdep_buildable, a.projdep_nonbuildable {
						text-decoration: none;
					}
					a.projdep_buildable:hover, a.projdep_nonbuildable:hover {
						text-decoration: underline;
					}
/*]]>*/
					</style>
					<title></title>
				</head><body>");
			foreach (local conf, configurationManager.Configurations()) {
				log("Adding results for solution configuration: ", conf);
				//
				append("<table summary=\"projects for configuration ");
				append(conf);
				append("\"><thead><tr><th colspan=\"3\">");
				append(conf);
				append("</th></tr></thead><tbody>");
				local projectsIDs = configurationManager.Projects(conf);
				foreach (local projid, projectsIDs) {
					log("adding info for project ", projid);
					//
					function idescape(str) {
						return 
							u.strgsub(
								u.strgsub(
									u.strgsub(
										u.strgsub(
											u.strgsub(
												u.strgsub(str, "\"", "&quot;"),
												" ",
												"_"),
											"{",
											"_"),
										"}",
										"_"),
									"-",
									"_"),
								"|",
								"_")
						;
					}
					function makeprojhtmlid (conf, projid) {
						return idescape(conf) + "_" + idescape(projid);
					}
					local projectEntry = projectEntryHolder.getProjectEntry(projid);
					local buildable = isBuildable(conf, projid);
					local trclass = (function (buildable) {
							local trclass = nil;
							if ( buildable )
								trclass = "buildable";
							else
								trclass = "nonbuildable";
							return trclass;
					})(buildable);
					local tr = "<tr class=\"" + trclass + "\">";
					local projname = projectEntry.getName();
					local projhtmlid = makeprojhtmlid(conf, projid);
					append("<tr class=\"");
					append(trclass);
					append(" separator\"><th class=\"projname\" rowspan=\"5\" id=\"" +
							projhtmlid + "\">");
					append(projname);
					append("</th><td class=\"infopost_id\">ID:</td><td class=\"projid\">");
					append(projectEntry.getID());
					append("</td></tr>");
					append(tr);
					append("<td class=\"infopost_path\">Path:</td><td class=\"projpath\">");
					append(projectEntry.getLocation().deltaString());
					append("</td></tr>");
					append(tr);
					append("<td class=\"infopost_buildable\">Buildable:</td><td class=\"projbuildable\">");
					append(buildable);
					append("</td></tr>");
					append(tr);
					append("<td class=\"infopost_deps\">Depends on:</td><td class=\"projdeps\">");
					//
					function appendDep (append, depid, makeprojhtmlid, isBuildable, conf, getProjectEntry) {
						local buildable = isBuildable(conf, depid);
						local depentry = getProjectEntry(depid);
						local class = "projdep_" + u.ternary(buildable, "buildable", "nonbuildable");
						append("<a class=\"");
						append(class);
						append("\" href=\"#" + makeprojhtmlid(conf, depid) + "\">");
						append(depentry.getName());
						append("</a>");
					}
					local comma = "";
					foreach (local depid, projectEntry.Dependencies()) {
						append(comma);
						appendDep(append, depid, makeprojhtmlid, isBuildable, conf, projectEntryHolder.getProjectEntry);
						comma = ", ";
					}
					append("</td></tr>");
					append(tr);
					append("<td class=\"infopost_rdeps\">R-Depend:</td><td class=\"projrdeps\">");
					function dependsOn (projentryHolder, projid, rdepid) {
						return u.iterable_contains(
							projentryHolder.getProjectEntry(rdepid).Dependencies(),
							projid);
					}
					comma = "";
					foreach (local rdepid, configurationManager.Projects(conf))
						if ( dependsOn(projectEntryHolder, projid, rdepid) ) {
							append(comma);
							appendDep(append, rdepid, makeprojhtmlid, isBuildable, conf, projectEntryHolder.getProjectEntry);
							comma = ", ";
						}
					append("</td></tr>");
				}
				append("</tbody></table>");
			}
			append("</body></html>");
			
			conclude();		}
		else
			log("Could not open ", report_file_path, " for writing");
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
	generateReport(log, configurationManager, projectEntryHolder);
	

	// return solution data
	return [
		@ConfigurationManager: configurationManager,
		@ProjectEntryHolder:   projectEntryHolder
	];
}

