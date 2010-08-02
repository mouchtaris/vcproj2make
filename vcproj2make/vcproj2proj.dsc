util = std::vmget(#util);
if (not util) {
	util = std::vmload("util.dbc", #util);
	std::vmrun(util);
}
assert( util );

function xmlload (filename_str) {
	return ::util.xmlload(filename_str);
}
// Should only be called if xmlload returns falsy
function xmlloaderror {
	local error_message = ::util.xmlloaderror();
	if ( not error_message )
		::util.error().AddError("No error message returned from XML loader");
	return error_message;
}

///////////// TODO temporary code, for reference //////////////////////
function{
// Adaptors to CProject and CSolution
// --------------------
// They create CProject and CSolution instances from 
// Visual Studio projects and Solutions


function VisualStudioProjectAdaptor (vcproj_filepath_str) {
	local vcproj_data = xmlload(vcproj_filepath_str);
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

function CSolutionFromVCSolution (solutionFilePath_str, solutionName) {
	
	/////////////////////////////////////////////////////////////////
	/////////////////////////// Classes /////////////////////////////
	/////////////////////////////////////////////////////////////////
	
	function SolutionData {
		if (std::isundefined(static SolutionData_stateFields))
			SolutionData_stateFields = [ #SolutionData_configurations, #SolutionData_configurationMapper ];

		if (std::isundefined(static SolutionData_class))
			SolutionData_class = ::util.Class().createInstance(
				// stateInitialiser
				function SolutionData_stateInitialiser (new, validFieldsNames) {
					::util.Class_checkedStateInitialisation(
						new,
						validFieldsNames,
						[
							@SolutionData_configurations     : [], //self map
							@SolutionData_configurationMapper: []
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
						local mapper = ::util.dobj_checked_get(self, SolutionData_stateFields, #SolutionData_configurationMapper);
						if ( not (local configurationProjects = mapper[solutionConfigurationID]) )
							configurationProjects = mapper[solutionConfigurationID] = [];
						::util.Assert( not ::util.dobj_contains_key(configurationProjects, projectID) );
						configurationProjects[projectID] = projectConfigurationID;
					}
				],
				// mixinRequirements
				[],
				// state field names
				[ #SolutionData_configurations, #SolutionData_configurationMapper ],
				// class name
				#SolutionData
			);

		return SolutionData_class;
	}
	function SolutionData_isaSolutionData (obj) {
		return ::util.Class_isa(obj, SolutionData());
	}
	
	// ProjectData
	function ProjectData_validProjectID (id) {
		return // some heuristics
				::util.isdeltastring(id)            and
				::util.strlength(id) == (52-15+1)   and
				::util.strchar(id, 0) == "{"        and
				::util.strchar(id, ::util.strlength(id) - 1) == "}" and
		true;
	}
	function ProjectData {
		if (std::isundefined(static ProjectData_stateFields))
			ProjectData_stateFields = [ #ProjectData_parentReference ];
		
		if (std::isundefined(static ProjectData_class)) {
			ProjectData_class = ::util.Class().createInstance(
				// stateInitialiser
				function ProjectData_stateInitialiser (new, validFieldsNames) {
					::util.Class_checkedStateInitialisation(new, validFieldsNames,
						[ { #ProjectData_parentReference: "" } ]);
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
	function ProjectData_isaProjectData (obj) {
		return ::util.Class_isa(obj, ProjectData());
	}
	
	/////////////////////////////////////////////////////////////////
	/////////////////// Rest of the world ///////////////////////////
	/////////////////////////////////////////////////////////////////
	
	function loadSolutionDataFromSolutionFile (solutionFilePath_str) {
		::util.assert_str( solutionFilePath_str );
		local data = xmlload(solutionFilePath_str);
		if (not data)
			::util.error().AddError(::xmlloaderror());
		return data;
	}
	
	/////////////////////////////////////////////////////////////////
	// Various constants
	// --------------------------------------------------------------
	const Global_ElementName                                = "Global";
	const GlobalSection_ElementName                         = "GlobalSection";
	const SolutionConfigurationPlatforms_TypeAttributeValue = "SolutionConfigurationPlatforms";
	//
	const ProjectConfigurationPlatforms_TypeAttributeValue  = "ProjectConfigurationPlatforms";
	const Project_ElementName                               = "Project";
	const ProjectSection_ElementName                        = "ProjectSection";
	//
	const WebsiteProperties_TypeAttributeValue              = "WebsiteProperties";

	
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
		local keys_to_die = std::list_new();
		local interesting_global_section_types = [
				SolutionConfigurationPlatforms_TypeAttributeValue,
				ProjectConfigurationPlatforms_TypeAttributeValue];
		// Remove useless "GlobalSection"s
		foreach (local key, ::util.dobj_keys(local gsects = solutionXML.Global.GlobalSection)) {
			local gsect = gsects[key];
			if ( not ::util.dobj_contains(interesting_global_section_types, gsect.type) )
				gsects[key] = nil;
		}
		// Remove useless <ProjectSection type="WebsiteProperties"> from projects
		// foreach Project element
		xmlforeachchild(solutionXML, Project_ElementName, function(parent_solutionXML, childindex, child_project, ismany) {
			::util.Assert( parent_solutionXML[childindex] == child_project );
			::util.Assert( childindex == Project_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
			if (local projsect = child_project[ProjectSection_ElementName])
				// if it has a ProjectSection, then...
				// ... foreach ProjectSection
				xmlforeachchild(child_project, ProjectSection_ElementName, function(parent, childindex, child_projectSection, ismany) {
					::util.Assert( parent[childindex] == child_projectSection );
					::util.Assert( childindex == ProjectSection_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
					::util.Assert( child_projectSection.type );
					if (child_projectSection.type == WebsiteProperties_TypeAttributeValue)
						// delete a "WebsiteProperties" ProjectSection
						parent[childindex] = nil;
					return true;
				});
				return true;
		});
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
		return xmlgetchild(xGlobal(solutionXML), GlobalSection_ElementName);
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

	/////////////////////////////////////////////////////////////////
	// Data extraction from XML elements
	// --------------------------------------------------------------
	function dexSolutionConfigurations (solutionXML, solutionConfigurations) {
		::util.Assert( SolutionData_isaSolutionData(solutionConfigurations) );
		local configurations_element = xSolutionConfigurationPlatforms(solutionXML);
		::util.Assert( configurations_element.type == SolutionConfigurationPlatforms_TypeAttributeValue );
		foreach (local pair, configurations_element.Pair) {
			::util.Assert( pair.left == pair.right );
			solutionConfigurations.addConfiguration(pair.right);
		}
		// Free this element
		xfreeSolutionConfigurationPlatforms(solutionXML);
	}
	function dexProjectsConfigurations (solutionXML, solutionConfigurations) {
		::util.Assert( SolutionData_isaSolutionData(solutionConfigurations) );
		local configurations_XMLelement = xProjectConfigurationPlatforms(solutionXML);
		::util.Assert( configurations_XMLelement.type == ProjectConfigurationPlatforms_TypeAttributeValue );
		foreach (local pair, configurations_XMLelement.Pair) {
			local config_elems = ::util.strsplit(pair.left, ".", 0);
			local proj_config = pair.right;
			function isBuildable (config_elems) { return config_elems[2] == "Build" and config_elems[3] == "0"; }
			if (isBuildable(config_elems)) {
				//
				local projid          = config_elems[0];
				local solution_config = config_elems[1];
				//
				solutionConfigurations.registerProjectConfigurationForConfiguration(solution_config, projid, proj_config);
			}
		}
		// Free this element
		xfreeProjectConfigurationPlatforms(solutionXML);
		return true;
	}
	function dexProjectData (solutionXML, projectDataHolder) {
		
	}
	
	local result = nil;
	::util.assert_str( solutionFilePath_str );
	::util.assert_str( solutionName );
	
	if (not local solutionXML = loadSolutionDataFromSolutionFile(solutionFilePath_str))
		return nil;
	
	// Data and holders
	local solutionData       = SolutionData().createInstance();
	local projectDataHolder  = [];
	
	// Test code
	xppRemoveUninterestingFields(solutionXML);
	dexSolutionConfigurations(solutionXML, solutionData);
	dexProjectsConfigurations(solutionXML, solutionData);
	xfreeGlobal(solutionXML);
	
	
	return result = solutionXML;
}