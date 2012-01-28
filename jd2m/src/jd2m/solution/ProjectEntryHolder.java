package jd2m.solution;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import jd2m.util.ProjectId;

public class ProjectEntryHolder implements Iterable<ProjectEntry> {
    private final Map<String, ProjectEntry> _entries = new HashMap<String, ProjectEntry>(100);

    public void Add (final ProjectEntry entry) {
        final Object previous =
                _entries.put(entry.GetIdentity().StringValue(), entry);
        assert previous == null;
    }

    public ProjectEntry Get (final String projectId) {
        final ProjectEntry result = _entries.get(projectId);
        assert result != null;
        return result;
    }

    public ProjectEntry Get (final ProjectId projectId) {
        final ProjectEntry result = _entries.get(projectId.StringValue());
        assert result != null;
        return result;
    }

    @Override
    public Iterator<ProjectEntry> iterator () {
        return new Iterator<ProjectEntry> () {
            private final Iterator<Entry<String, ProjectEntry>> ite = _entries.entrySet().iterator();
            @Override public boolean        hasNext () { return ite.hasNext(); }
            @Override public ProjectEntry   next    () { return ite.next().getValue(); }
            @Override public void           remove  () { throw new UnsupportedOperationException("Not allowed"); }
        };
    }
}
