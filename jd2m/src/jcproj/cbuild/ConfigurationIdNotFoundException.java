package jcproj.cbuild;

public class ConfigurationIdNotFoundException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public ConfigurationIdNotFoundException () {
	}

	public ConfigurationIdNotFoundException (final String msg) {
		super(msg);
	}
	
	public ConfigurationIdNotFoundException (final String msg, final Throwable cause) {
		super(msg, cause);
	}
}
