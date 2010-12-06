package jd2m.solution;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

public class PathResolver {

    private final String                _solutionName;
    private final Path                  _solutionDir;
    private final ProjectEntryHolder    _projEntries;
    public PathResolver (final Path solutionPath, final ProjectEntryHolder _h) {
        _solutionName   = solutionPath.getName().toString();
        assert _solutionName.length() > 0;
        _solutionDir    = solutionPath.getParent();
        assert _solutionDir != null;
        _projEntries = _h;
    }

    public Path GetSolutionDirectory () {
        return _solutionDir;
    }

    public String GetSolutionName () {
        return _solutionName;
    }

    public Path ProjectDirectory (final String projectId) {
        final ProjectEntry entry = _projEntries.Get(projectId);
        final File location = entry.GetLocation();
        assert !location.isAbsolute();
        assert location.isDirectory();
        final Path result = _solutionDir.resolve(entry.GetLocation().getPath());
        return result;
    }

    public Path ProjectResolve (final String projectId, final Path pat) {
        final Path result = ProjectDirectory(projectId).resolve(pat);
        return result;
    }
}

