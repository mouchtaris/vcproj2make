package jcproj.vcxproj.xml;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import jcproj.util.FilteringIterable;
import jcproj.util.HashSet;
import jcproj.util.Predicate;
import jcproj.vcxproj.ProjectGuid;

/**
 *
 * A Visual Studio 2010 Project.
 *
 * @data Sunday 7th of August 2011
 * @author amalia
 */
@SuppressWarnings("FinalClass")
public final class Project {

	///////////////////////////////////////////////////////

	public void AddItemGroup (final Group<? extends Item> group) {
		assert !group.GetType().equals(ClInclude.class);
		assert !group.GetType().equals(ClCompile.class);

		final boolean added = itemgroups.add(group);
		assert added;
	}

	///////////////////////////////////////////////////////

	public void AddPropertyGroup (final Group<Property> group) {
		final boolean added = propertygroups.contains(group)?
				propertygroups.add(propertygroups.pop(group).Merge(group)):
				propertygroups.add(group);
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

	public Iterable<Group<? extends Import>> GetImportGroup (final String label) {
		return new FilteringIterable<Group<? extends Import>>(
				Collections.unmodifiableSet(importgroups),
				new Predicate<Group<? extends Import>>() {
					@Override
					public boolean HoldsFor (final Group<? extends Import> something) {
						return something.GetLabel().equals(label);
					}
				});
	}

	///////////////////////////////////////////////////////

	///////////////////////////////////////////////////////
	// Private

	///////////////////////////////////////////////////////
	// State
	private final HashSet<Group<? extends Item>>			itemgroups				= new HashSet<Group<? extends Item>>(5);
	private final HashSet<Group<Property>>					propertygroups			= new HashSet<Group<Property>>(5);
	private final HashSet<Import>							imports					= new HashSet<Import>(5);
	private final HashSet<Group<? extends Import>>			importgroups			= new HashSet<Group<? extends Import>>(5);
	private final HashSet<Group<? extends ItemDefinition>>	itemdefinitiongroups	= new HashSet<Group<? extends ItemDefinition>>(5);
	private final HashSet<ClInclude>						clincludes				= new HashSet<ClInclude>(5);
	private final HashSet<ClCompile>						clcompiles				= new HashSet<ClCompile>(5);
	private final Map<ProjectGuid, String>					references				= new HashMap<ProjectGuid, String>(5);

} // class Project
