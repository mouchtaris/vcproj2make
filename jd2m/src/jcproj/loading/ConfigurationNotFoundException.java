package jcproj.loading;

public class ConfigurationNotFoundException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public ConfigurationNotFoundException (Throwable cause) {
		super(cause);
	}

	public ConfigurationNotFoundException (String message, Throwable cause) {
		super(message, cause);
	}

	public ConfigurationNotFoundException (String message) {
		super(message);
	}

	public ConfigurationNotFoundException () {
	}

	
}
