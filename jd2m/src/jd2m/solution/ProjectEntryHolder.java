package jd2m.solution;

import java.util.HashMap;
import java.util.Map;

public class ProjectEntryHolder {
    private final Map<String, ProjectEntry> _entries = new HashMap<>(100);

    public void Add (final ProjectEntry entry) {
        final Object previous = 
                _entries.put(entry.GetIdentity().toString(), entry);
        assert previous == null;
    }

    public ProjectEntry Get (final String projectId) {
        final ProjectEntry result = _entries.get(projectId);
        assert result != null;
        return result;
    }
}
