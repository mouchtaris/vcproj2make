package jcproj.util;

public class InstanceNotFoundException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public InstanceNotFoundException () {
	}

	public InstanceNotFoundException (final String msg) {
		super(msg);
	}

	public InstanceNotFoundException (final String msg, final Throwable cause) {
		super(msg, cause);
	}
}
