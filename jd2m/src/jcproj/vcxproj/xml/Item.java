package jcproj.vcxproj.xml;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class Item extends Element {

	///////////////////////////////////////////////////////

	public String GetInclude () {
		return include;
	}

	///////////////////////////////////////////////////////

	protected Item (final String include) {
		this.include = include;
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final String include;

} // class Item
