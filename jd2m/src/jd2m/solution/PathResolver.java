package jd2m.solution;

import java.io.File;
import java.nio.file.Path;
import jd2m.util.ProjectId;

public class PathResolver {

    private final Path                  _solutionDir;
    private final ProjectEntryHolder    _projEntries;
    public PathResolver (final Path solutionRoot, final ProjectEntryHolder _h) {
        _solutionDir    = solutionRoot;
        assert _solutionDir != null;
        _projEntries = _h;
    }

    public Path GetSolutionDirectory () {
        return _solutionDir;
    }

    public Path SolutionResolve (final Path path) {
        final Path result = _solutionDir.resolve(path);
        return result;
    }
    public Path SolutionResolve (final String path) {
        final Path result = _solutionDir.resolve(path);
        return result;
    }

    public Path ProjectPath (final ProjectEntry entry) {
        final File location = entry.GetLocation();
        assert !location.isAbsolute();
        final Path result = _solutionDir.resolve(location.getPath());
        assert new File(result.toAbsolutePath().toString()).isFile();
        return result;
    }
    public Path ProjectPath (final ProjectId projectId) {
        final ProjectEntry entry = _projEntries.Get(projectId);
        final Path result = ProjectPath(entry);
        return result;
    }

//    public Path ProjectResolve (final ProjectId projectId, final Path pat) {
//        final Path result = ProjectPath(projectId).resolve(pat);
//        return result;
//    }
//    public Path ProjectResolve (final ProjectEntry entry, final Path path) {
//        final Path result = ProjectPath(entry).resolve(path);
//        return result;
//    }
    public Path ProjectResolve (final ProjectId projectId, final String path) {
        final Path result = ProjectPath(projectId).resolve(path);
        return result;
    }
    public Path ProjectResolve (final ProjectEntry entry, final String path) {
        final Path result = ProjectPath(entry).resolve(path);
        return result;
    }
}

