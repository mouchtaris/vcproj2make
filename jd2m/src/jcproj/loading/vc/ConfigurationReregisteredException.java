package jcproj.loading.vc;

public class ConfigurationReregisteredException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public ConfigurationReregisteredException (Throwable cause) {
		super(cause);
	}

	public ConfigurationReregisteredException (String message, Throwable cause) {
		super(message, cause);
	}

	public ConfigurationReregisteredException (String message) {
		super(message);
	}

	public ConfigurationReregisteredException () {
	}


}