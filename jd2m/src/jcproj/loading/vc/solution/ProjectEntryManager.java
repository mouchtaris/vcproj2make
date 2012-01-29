package jcproj.loading.vc.solution;

import jcproj.util.InstanceManager;
import jcproj.vcxproj.ProjectGuid;

public class ProjectEntryManager extends InstanceManager<ProjectGuid, ProjectEntry> {

	public ProjectEntryManager () {
		super(100);
	}
}
