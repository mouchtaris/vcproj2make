package jd2m.cbuild;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import jd2m.util.Name;
import jd2m.util.ProjectId;

public final class CSolution implements Iterable<CProject> {
    private final Path                      _location;
    private final Name                      _name;
    private final String                    _configurationName;
    private final Map<ProjectId, CProject>  _projects = new HashMap<>(100);

    public CSolution (  final Path      location,
                        final Name      name,
                        final String    configurationName)
    {
        _location           = location;
        _name               = name;
        _configurationName  = configurationName;
    }

    public void AddProject (final CProject proj) {
        final CProject previous = _projects.put(proj.GetId(), proj);
        assert previous == null;
    }

    public CProject GetProject (final ProjectId projId) {
        final CProject result = _projects.get(projId);
        return result;
    }

    @Override
    public Iterator<CProject> iterator() {
        final Iterator<Entry<ProjectId, CProject>> entriesIterator =
                _projects.entrySet().iterator();
        return new Iterator<>() {
            @Override
            public boolean hasNext() { return entriesIterator.hasNext(); }
            @Override
            public CProject next() { return entriesIterator.next().getValue(); }
            @Override
            public void remove() {
                throw new UnsupportedOperationException("Not supported.");
            }
        };
    }
}
