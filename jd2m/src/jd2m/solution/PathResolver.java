package jd2m.solution;

import java.io.File;
import java.nio.file.Path;
import jd2m.util.ProjectId;

import static jd2m.util.PathHelper.IsWindowsPath;
import static jd2m.util.PathHelper.IsFileName;
import static jd2m.util.PathHelper.UnixifyPath;
import static jd2m.util.PathHelper.CreatePath;

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
        assert !IsWindowsPath(path) || IsFileName(path);
        final Path result = _solutionDir.resolve(path);
        return result;
    }
    public Path SolutionResolve (final String path, final boolean isWindows) {
        Path _m_result;
        if (isWindows) {
            final String unixPath = UnixifyPath(path);
            _m_result = SolutionResolve(unixPath);
        }
        else
            _m_result = SolutionResolve(path);
        final Path result = _m_result;
        return result;
    }
    public Path SolutionResolveWinPath (final String path) {
        final Path result = SolutionResolve(path, true);
        return result;
    }

    public Path ProjectPath (final ProjectEntry entry) {
        final Path location = entry.GetLocation();
        assert !IsWindowsPath(location.toString());
        assert !location.isAbsolute();
        final Path result = _solutionDir.resolve(location);
        {
            assert result.isAbsolute();
            assert new File(result.toString()).isFile();
        }
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
        final ProjectEntry entry = _projEntries.Get(projectId);
        final Path result = ProjectResolve(entry, path);
        return result;
    }
    public Path ProjectResolve (final ProjectEntry entry, final String path) {
        final Path projectPath = ProjectPath(entry);
        final Path projectDirectory = projectPath.getParent();
        final Path result = projectDirectory != null?
                                    projectDirectory.resolve(path):
                                    CreatePath(path);
        return result;
    }
}

