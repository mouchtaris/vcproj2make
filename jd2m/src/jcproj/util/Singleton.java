package jcproj.util;

public abstract class Singleton<T> {
	
	///////////////////////////////////////////////////////
	// state
	private final Class<? extends T> subclass;
	
	///////////////////////////////////////////////////////
	//
	/**
	 * Make a direct state-equality check. No null or class equivalence checks
	 * required.
	 * 
	 * @param other cannot be null.
	 * @return 
	 */
	public abstract boolean Equals (final T other);
	/**
	 * Do not call {@link #hasCode}. It relies on this method.
	 * @return 
	 */
	protected abstract int HashCode ();
	
	///////////////////////////////////////////////////////
	// Refining Object
	@Override
	public boolean equals (final Object other) {
		final boolean equals = other != null && getClass().equals(other.getClass()) && Equals(subclass.cast(other));
		assert !equals || super.equals(other);
		assert !equals || hashCode() == other.hashCode();
		return equals;
	}

	@Override
	public int hashCode () {
		return HashCode();
	}
	
	///////////////////////////////////////////////////////
	// Protected
	///////////////////////////////////////////////////////
	
	///////////////////////////////////////////////////////
	// Constructors
	protected Singleton (final Class<? extends T> subclass) {
		this.subclass = subclass;
	}
}
