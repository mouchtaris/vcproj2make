package jcproj.vcxproj.xml;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class ProjectReference extends Item {

	///////////////////////////////////////////////////////

	public String GetProject () {
		return project;
	}

	///////////////////////////////////////////////////////

	public ProjectReference (final String include, final String project) {
		super(include);
		this.project = project;
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	final String project;

} // class ProjectReference
