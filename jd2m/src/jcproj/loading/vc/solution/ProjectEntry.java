package jcproj.loading.vc.solution;

import jcproj.util.Identifiable;
import jcproj.util.Singleton;
import jcproj.vcxproj.ProjectGuid;

/**
 *
 * Struct.
 *
 * @date Sunday 7th August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class ProjectEntry extends Singleton<ProjectEntry> implements Identifiable<ProjectGuid> {

	///////////////////////////////////////////////////////

	public ProjectEntry (
			final ProjectGuid	projectId,
			final String		relativePath)
	{
		super(ProjectEntry.class);
		id				= projectId;
		relpath			= relativePath;
	}

	///////////////////////////////////////////////////////

	public String			GetRelativePath ()		{ return relpath	; }

	///////////////////////////////////////////////////////
	
	@SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
	@Override // Singleton
	public boolean Equals (final ProjectEntry other) {
		return id.equals(other.id) && relpath.equals(other.relpath);
	}
	
	@Override // Singleton
	protected int HashCode () {
		int hash = 7;
		hash = 11 * hash + (this.id != null ? this.id.hashCode() : 0);
		hash = 11 * hash + (this.relpath != null ? this.relpath.hashCode() : 0);
		return hash;
	}
	
	///////////////////////////////////////////////////////
	
	@Override // Identifiable
	public ProjectGuid GetId () {
		return id;
	}

	///////////////////////////////////////////////////////

	@Override
	public String toString () {
		return "ProjectConfigurationEntry[" + id.toString() + ":" + relpath + "]";
	}

	///////////////////////////////////////////////////////
	// State
	private final ProjectGuid	id;
	private final String		relpath;
} // class ProjectConfigurationEntry
