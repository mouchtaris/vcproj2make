util = std::vmget(#util);
if (not util) {
	util = std::vmload("util.dbc", #util);
	std::vmrun(util);
}
assert( util );

// UTIL adaptors
util.xmlload = util.XMLload;

function myxmlload (filename_str) {
	return ::util.xmlload(filename_str);
}
// Should only be called if xmlload returns falsy
function xmlloaderror {
	local error_message = ::util.XMLloaderror();
	if ( not error_message )
		::util.error().AddError("No error message returned from XML loader");
	return error_message;
}

function log(...) {
	::util.println("[VCPROJ2PROJ]: ", ...);
}

///////////// TODO temporary code, for reference //////////////////////
function{
// Adaptors to CProject and CSolution
// --------------------
// They create CProject and CSolution instances from 
// Visual Studio projects and Solutions


function VisualStudioProjectAdaptor (vcproj_filepath_str) {
	local vcproj_data = ::myxmlload(vcproj_filepath_str);
	local vcproj_loaderror = ::xmlloaderror();
	if (vcproj_data) {
		::util.Assert( not vcproj_loaderror );
		::util.println( ::util.dobj_keys(vcproj_data) );
	}
	else {
		::util.Assert( vcproj_loaderror );
		::util.p(vcproj_loaderror);
	}
}
///////////////////////////////////////////////////////////////////////
}



// TODO add magic numbers and check for them
function CSolutionFromVCSolution (solutionFilePath_str, solutionName) {
	
	/////////////////////////////////////////////////////////////////
	/////////////////////////// Classes /////////////////////////////
	/////////////////////////////////////////////////////////////////
	
	// Forward static members of ProjectData
	function ProjectData_validProjectID (id) {
		return // some heuristics
				::util.isdeltastring(id)            and
				::util.strlength(id) == (52-15+1)   and
				::util.strchar(id, 0) == "{"        and
				::util.strchar(id, ::util.strlength(id) - 1) == "}" and
		true;
	}
	
	// SolutionData
	function SolutionData {
		if (std::isundefined(static SolutionData_stateFields))
			SolutionData_stateFields = [ #SolutionData_configurations, #SolutionData_configurationMapper, #SolutionData_nonbuildables ];

		// Private methods
		function getnonbuildables (this) {
			return ::util.dobj_checked_get(this, SolutionData_stateFields, #SolutionData_nonbuildables);
		}
		function getsolutionmapper (this) {
			return ::util.dobj_checked_get(this, SolutionData_stateFields, #SolutionData_configurationMapper);
		}
		function isbuildable (this, projid) {
			::util.assert_str(projid);
			local solutionMapper = getsolutionmapper(this);
			foreach (local configurationMapper, solutionMapper)
				foreach (local projectID, ::util.dobj_keys(configurationMapper))
					if (::util.assert_str(projectID) == projid)
						return true;
			return false;
		}
		
		if (std::isundefined(static SolutionData_class))
			SolutionData_class = ::util.Class().createInstance(
				// stateInitialiser
				function SolutionData_stateInitialiser (new, validFieldsNames) {
					::util.Class_checkedStateInitialisation(
						new,
						validFieldsNames,
						[
							@SolutionData_configurations     : [], //self map
							@SolutionData_configurationMapper: [],
							@SolutionData_nonbuildables      : []  //self map
						]
					);
				},
				// prototype
				[
					method addConfiguration (configurationID) {
						::util.assert_str(configurationID);
						local configs = ::util.dobj_checked_get(self, SolutionData_stateFields, #SolutionData_configurations);
						::util.Assert( ::util.isdeltanil(configs[configurationID]) );
						configs[configurationID] = configurationID;
					},
					method hasConfiguration (configurationID) {
						return not not ::util.dobj_checked_get(self, SolutionData_stateFields, #SolutionData_configurations)[configurationID];
					},
					method registerProjectConfigurationForConfiguration (solutionConfigurationID, projectID, projectConfigurationID) {
						::util.assert_str(solutionConfigurationID);
						::util.assert_str(projectID);
						::util.assert_str(projectConfigurationID);
						::util.Assert( self.hasConfiguration(solutionConfigurationID) );
						local mapper = getsolutionmapper(self);
						if ( not (local configurationProjects = mapper[solutionConfigurationID]) )
							configurationProjects = mapper[solutionConfigurationID] = [];
						::util.Assert( not ::util.dobj_contains_key(configurationProjects, projectID) );
						configurationProjects[projectID] = projectConfigurationID;
						//
						::util.Assert( isbuildable(self, projectID) );
					},
					method addNonBuildable (projID) {
						::util.Assert( ProjectData_validProjectID(projID) );
						::util.Assert( not isbuildable(self, projID) );
						local nonbuildables = getnonbuildables(self);
						::util.Assert( not ::util.dobj_contains_key(nonbuildables, projID) );
						nonbuildables[projID] = projID;
					},
					method isNonBuildable (projID) {
						::util.Assert( ProjectData_validProjectID(projID) );
						local nonbuildables = getnonbuildables(self);
						local result = ::util.dobj_contains_key(nonbuildables, projID);
						// it is not necessary that a non-buildable project will have
						// been registered as a buildable one
						// (because of virtual folders (filters) etc
						// TODO re-enable this assertion after trimming out
						// virtual folders and such
						//::util.assert_eq( result, not isbuildable(self, projID) );
						return result;
					},
					method isBuildable (projID) {
						local result = not self.isNonBuildable(projID);
						return result;
					}
				],
				// mixinRequirements
				[],
				// state field names
				[ #SolutionData_configurations, #SolutionData_configurationMapper, #SolutionData_nonbuildables ],
				// class name
				#SolutionData
			);

		return SolutionData_class;
	}
	function SolutionData_isaSolutionData (obj) {
		return ::util.Class_isa(obj, SolutionData());
	}
	
	// ProjectData
	function classy_ProjectData {
		if (std::isundefined(static ProjectData_stateFields))
			ProjectData_stateFields = [ #ProjectData_parentReference, #ProjectData_dependencies ];
		
		if (std::isundefined(static ProjectData_class)) {
			// private methods
			function deps(projdata) {
				return ::util.dobj_checked_get(projdata, ProjectData_stateFields, #ProjectData_dependencies);
			}
			
			ProjectData_class = ::util.Class().createInstance(
				// stateInitialiser
				function ProjectData_stateInitialiser (new, validFieldsNames) {
					::util.Class_checkedStateInitialisation(new, validFieldsNames,
						[
							{ #ProjectData_parentReference: ""              },
							{ #ProjectData_dependencies   : std::list_new() }
						]);
				},
				// prototype
				[
					method setParentReference (parentID) {
						::util.assert_str( parentID );
						return ::util.dobj_checked_set(self, ProjectData_stateFields, #ProjectData_parentReference, parentID);
					},
					method getParentReference {
						local result = ::util.dobj_checked_get(self, ProjectData_stateFields, #ProjectData_parentReference);
						return result;
					},
					method addDependency (projID) {
						::util.Assert( ProjectData_validProjectID(projID) );
						local dops = deps(self);
						local deps = dops;
						::util.Assert( not ::util.iterable_contains(deps, projID) );
						std::list_push_back(deps, projID);
					},
					method Dependencies {
						return ::util.list_clone(deps(self));
					}
				],
				// mixInRequirements
				[],
				// stateFields
				ProjectData_stateFields,
				// class name
				#ProjectData
			);
			
			if (std::isundefined(static mixinsInstancesStateInitialisersArgumentsFunctors)) {
				mixinsInstancesStateInitialisersArgumentsFunctors = [
					@Namable  : lambda {["__noname__"]},
					@IDable   : lambda {["__noID__"  ]},
					@Locatable: lambda {["__nopath__"]}
				];
			}
			else
				mixinsInstancesStateInitialisersArgumentsFunctors=mixinsInstancesStateInitialisersArgumentsFunctors;
			// Mix-ins
			ProjectData_class.mixIn(::util.Namable  (), mixinsInstancesStateInitialisersArgumentsFunctors.Namable   );
			ProjectData_class.mixIn(::util.IDable   (), mixinsInstancesStateInitialisersArgumentsFunctors.IDable    );
			ProjectData_class.mixIn(::util.Locatable(), mixinsInstancesStateInitialisersArgumentsFunctors.Locatable );
		}
		return ProjectData_class;
	}
	function light_ProjectData {
		if (std::isundefined(static ProjectData_class))
			ProjectData_class = [
				@createInstance: function createInstance {
					return [
						method setName(name) { @name = name; },
						method setID  (id)   { @id = id; },
						method setParentReference(pr) { @pr = pr; },
						method setLocation(path) { @path = path; },
						method addDependency(projID) { @deps.push_back(projID); },
						@deps: std::list_new(),
						method getName { return @name; },
						method getID { return @id; },
						method getParentReference { return @pr; },
						method Dependencies { return ::util.list_clone(@deps); }
					];
				}
			];
		return ProjectData_class;
	}
	function ProjectData { return
//			light_ProjectData
			classy_ProjectData
		();
	}
	function ProjectData_isaProjectData (obj) {
		return ::util.Class_isa(obj, ProjectData());
	}
	
	/////////////////////////////////////////////////////////////////
	/////////////////// Rest of the world ///////////////////////////
	/////////////////////////////////////////////////////////////////
	
	function loadSolutionDataFromSolutionFile (solutionFilePath_str) {
		::util.assert_str( solutionFilePath_str );
		local data = ::myxmlload(solutionFilePath_str);
		if (not data)
			::util.error().AddError(::xmlloaderror());
		return data;
	}
	
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
	// Errors, error messages, error reporting
	// --------------------------------------------------------------
	function E_NoSolutionConfigurationPlatformsElementFound (SolConfPlats) {
		::util.error().AddError("No /Global/GlobalSection/ with type=\"" + SolConfPlats + "\"");
	}
	function E_NoProjectConfigurationPlatformsElementFound (ProjConfPlats) {
		::util.error().AddError("No /Global/GlobalSection/ with type=\"" + ProjConfPlats + "\"");
	}
	
	/////////////////////////////////////////////////////////////////
	// Utilities for XML nodes
	// --------------------------------------------------------------
	function xmlgetchild (parent, childindex) {
		::util.Assert( parent );
		::util.assert_def( childindex );
		local child = parent[childindex];
		::util.Assert( child );
		return child;
	}
	function xmlhaschild (parent, childindex) {
		return not not parent[childindex];
	}
	function xmlgetchildwithindex (parent, childindex) {
		return [ childindex, xmlgetchild(parent, childindex) ];
	}
	function xmlchildismany (parent, childindex) {
		// only mutiple children will have arithmetic indeces.
		// Arithmetic indeces have no way of being produced from
		// normal XML parsing.
		return ::util.isdeltanumber(::util.dobj_keys(parent[childindex])[0]);
	}
	// f(parent, childindex, child, childismany) => keep_iterating
	function xmlforeachchild (parent, childindex, f) {
		if (local childismany = xmlchildismany(parent, childindex)) {
			foreach (local key, ::util.dobj_keys(local children = parent[childindex]))
				if (not f(children, key, children[key], childismany))
					break;
		}
		else
			f(parent, childindex, parent[childindex], childismany);
	}

	/////////////////////////////////////////////////////////////////
	// XML data (pre)processing
	// --------------------------------------------------------------
	function xppRemoveUninterestingFields (solutionXML) {
		local outer_log = log;
		local log = [method@operator()(...){@l("Trimmer: ",...);},@l:outer_log];
		//
		local keys_to_die = std::list_new();
		local interesting_global_section_types = [
				SolutionConfigurationPlatforms_TypeAttributeValue,
				ProjectConfigurationPlatforms_TypeAttributeValue];
		// Remove useless "GlobalSection"s
		log("removing useless GlobalSection-s");
		foreach (local key, ::util.dobj_keys(local gsects = solutionXML.Global[0].GlobalSection)) {
			local gsect = gsects[key];
			if ( not ::util.dobj_contains(interesting_global_section_types, gsect.type) )
				gsects[key] = nil;
		}
		// Remove useless <ProjectSection type="WebsiteProperties"> from projects
		// foreach Project element
		log("removing \"WebsiteProperties\" ProjectSection-s");
		xmlforeachchild(solutionXML, Project_ElementName, function(parent_solutionXML, childindex, child_project, ismany) {
			::util.Assert( parent_solutionXML[childindex] == child_project );
			::util.Assert( childindex == Project_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
			if (local projsect = child_project[ProjectSection_ElementName]) {
				// if it has a ProjectSection, then...
				// ... foreach ProjectSection
				xmlforeachchild(child_project, ProjectSection_ElementName, function(parent, childindex, child_projectSection, ismany) {
					::util.Assert( parent[childindex] == child_projectSection );
					::util.Assert( childindex == ProjectSection_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
					::util.Assert( child_projectSection.type );
					if (
						child_projectSection.type == WebsiteProperties_TypeAttributeValue or
						child_projectSection.type == SolutionItems_TypeAttributeValue
					)
						// delete a "WebsiteProperties" or "SolutionItems" ProjectSection
						parent[childindex] = nil;
					return true;
				});
				
				// kill an alltogethere empty ProjectSection
				if (::util.dobj_empty(projsect))
					child_project[ProjectSection_ElementName] = nil;
			}

			return true;
		});
		
		// Remove "project" entries which are not real projects but some
		// else and useless, like filtres and such.
		log("removing non-project Project-s");
		xmlforeachchild(solutionXML, Project_ElementName, [
			method NonProjectProjectEntryRemover
				(parent, childindex, projelem, ismany)
			{
				local path = ::util.Path_castFromPath(projelem.path);
				if (path.Extension() != VCPROJ_Extension) {
					::util.assert_eq( projelem.name , projelem.path );
					@l("Deleting nonProject project: ", projelem.name, ", ",
							projelem.id, ", ", projelem.path);
					parent[childindex] = nil;
				}
				return true; //keep iterating
			},
			{"()": @self.NonProjectProjectEntryRemover},
			@l: log
		]);
	}
	
	/////////////////////////////////////////////////////////////////
	// Utilities for quick access to standard XPATHs
	// --------------------------------------------------------------
	function xfree (parent, childindex) {
		::util.Assert( xmlgetchild(parent, childindex) == parent[childindex] );
		parent[childindex] = nil;
	}
	function xGlobal (solutionXML) {
		return xmlgetchild(solutionXML, Global_ElementName);
	}
	function xfreeGlobal (solutionXML) {
		xfree(solutionXML, Global_ElementName);
	}
	function xGlobalSection (solutionXML) {
		local subchild = xmlgetchild(xGlobal(solutionXML), 0);
		local result = xmlgetchild(subchild, GlobalSection_ElementName);
		return result;
	}
	function xGlobalSectionOfTypeWithElementName (solutionXML, type) {
		foreach (local key, ::util.dobj_keys(local xGlobalSections = xGlobalSection(solutionXML))) {
			local xGlobalSection = xGlobalSections[key];
			if (xGlobalSection.type == type)
				return [ key, xGlobalSection ];
		}
		return nil;
	}
	//
	function xSolutionConfigurationPlatforms_parent (solutionXML) {
		return xGlobalSection(solutionXML);
	}
	function xSolutionConfigurationPlatformsWithElementName (solutionXML) {
		if (not local result = xGlobalSectionOfTypeWithElementName(solutionXML, SolutionConfigurationPlatforms_TypeAttributeValue))
			E_NoSolutionConfigurationPlatformsElementFound(SolutionConfigurationPlatforms_TypeAttributeValue);
		return result;
	}
	function xSolutionConfigurationPlatforms (solutionXML) {
		local result = xSolutionConfigurationPlatformsWithElementName(solutionXML);
		if (result)
			result = result[1];
		return result;
	}
	function xfreeSolutionConfigurationPlatforms (solutionXML) {
		local confPlatsAndKey = xSolutionConfigurationPlatformsWithElementName(solutionXML);
		local key             = confPlatsAndKey[0];
		xfree(xSolutionConfigurationPlatforms_parent(solutionXML), key);
	}
	//
	function xProjectConfigurationPlatforms_parent (solutionXML) {
		return xGlobalSection(solutionXML);
	}
	function xProjectConfigurationPlatformsWithElementName (solutionXML) {
		if (not local result = xGlobalSectionOfTypeWithElementName(solutionXML, ProjectConfigurationPlatforms_TypeAttributeValue))
			E_NoProjectConfigurationPlatformsElementFound(ProjectConfigurationPlatforms_TypeAttributeValue);
		return result;
	}
	function xProjectConfigurationPlatforms (solutionXML) {
		local result = xProjectConfigurationPlatformsWithElementName(solutionXML);
		if (result)
			result = result[1];
		return result;
	}
	function xfreeProjectConfigurationPlatforms (solutionXML) {
		local confPlatsAndKey = xProjectConfigurationPlatformsWithElementName(solutionXML);
		local key             = confPlatsAndKey[0];
		xfree(xProjectConfigurationPlatforms_parent(solutionXML), key);
	}
	//
	function xProject_parent (solutionXML) {
		return solutionXML;
	}
	function xProject (solutionXML) {
		return xmlgetchild(solutionXML, Project_ElementName);
	}
	function xfreeProject (solutionXML) {
		return xfree(solutionXML, Project_ElementName);
	}

	/////////////////////////////////////////////////////////////////
	// Data extraction from XML elements
	// --------------------------------------------------------------
	function dexSolutionConfigurations (solutionXML, solutionConfigurations) {
		::util.Assert( SolutionData_isaSolutionData(solutionConfigurations) );
		local configurations_element = xSolutionConfigurationPlatforms(solutionXML);
		::util.Assert( configurations_element.type == SolutionConfigurationPlatforms_TypeAttributeValue );
		xmlforeachchild(configurations_element, Pair_ElementName, [
			method @operator () (parent, childindex, pair, ismany) {
				::util.Assert( pair.left == pair.right );
				@configurationAdder(pair.right);
				return true;
			},
			@configurationAdder: solutionConfigurations.addConfiguration
		]);
		// Free this element
		xfreeSolutionConfigurationPlatforms(solutionXML);
	}
	function dexProjectsConfigurations (solutionXML, solutionConfigurations) {
		::util.Assert( SolutionData_isaSolutionData(solutionConfigurations) );
		local configurations_XMLelement = xProjectConfigurationPlatforms(solutionXML);
		::util.Assert( configurations_XMLelement.type == ProjectConfigurationPlatforms_TypeAttributeValue );
		xmlforeachchild(configurations_XMLelement, Pair_ElementName, [
			method @operator () (parent, childindex, pair_element, ismany) {
				local config_elems = ::util.strsplit(pair_element.left, ".", 0);
				local proj_config = pair_element.right;
				//
				local projid          = config_elems[0];
				local solution_config = config_elems[1];
				//
				function isBuildable (config_elems) { return config_elems[2] == "Build" and config_elems[3] == "0"; }
				if (isBuildable(config_elems))
					@solutionConfigurations.registerProjectConfigurationForConfiguration(solution_config, projid, proj_config);
				else {
					@solutionConfigurations.addNonBuildable(projid); // TODO think about storing the rest of the info
					::log("notice: project configured not to be built: ID=", projid);
				}
			},
			@solutionConfigurations: solutionConfigurations
		]);
		// Free this element
		xfreeProjectConfigurationPlatforms(solutionXML);
		return true;
	}
	function dexProjectData (solutionXML, solutionData, projectDataHolder) {
		xmlforeachchild(xProject_parent(solutionXML), Project_ElementName, [
			method @operator () (parent, childindex, projectElement, ismany) {
				if (std::isundefined(static runcounter)) runcounter = 1; else runcounter = runcounter;
				::util.Assert( ismany ); // it is unlikely that we would have a solution with one project only
				::log("Analysing project data for /Project[", childindex, "]  (", runcounter++, "/",
					(function(parent, childindex, projectElement, ismany){if(ismany)return::util.dobj_length(parent);else return(1);})
							(parent, childindex, projectElement, ismany), ")");
				//
				local id              = projectElement.id;
				local name            = projectElement.name;
				local parentReference = projectElement.parentref;
				local path            = projectElement.path;
				//
				::util.assert_str(id);
				::util.assert_str(name);
				::util.assert_str(path);
				::util.assert_str(parentReference);
				//
				local solutionData = @solutionData;
				if (solutionData.isBuildable(id)) {
					local projectData = ProjectData().createInstance();
					projectData.setID(id);
					projectData.setName(name);
					projectData.setLocation(path);
					projectData.setParentReference(parentReference);
					//
					if (xmlhaschild(projectElement, ProjectSection_ElementName)) {
						// foreach ProjectSection (there should be only one, but is left over of many, so this is more conventient, as it abstracts whethere something is/was one or many)
						xmlforeachchild(projectElement, ProjectSection_ElementName, [
							method @operator () (parent, childindex, projectSectionElement, ismany) {
								// It has to be a project dependencies node
								::util.assert_eq( projectSectionElement.type , ProjectDependencies_TypeAttributeValue );
								// foreach pair
								xmlforeachchild(projectSectionElement, Pair_ElementName, [
									method @operator () (parent, childindex, pairElement, ismany) {
										::util.assert_eq( pairElement.left , pairElement.right );
										// add dependency
										@dependencyAdder(pairElement.right);
										return true; // keep iterating
									},
									@dependencyAdder: @projectData.addDependency
								]);
								
								return true; // keep iterating
							},
							@projectData: projectData
						]);

						// kill all ProjectSections
						xfree(projectElement, ProjectSection_ElementName);
					}
					// add project data to holder
					@holder[id] = projectData;
				}
				else // a non-buildable project has been encountered
					::log("Ignoring unbuildable project ", id, ", ", name, ", ", path);
				
				// keep iterating
				return true;
			},
			@holder      : projectDataHolder,
			@solutionData: solutionData
		]);
		
		xfreeProject(solutionXML);
	}
	
	local result = nil;
	::util.assert_str( solutionFilePath_str );
	::util.assert_str( solutionName );
	
	if (not local solutionXML = loadSolutionDataFromSolutionFile(solutionFilePath_str))
		return nil;
	
	// Data and holders
	local solutionData       = SolutionData().createInstance();
	local projectDataHolder  = [];
	// Trim and extract data
	xppRemoveUninterestingFields(solutionXML);
	dexSolutionConfigurations(solutionXML, solutionData);
	dexProjectsConfigurations(solutionXML, solutionData);
	xfreeGlobal(solutionXML);
	dexProjectData(solutionXML, solutionData, projectDataHolder);
	
	
	return result = solutionXML;
}
