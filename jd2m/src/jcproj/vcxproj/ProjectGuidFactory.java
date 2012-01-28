package jcproj.vcxproj;

import java.util.Comparator;
import java.util.Map;
import java.util.TreeMap;

/**
 *
 * 
 * @data Monday 8th of August 2011
 * @author amalia
 */
public class ProjectGuidFactory { // TODO desingletonify
	
	///////////////////////////////////////////////////////
	// Public fields
	
	public static final byte ID_LENGTH = 38;
	
	///////////////////////////////////////////////////////
	// Singleton
	
	public static void SingletonCreate () {
		assert instance == null;
		instance = new ProjectGuidFactory();
	}
	
	///////////////////////////////////////////////////////
	
	public static ProjectGuidFactory GetSingleton () {
		assert instance != null;
		return instance;
	}
	
	///////////////////////////////////////////////////////
	
	public static void SingletonDestroy () {
		assert instance != null;
		instance = null;
	}
	
	///////////////////////////////////////////////////////
	
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
	
	///////////////////////////////////////////////////////
	
	public ProjectGuid Create (final String str) {
		final ProjectGuid projid = ParseProjectGuid(str);
		
		assert projid.toString().equalsIgnoreCase(str);
		assert ParseProjectGuid(projid.toString()).Equals(projid);
		assert ParseProjectGuid(projid.toString()).toString().equals(projid.toString());
		
		final ProjectGuid previous = projids.put(str, projid);
		assert previous == null;
		return projid;
	}
	
	///////////////////////////////////////////////////////
	
	public ProjectGuid Get (final String str) {
		final ProjectGuid result = projids.containsKey(str)? projids.get(str) : null;
		assert result != null;
		return result;
	}
	
	///////////////////////////////////////////////////////
	// Private
	
	private ProjectGuidFactory () {}
	
	///////////////////////////////////////////////////////
	
	private ProjectGuid ParseProjectGuid (final String str) {
		assert IsValid(str);
		
		final long  a   = Long   .parseLong(str.substring( 1,  9), 0x10);
		final int   b   = Integer.parseInt (str.substring(10, 14), 0x10);
		final int   c   = Integer.parseInt (str.substring(15, 19), 0x10);
		final int   d   = Integer.parseInt (str.substring(20, 24), 0x10);
		final long  e   = Long   .parseLong(str.substring(25, 37), 0x10);
		
		return new ProjectGuid(a, b, c, d, e);
	}
	
	///////////////////////////////////////////////////////
	
	///////////////////////////////////////////////////////
	// String-Key No-case Comparator 
	private class NoCaseStringComparator implements Comparator<String> {
		@Override
		public int compare (final String o1, final String o2) {
			return o1.compareToIgnoreCase(o2);
		}
	}
	
	///////////////////////////////////////////////////////
	// State
	private final Map<String, ProjectGuid> projids = new TreeMap<String, ProjectGuid>(new NoCaseStringComparator());
	
	///////////////////////////////////////////////////////
	// Singleton
	private static ProjectGuidFactory   instance;
	
} // class ProjectGuidFactory
