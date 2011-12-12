package jcproj.vcxproj.xml;

import java.util.LinkedList;
import java.util.List;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class ClCompile extends Item {
    
    ///////////////////////////////////////////////////////
    
    public List<String> GetExcludeFromBuildConditions () {
        return excludeFromBuildConditions;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddExcludeFromBuildCondition (final String condition) {
        excludeFromBuildConditions.add(condition);
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddPrecompiledHeaderCreationCondition (final String condition) {
        final boolean added = precompiledHeaderCreationConditions.add(condition);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public ClCompile (final String include) {
        super(include);
    }
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    
    private final List<String>  excludeFromBuildConditions          = new LinkedList<String>();
    private final List<String>  precompiledHeaderCreationConditions = new LinkedList<String>();
    
} // class ClCompile
