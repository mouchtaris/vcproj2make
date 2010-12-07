package jd2m.cbuild;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import jd2m.util.Name;
import jd2m.util.ProjectId;

public final class CSolution {
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
}
