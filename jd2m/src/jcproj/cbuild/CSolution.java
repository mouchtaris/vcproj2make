package jcproj.cbuild;

import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import jcproj.vcxproj.ProjectGuid;
import jcproj.vcxproj.ProjectGuidFactory;
import jd2m.util.Name;

@SuppressWarnings("FinalClass")
public final class CSolution {
    private final String                        _location;
    private final Name                          _name;
    private final String                        _configurationName;
    private final Map<ProjectGuid, CProject>    _projects = new HashMap<ProjectGuid, CProject>(100);

    public CSolution (  final String    location,
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

    public CProject GetProject (final ProjectGuid projId) {
        final CProject result = _projects.get(projId);
        return result;
    }
    public CProject GetProject (final String projid) {
        return GetProject(ProjectGuidFactory.GetSingleton().Get(projid));
    }

    public Iterable<CProject> GetCProjectIterable () {
        return new Iterable<CProject>() {
            @Override
            public Iterator<CProject> iterator () {
                final Iterator<Entry<ProjectGuid, CProject>> entriesIterator = _projects.entrySet().iterator();
                return new Iterator<CProject>() {
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
        };
    }
    
    public Iterable<Map.Entry<ProjectGuid, CProject>> GetEntryIteratable () {
        return Collections.unmodifiableSet(_projects.entrySet());
    }
}
