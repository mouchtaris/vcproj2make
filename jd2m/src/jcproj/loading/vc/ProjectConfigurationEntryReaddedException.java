package jcproj.loading.vc;

public class ProjectConfigurationEntryReaddedException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public ProjectConfigurationEntryReaddedException (Throwable cause) {
		super(cause);
	}

	public ProjectConfigurationEntryReaddedException (String message, Throwable cause) {
		super(message, cause);
	}

	public ProjectConfigurationEntryReaddedException (String message) {
		super(message);
	}

	public ProjectConfigurationEntryReaddedException () {
	}


}
