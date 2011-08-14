package jcproj.vcxproj.xml;

import jcproj.vcxproj.ProjectGuid;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 *
 * A Visual Studio 2010 Project.
 * 
 * @data Sunday 7th of August 2011
 * @author amalia
 */
public final class Project {

    ///////////////////////////////////////////////////////
    
    public void AddItemGroup (final Group<? extends Item> group) {
        assert !group.GetType().equals(ClInclude.class);
        assert !group.GetType().equals(ClCompile.class);
        
        final boolean added = itemgroups.add(group);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddPropertyGroup (final Group<? extends Property> group) {
        final boolean added = propertygroups.add(group);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddImport (final Import import_) {
        final boolean added = imports.add(import_);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddImportGroup (final Group<? extends Import> group) {
        final boolean added = importgroups.add(group);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddItemDefinitionGroup (final Group<? extends ItemDefinition> group) {
        final boolean added = itemdefinitiongroups.add(group);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddClCompile (final ClCompile clcompile) {
        final boolean added = clcompiles.add(clcompile);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddClInclude (final ClInclude clinclude) {
        final boolean added = clincludes.add(clinclude);
        assert added;
    }
    
    ///////////////////////////////////////////////////////
    
    public void AddProjectReference (final ProjectGuid projid, final String relpath) {
        final Object previous = references.put(projid, relpath);
        assert previous == null;
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final Set<Group<? extends Item>>            itemgroups              = new HashSet<>(5);
    private final Set<Group<? extends Property>>        propertygroups          = new HashSet<>(5);
    private final Set<Import>                           imports                 = new HashSet<>(5);
    private final Set<Group<? extends Import>>          importgroups            = new HashSet<>(5);
    private final Set<Group<? extends ItemDefinition>>  itemdefinitiongroups    = new HashSet<>(5);
    private final Set<ClInclude>                        clincludes              = new HashSet<>(5);
    private final Set<ClCompile>                        clcompiles              = new HashSet<>(5);
    private final Map<ProjectGuid, String>              references              = new HashMap<>(5);
    
} // class Project
