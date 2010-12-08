package jd2m.cbuild;

import java.nio.file.Path;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Name;
import jd2m.util.ProjectId;

import static jd2m.util.PathHelper.CreatePath;

/**
 * @author TURBO_X
 */
public final class CProject {
    private final List<CProperties> _props = new LinkedList<>();
    private final Path              _location;
    private final Name              _name;
    private final ProjectId         _id;
    private final String            _target;
    private final String            _targetExt;
    private final Path              _output;
    private final Path              _intermediate;
    private final Path              _api;
    private final CProjectType      _type;
    private final List<ProjectId>   _deps = new LinkedList<>();
    private final List<Path>        _sources = new LinkedList<>();

    public CProject (   final Path          location,
                        final Name          name,
                        final ProjectId     id,
                        final String        target,
                        final String        targetExt,
                        final Path          output,
                        final Path          intermediate,
                        final Path          apiDirectory,
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

    public void AddDependency (final ProjectId depId) {
        _deps.add(depId);
    }

    public void AddSource (final Path path) {
        assert !path.isAbsolute();
        _sources.add(path);
    }
    public void AddSource (final String path) {
        AddSource(CreatePath(path));
    }

    ////////////////////////////////////////////
    // getters
    ////////////////////////////////////////////

    public ProjectId GetId () {
        return _id;
    }
}
