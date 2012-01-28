package jcproj.vcxproj.xml;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class LinkDefinition extends ItemDefinition {

	///////////////////////////////////////////////////////

	public String GetSubSystem () {
		return subSystem;
	}

	///////////////////////////////////////////////////////

	public String GetGenerateDebugInformation () {
		return generateDebugInformation;
	}

	///////////////////////////////////////////////////////

	public String GetAdditionalDependencies () {
		return additionalDependencies;
	}

	///////////////////////////////////////////////////////

	public LinkDefinition(
			final String	subSystem,
			final String	generateDebugInformation,
			final String	additionalDependencies) {
		this.subSystem					= subSystem;
		this.generateDebugInformation	= generateDebugInformation;
		this.additionalDependencies	 = additionalDependencies;
	}

	///////////////////////////////////////////////////////


	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final String subSystem;
	private final String generateDebugInformation;
	private final String additionalDependencies;

} // class Link
