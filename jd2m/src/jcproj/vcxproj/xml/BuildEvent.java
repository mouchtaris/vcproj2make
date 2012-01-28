package jcproj.vcxproj.xml;

/**
 * @date 2011-12-18
 * @author TURBO_X
 */
public class BuildEvent extends ItemDefinition {

	///////////////////////////////////////////////////////
	// state
	private final String command;

	///////////////////////////////////////////////////////
	// constructors
	public BuildEvent (final String command) {
		this.command = command;
	}

	///////////////////////////////////////////////////////
	//
	public String GetCommand () {
		return command;
	}

}
