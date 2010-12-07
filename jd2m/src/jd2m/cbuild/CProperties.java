package jd2m.cbuild;

import java.io.File;
import java.util.LinkedList;
import java.util.List;

public final class CProperties {

    private final List<File> _includes  = new LinkedList<>();
    private final List<String> _defs    = new LinkedList<>();
    private final List<File> _libdirs   = new LinkedList<>();
    private final List<String> _libs    = new LinkedList<>();

    public void AddIncludeDirectory (final File dir) {
        assert dir.isDirectory();
        assert !dir.isAbsolute();
        _includes.add(dir);
    }
    public void AddIncludeDirectory (final String dirpath) {
        AddIncludeDirectory(new File(dirpath));
    }

    public void AddIncludeDirectories (final Iterable<? extends File> dirs) {
        for (final File dir: dirs)
            AddIncludeDirectory(dir);
    }

    public void AddIncludeDirectoriesFromPaths (final Iterable<String> paths) {
        for (final String path: paths)
            AddIncludeDirectory(new File(path));
    }

    public void AddDefinition (final String def) {
        _defs.add(def);
    }

    public void AddLibraryDrectory (final File dir) {
        assert dir.isAbsolute() || dir.getPath().length() == 0;
        _libdirs.add(dir);
    }

    public void AddLibraryDrectory (final String dirpath) {
        AddLibraryDrectory(new File(dirpath));
    }

    public void AddLibraryDrectories (final Iterable<? extends File> dirs) {
        for (final File dir: dirs)
            AddLibraryDrectory(dir);
    }

    public void AddLibraryDirectoriesFromPaths (final Iterable<String> paths) {
        for (final String path: paths)
            AddLibraryDrectory(new File(path));
    }

    /**
     * <em>NOTICE</em>:
     * the library name must be the base name, without system specific
     * prefices or extensions.
     * @param lib
     */
    public void AddLibrary (final String lib) {
        _libs.add(lib);
    }
}
