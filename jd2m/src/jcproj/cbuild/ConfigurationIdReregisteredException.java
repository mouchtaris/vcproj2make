package jcproj.cbuild;

public class ConfigurationIdReregisteredException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public ConfigurationIdReregisteredException () {
	}

	public ConfigurationIdReregisteredException (final String msg) {
		super(msg);
	}
	
	public ConfigurationIdReregisteredException (final String msg, final Throwable cause) {
		super(msg, cause);
	}
}
