package jcproj.loading.vc.xml;

public class XmlWalkingException extends Exception {
	private static final long serialVersionUID = 28L;

	public XmlWalkingException (final org.w3c.dom.Node context, final org.w3c.dom.Node unknown) {
		this(context, "Unidentified node \"" + unknown + "\" encounted");
	}

	public XmlWalkingException (final org.w3c.dom.Node context, final String msg) {
		super(Context(context) + msg);
	}

	public XmlWalkingException (final org.w3c.dom.Node context, final Throwable cause) {
		super(Context(context), cause);
	}

	private static String Context (final org.w3c.dom.Node context) {
		return jcproj.util.xml.XmlTreeVisitor.NodePath(context);
	}
}
