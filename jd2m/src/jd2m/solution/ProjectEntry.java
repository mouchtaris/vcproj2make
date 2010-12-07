package jd2m.solution;

import java.io.File;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Identifiable;
import jd2m.util.ProjectId;
import jd2m.util.Locatable;
import jd2m.util.Namable;
import jd2m.util.Name;

public final class ProjectEntry implements
    Identifiable,
    Namable,
    Locatable
{

    private final ProjectId         _identity;
    private final ProjectId         _parentRefId;
    private final Name              _name;
    private final File              _location;
    private final List<ProjectId>   _dependencies = new LinkedList<>();
    private ProjectEntry (  final ProjectId identity,
                            final Name      name,
                            final File      location,
                            final ProjectId parentRefId)
    {
        _identity       = identity;
        _parentRefId    = parentRefId;
        _name           = name;
        _location       = location;
    }

    public ProjectId GetIdentity () {
        return _identity;
    }

    public ProjectId GetParentRefId () {
        return _parentRefId;
    }

    public Name GetName () {
        return _name;
    }

    public File GetLocation () {
        return _location;
    }

    public void AddDependency (final String depId) {
        _dependencies.add(ProjectId.Get(depId));
    }
    public void AddDependency (final ProjectId depId) {
        _dependencies.add(depId);
    }

    // ---------------------------------

    public static ProjectEntry Create ( final ProjectId id,
                                        final String name,
                                        final String location,
                                        final ProjectId parentRefId)
    {
        return new ProjectEntry(id, new Name(name), new File(location),
                                parentRefId);
    }

    // ---------------------------------

    @Override
    public String toString () {
        return _name.toString() + "/" + _identity + "/" + _location +
                "/Dependencies(" + _dependencies.size() + ")";
    }
}