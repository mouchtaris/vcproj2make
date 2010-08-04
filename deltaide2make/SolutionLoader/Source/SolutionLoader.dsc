// Get util library
u = std::vmget("util");
assert( u );

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
		return u.toboolean(parent[childindex]);
	}
	function xmlgetchildwithindex (parent, childindex) {
		return [ childindex, xmlgetchild(parent, childindex) ];
	}
	function xmlismultiple (element) {
		// only mutiple elements will have arithmetic indeces.
		// Arithmetic indeces have no way of being produced from
		// normal XML parsing.
		return u.isdeltanumber(u.dobj_keys( element )[0])
	}
	function xmlchildismultiple (parent, childindex) {
		return xmlismultiple(xmlgetchild(parent, childindex));
	}
	// f(parent, childindex, child, childismany) => keep_iterating
	function xmlforeachchild (parent, childindex, f) {
		if (local childismultiple = xmlchildismultiple(parent, childindex)) {
			foreach (local key, ::util.dobj_keys(local children = xmlgetchild(parent, childindex)))
				if (not f(children, key, children[key], childismultiple))
					break;
		}
		else
			f(parent, childindex, parent[childindex], childismultiple);
	}
	
	
	
	/////////////////////////////////////////////////////////////////
	// Utilities for abstracted and quick access to standard XPATHs
	// --------------------------------------------------------------
	function xfree (parent, childindex) {
		::util.Assert( xmlgetchild(parent, childindex) == parent[childindex] );
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
	function trimGlobalSections (solutionXML) {
		if (std::isundefined(static interesting_global_section_types))
			interesting_global_section_types = [
					SolutionConfigurationPlatforms_TypeAttributeValue,
					ProjectConfigurationPlatforms_TypeAttributeValue];;
		
		xmlforeachchild(xGlobalSection_parent(solutionXML), GlobalSection_ElementName, function UselessGlobalSectionTrimmer (parent, childindex, globalSectionElement, ismany) {
			u.Assert( xmlgetchild(parent, childindex) == globalSectionElement );
			u.Assert( childindex == GlobalSection_ElementName or (ismany and u.isdeltanumber(childindex)) );
			if ( not u.dobj_contains(interesting_global_section_types, globalSectionElement.type) ) {				
				u.Assert( not u.dobj_contains(interesting_global_section_types, xmlgetchild(parent, childindex).type) );
				xfree(parent, childindex);
			}
			return true; //keep iterating
		});
	}
	// --------------------------------------------------------------
	function trimNonBuildableProject (solutionXML) {
		if (std::isundefined(static uninteresting_project_section_types ))
			uninteresting_project_section_types = [
					WebsiteProperties_TypeAttributeValue,
					SolutionItems_TypeAttributeValue];
				
		xmlforeachchild(xProject_parent(solutionXML), Project_ElementName, function NonBuildableProjectTrimmer (parent_solutionXML, childindex, child_project, ismany) {
			::util.Assert( xmlgetchild(parent_solutionXML, childindex) == child_project );
			::util.Assert( childindex == Project_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
			if (local projsect = xmlgetchild(child_project, ProjectSection_ElementName)) {
				// if it has a ProjectSection, then...
				// ... foreach ProjectSection
				xmlforeachchild(child_project, ProjectSection_ElementName, function(parent, childindex, child_projectSection, ismany) {
					::util.Assert( xmlgetchild(parent, childindex) == child_projectSection );
					::util.Assert( childindex == ProjectSection_ElementName or (ismany and ::util.isdeltanumber(childindex)) );
					::util.Assert( child_projectSection.type );
					if ( u.dobj_contains(uninteresting_project_section_types, child_projectSection.type) ) {
						u.Assert( u.dobj_contains(uninteresting_project_section_types, xmlgetchild(parent, childindex).type) );
						// delete a "WebsiteProperties" or "SolutionItems" ProjectSection
						xfree(parent, childindex);
					}
					return true;
				});
				
				// kill an alltogethere empty ProjectSection
				if (::util.dobj_empty(projsect))
					xfree(child_project, ProjectSection_ElementName);
			}

			return true;
		});
	}
	// --------------------------------------------------------------
	function trim (solutionXML) {
		local outer_log = log;
		local log = [method@operator()(...){@l("Trimmer: ",...);},@l:outer_log];
		
		
		// Remove useless "GlobalSection"s
		log("removing useless GlobalSection-s");
		trimGlobalSections(solutionXML);
		
		// Remove useless <ProjectSection type="WebsiteProperties"> from projects
		// foreach Project element
		log("removing \"WebsiteProperties\" ProjectSection-s");
		trimNonBuildableProject(solutionXML);
		
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
}

