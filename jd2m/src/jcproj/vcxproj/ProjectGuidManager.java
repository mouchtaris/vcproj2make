package jcproj.vcxproj;

import jcproj.util.InstanceManager;

/**
 *
 *
 * @data Monday 8th of August 2011
 * @author amalia
 */
public class ProjectGuidManager extends InstanceManager<String, ProjectGuid> {
	
	///////////////////////////////////////////////////////
	
	public ProjectGuidManager () {
		super(100);
	}

	///////////////////////////////////////////////////////

	public ProjectGuid Create (final String str) {
		final ProjectGuid projid = ProjectGuid.Parse(str);
		return Register(projid);
	}

	///////////////////////////////////////////////////////
	// Overriding
	@Override
	public boolean Has (final String id) {
		return super.Has(ProjectGuid.NormaliseId(id));
	}

	@Override
	public ProjectGuid Get (final String id) {
		return super.Get(ProjectGuid.NormaliseId(id));
	}

} // class ProjectGuidFactory
