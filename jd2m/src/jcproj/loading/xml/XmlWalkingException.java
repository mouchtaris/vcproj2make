package jcproj.loading.xml;

public class XmlWalkingException extends Exception {
	private static final long serialVersionUID = 28L;
	
	public XmlWalkingException (final org.w3c.dom.Node context, final org.w3c.dom.Node unknown) {
		super("Unidentified node \"" + unknown + "\" encounted while in \""
				+ context + "\"");
	}
}
