package jd2m.cbuild;

import java.io.File;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Name;
import jd2m.util.ProjectId;

/**
 * @author TURBO_X
 */
public final class CProject {
    private final List<CProperties> _props = new LinkedList<>();
    private final File              _location;
    private final Name              _name;
    private final ProjectId         _id;
    private final String            _target;
    private final String            _targetExt;
    private final File              _output;
    private final File              _intermediate;
    private final File              _api;
    private final CProjectType      _type;
    private final List<String>      _deps = new LinkedList<>();
    private final List<File>        _sources = new LinkedList<>();

    public CProject (   final File          location,
                        final Name          name,
                        final ProjectId     id,
                        final String        target,
                        final String        targetExt,
                        final File          output,
                        final File          intermediate,
                        final File          apiDirectory,
                        final CProjectType  type
    ) {
        _location       = location;
        _name           = name;
        _id             = id;
        _target         = target;
        _targetExt      = targetExt;
        _output         = output;
        _intermediate   = intermediate;
        _api            = apiDirectory;
        _type           = type;
    }

    public void AddProperties (final CProperties prop) {
        _props.add(prop);
    }
    public void AddProperties (final Collection<? extends CProperties> props) {
        _props.addAll(props);
    }

    public void AddDependency (final String depId) {
        ProjectId result = ProjectId.Get(depId);
        assert result != null;
        assert result.toString().equals(depId);
        _deps.add(depId);
    }

    public void AddSource (final File path) {
        assert !path.isAbsolute();
        _sources.add(path);
    }
    public void AddSource (final String path) {
        AddSource(new File(path));
    }

    ////////////////////////////////////////////
    // getters
    ////////////////////////////////////////////

    public ProjectId GetId () {
        return _id;
    }
}
