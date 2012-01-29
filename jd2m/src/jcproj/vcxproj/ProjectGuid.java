package jcproj.vcxproj;

import java.util.Objects;
import jcproj.util.Identifiable;
import jcproj.util.Singleton;

/**
 *
 *
 * @data Monday 8th of August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class ProjectGuid extends Singleton<ProjectGuid> implements Identifiable<String> {

	///////////////////////////////////////////////////////
	// Public fields

	public static final byte ID_LENGTH = 38;

	///////////////////////////////////////////////////////

	@Override
	public String toString () {
		return string;
	}

	///////////////////////////////////////////////////////

	@Override
	public String GetId () {
		return id;
	}

	///////////////////////////////////////////////////////

	@SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
	@Override
	public boolean Equals (final ProjectGuid other) {
		return other != null
				&& Objects.equals(A, other.A)
				&& Objects.equals(B, other.B)
				&& Objects.equals(C, other.C)
				&& Objects.equals(D, other.D)
				&& Objects.equals(E, other.E);
	}
	
	@Override
	protected int HashCode () {
		int hash = 3;
		hash = 97 * hash + (int) (A ^ (A >>> 32));
		hash = 97 * hash + B;
		hash = 97 * hash + C;
		hash = 97 * hash + D;
		hash = 97 * hash + (int) (E ^ (E >>> 32));
		return hash;
	}

	///////////////////////////////////////////////////////
	// Static utils

	public static boolean IsValid (final String value) {
		//		"{F6459465-11D4-4CFD-99B9-5D8BDC5B598C}"
		boolean b0 = value.length()					== ID_LENGTH;
		boolean b1 = value.charAt(0)				== '{';
		boolean b2 = value.charAt(ID_LENGTH - 1)	== '}';
		boolean b3 = value.charAt(9)				== '-';
		boolean b4 = value.charAt(14)				== '-';
		boolean b5 = value.charAt(19)				== '-';
		boolean b6 = value.charAt(24)				== '-';
		return b0 && b1 && b2 && b3 && b4 && b5 && b6;
	}

	public static String NormaliseId (final String id) {
		return Parse(id).GetId();
	}

	///////////////////////////////////////////////////////
	///////////////////////////////////////////////////////
	// Package private

	///////////////////////////////////////////////////////

	static ProjectGuid Parse (final String str) {
		assert IsValid(str);

		final long	a	= Long		.parseLong(str.substring( 1,  9), 0x10);
		final int	b	= Integer	.parseInt (str.substring(10, 14), 0x10);
		final int	c	= Integer	.parseInt (str.substring(15, 19), 0x10);
		final int	d	= Integer	.parseInt (str.substring(20, 24), 0x10);
		final long	e	= Long		.parseLong(str.substring(25, 37), 0x10);

		return new ProjectGuid(a, b, c, d, e);
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
	// precomputed
	private final String string;
	private final String id;

	///////////////////////////////////////////////////////
	// private static utils

	private ProjectGuid (final long a, final int b, final int c, final int d, final long e) {
		super(ProjectGuid.class);
		A = a;
		B = b;
		C = c;
		D = d;
		E = e;
		id = String.format("{%08x-%04x-%04x-%04x-%012x}", A, B, C, D, E);
		string = "ProjectGuid[" + id + "]";
	}
} // class ProjectGuid
