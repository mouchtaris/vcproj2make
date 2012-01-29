package jcproj.util;

public class InstanceAlreadyRegisteredException extends RuntimeException {
	private static final long serialVersionUID = 1L;

	public InstanceAlreadyRegisteredException () {
	}

	public InstanceAlreadyRegisteredException (final String msg) {
		super(msg);
	}

	public InstanceAlreadyRegisteredException (final String msg, final Throwable cause) {
		super(msg, cause);
	}
}
