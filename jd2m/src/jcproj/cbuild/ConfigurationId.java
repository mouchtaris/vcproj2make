package jcproj.cbuild;

import jcproj.util.Identifiable;
import jcproj.util.Patterns;

public class ConfigurationId implements Identifiable<String> {
	///////////////////////////////////////////////////////
	// state
	private final String build;
	private final String platform;
	// precomputed
	private final String id;

	///////////////////////////////////////////////////////
	// constructors
	private ConfigurationId (final String build, final String platform, final String id) {
		this.id			= id;
		this.build		= build;
		this.platform	= platform;
	}

	///////////////////////////////////////////////////////
	//
	public String GetBuild () {
		return build;
	}

	public String GetPlatform () {
		return platform;
	}

	@Override
	public String GetId () {
		return id;
	}

	///////////////////////////////////////////////////////
	//
	public static boolean IsValidBuildDescriptor (final String build) {
		for (final char c: build.toCharArray())
			if (!(Character.isLetter(c) || c == '_'))
				return false;
		return true;
	}

	public static boolean IsValidPlatformDescriptor (final String platform) {
		for (final char c: platform.toCharArray())
			if (!Character.isLetterOrDigit(c))
				return false;
		return true;
	}

	///////////////////////////////////////////////////////
	//
	public static String IdOf (final String build, final String platform) {
		EnsureValidBuildAndPlatformDescriptors(build, platform);
		return build + "|" + platform;
	}

	private static String[] IdToBuildPlatformAndId (final String id) {
		final String[] buildAndPlatform = Patterns.Pipe().split(id);
		final String build = buildAndPlatform[0];
		final String platform = buildAndPlatform[1];
		final String idGenerated = IdOf(build, platform);

		assert idGenerated.equals(id);
		return new String[] {build, platform, idGenerated};
	}

	public static ConfigurationId FromId (final String id) {
		final String[] parts = IdToBuildPlatformAndId(id);
		return new ConfigurationId(parts[0], parts[1], parts[2]);
	}

	public static String ParseToId (final String string) {
		return IdToBuildPlatformAndId(string)[2];
	}

	public static ConfigurationId Parse (final String string) {
		return FromId(string);
	}

	///////////////////////////////////////////////////////
	// Object
	@Override
	@SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
	public boolean equals (Object obj) {
		if (obj == null) {
			return false;
		}
		if (getClass() != obj.getClass()) {
			return false;
		}
		final ConfigurationId other = (ConfigurationId) obj;
		if ((this.build == null) ? (other.build != null) : !this.build.equals(other.build)) {
			return false;
		}
		if ((this.platform == null) ? (other.platform != null) : !this.platform.equals(other.platform)) {
			return false;
		}
		return true;
	}

	@Override
	public int hashCode () {
		int hash = 3;
		hash = 53 * hash + (this.build != null ? this.build.hashCode() : 0);
		hash = 53 * hash + (this.platform != null ? this.platform.hashCode() : 0);
		return hash;
	}

	@Override
	public String toString () {
		return "ConfigurationId[" + build + ", " + platform + "]";
	}

	///////////////////////////////////////////////////////
	// Private
	///////////////////////////////////////////////////////
	private static void EnsureValidBuildAndPlatformDescriptors (final String build, final String platform) {
		if (!IsValidBuildDescriptor(build))
			throw new IllegalArgumentException("build:" + build);
		if (!IsValidPlatformDescriptor(platform))
			throw new IllegalArgumentException("platform:" + platform);
	}
}
