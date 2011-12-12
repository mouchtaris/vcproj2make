package jcproj.loading;

import java.util.Objects;
import jcproj.vcxproj.ProjectGuid;

/**
 *
 * Struct.
 * 
 * @date Sunday 7th August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class ProjectConfigurationEntry implements Cloneable {
    
    ///////////////////////////////////////////////////////
    
    public ProjectConfigurationEntry (
            final ProjectGuid   projectId,
            final String        relativePath)
    {
        id              = projectId;
        relpath         = relativePath;
    }
    
    ///////////////////////////////////////////////////////
    
    public ProjectGuid  GetProjectId ()         { return id         ; }
    public String       GetRelativePath ()      { return relpath    ; }
    public String       GetConfigurationId ()   { return configid   ; }
    public boolean      IsBuildable ()          { return buildable  ; }
    
    ///////////////////////////////////////////////////////
    
    public void SetConfigurationId (final String configurationId)   { assert configid == null; configid = configurationId; }
    public void SetBuildable ()                                     { assert !buildable; buildable = true; }
    
    ///////////////////////////////////////////////////////

    @Override
    public ProjectConfigurationEntry clone() {
        ProjectConfigurationEntry result = null;
        
        try
            { result = (ProjectConfigurationEntry) super.clone(); }
        catch (final CloneNotSupportedException ex)
            { assert false; }
        
        return result;
    }
    
    ///////////////////////////////////////////////////////
    
    @SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
    public ProjectConfigurationEntry clone (final String configurationId, final boolean buildable) {
        final ProjectConfigurationEntry result = clone();
        result.buildable = buildable;
        result.configid = configurationId;
        return result;
    }
    
    ///////////////////////////////////////////////////////
    
    @Override
    public String toString () {
        return "[" + id.toString() + ":" + configid + ":" + relpath + ":" + buildable + "]";
    }

    ///////////////////////////////////////////////////////
    
    @Override
    @SuppressWarnings("AccessingNonPublicFieldOfAnotherObject")
    public boolean equals (final Object obj) {
        boolean result = false;
        
        // remove netbeans warning
        if (false)
            Objects.equals(getClass(), obj.getClass());
        
        try {
            final ProjectConfigurationEntry other = ProjectConfigurationEntry.class.cast(obj);

            result =        Objects.equals(this.id, other.id)
                        &&  Objects.equals(this.configid, other.configid);
        }
        catch (final NullPointerException npex) {}
        catch (final ClassCastException ccex) {}

        return result;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 67 * hash + Objects.hashCode(this.id);
        hash = 67 * hash + Objects.hashCode(this.configid);
        return hash;
    }
    
    ///////////////////////////////////////////////////////
    // State
    private final ProjectGuid   id;
    private final String        relpath;
    private String              configid;
    private boolean             buildable;
} // class ProjectConfigurationEntry
