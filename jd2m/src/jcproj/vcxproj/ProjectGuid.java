package jcproj.vcxproj;

import java.util.Formatter;
import java.util.Objects;

/**
 *
 *
 * @data Monday 8th of August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class ProjectGuid {

	///////////////////////////////////////////////////////

	@Override
	public String toString () {
		sb.delete(0, sb.length());
		f.format("{%08x-%04x-%04x-%04x-%012x}", A, B, C, D, E);
		f.flush();
		return sb.toString();
	}

	///////////////////////////////////////////////////////

	@SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
	public boolean Equals (final ProjectGuid other) {
		return other != null
				&& Objects.equals(A, other.A)
				&& Objects.equals(B, other.B)
				&& Objects.equals(C, other.C)
				&& Objects.equals(D, other.D)
				&& Objects.equals(E, other.E);
	}

	///////////////////////////////////////////////////////

	@Override
	public boolean equals (final Object o) {
		// based on the assumption that only the factory creates instances:
		// Equals(other) => equals(other)
		assert !(getClass().equals(o.getClass()) && Equals((ProjectGuid) o)) || super.equals(o);
		return super.equals(o);
	}

	///////////////////////////////////////////////////////

	@Override
	public int hashCode () {
		int hash = 3;
		hash = 97 * hash + (int) (A ^ (A >>> 32));
		hash = 97 * hash + B;
		hash = 97 * hash + C;
		hash = 97 * hash + D;
		hash = 97 * hash + (int) (E ^ (E >>> 32));
		return hash;
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	///////////////////////////////////////////////////////
	// Package private

	///////////////////////////////////////////////////////

	ProjectGuid (long a, int b, int c, int d, long e) {
		A = a;
		B = b;
		C = c;
		D = d;
		E = e;
	}

	///////////////////////////////////////////////////////
	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final long	A;
	private final int	B;
	private final int	C;
	private final int	D;
	private final long	E;

	///////////////////////////////////////////////////////
	// Static utils
	private final static StringBuilder	sb	= new StringBuilder(1 << 18); //256KiB
	private final static Formatter		f	= new Formatter(sb);
} // class ProjectGuid
