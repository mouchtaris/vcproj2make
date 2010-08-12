u = std::vmget("util");
assert( u );

function ProjectLoader_loadProject (projectPath, variableEvaluator) {
	if (local projectXML = u.xmlload(projectPath)) {
		u.println(projectXML);
	}
	else
		u.error().AddError("Could not load project file (XML) from ", projectPath);
}
