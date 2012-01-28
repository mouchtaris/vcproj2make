package jcproj.vcxproj.xml;

/**
 *
 * @date Monday 12th of December 2011
 * @author TURBO_X
 */
public class LibDefinition extends ItemDefinition {

	///////////////////////////////////////////////////////

	public String GetAdditionalLibraryDirectories () {
		return additionalLibraryDirectories;
	}

	///////////////////////////////////////////////////////

	public LibDefinition (
			final String	additionalLibraryDirectories)
	{
		this.additionalLibraryDirectories = additionalLibraryDirectories;
	}

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final String additionalLibraryDirectories;

} // class LibDefinition
