package jd2m.cbuild;

import java.nio.file.Path;
import java.util.LinkedList;
import java.util.List;

import static jd2m.util.PathHelper.IsFile;
import static jd2m.util.PathHelper.CreatePath;
import static java.util.Collections.unmodifiableList;

public final class CProperties {

    private final List<Path> _includes  = new LinkedList<Path>();
    private final List<String> _defs    = new LinkedList<String>();
    private final List<Path> _libdirs   = new LinkedList<Path>();
    private final List<String> _libs    = new LinkedList<String>();

    public void AddIncludeDirectory (final Path dir) {
        assert !IsFile(dir.toString());
        assert !dir.isAbsolute();
        _includes.add(dir);
    }
    public void AddIncludeDirectory (final String dirpath) {
        AddIncludeDirectory(CreatePath(dirpath));
    }

    public void AddIncludeDirectories (final Iterable<? extends Path> dirs) {
        for (final Path dir: dirs)
            AddIncludeDirectory(dir);
    }

    public void AddIncludeDirectoriesFromPaths (final Iterable<String> paths) {
        for (final String path: paths)
            AddIncludeDirectory(CreatePath(path));
    }

    public void AddDefinition (final String def) {
        _defs.add(def);
    }

    public void AddLibraryDrectory (final Path dir) {
        _libdirs.add(dir);
    }

    public void AddLibraryDrectory (final String dirpath) {
        AddLibraryDrectory(CreatePath(dirpath));
    }

    public void AddLibraryDrectories (final Iterable<? extends Path> dirs) {
        for (final Path dir: dirs)
            AddLibraryDrectory(dir);
    }

    public void AddLibraryDirectoriesFromPaths (final Iterable<String> paths) {
        for (final String path: paths)
            AddLibraryDrectory(CreatePath(path));
    }

    /**
     * <em>NOTICE</em>:
     * the library name must be the base name, without system specific
     * prefices or extensions. Use {@link #AddWindowsLibrary} to strip
     * windows specific naming elements.
     * @param lib
     */
    public void AddLibrary (final String lib) {
        _libs.add(lib);
    }

    /** Strips all extensions from the given string and then adds it as a
     *  library dependency, by {@link #AddLibrary(String)}
     * @param lib
     */
    public void AddWindowsLibrary (final String lib) {
        AddLibrary(_u_stripWindowsSpecificLibraryNaming(lib));
    }

    // -----------------------------------------------------------------
    // Getters

    public Iterable<String> GetDefinitions () {
        return unmodifiableList(_defs);
    }

    public Iterable<Path> GetIncludeDirectories () {
        return unmodifiableList(_includes);
    }

    public Iterable<Path> GetLibraryDirectories () {
        return unmodifiableList(_libdirs);
    }

    public Iterable<String> GetAdditionalLibraries () {
        return unmodifiableList(_libs);
    }

    // ---------------------------------
    // Private
    private static String _u_stripWindowsSpecificLibraryNaming (final String s){
        // Strip all extensions
        final int dotIndex = s.lastIndexOf('.');
        assert dotIndex > 0;
        assert s.length() > dotIndex + 3;
        assert s.substring(dotIndex+1).equals("lib");
        final String result = s.substring(0, dotIndex);
        return result;
    }
}
