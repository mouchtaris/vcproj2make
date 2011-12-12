package jcproj.cbuild;

import java.util.LinkedList;
import java.util.List;

import static jd2m.util.PathHelper.IsUnixDirectory;
import static jd2m.util.PathHelper.IsAbsoluteUnixPath;
import static java.util.Collections.unmodifiableList;

public final class CProperties {

    private final List<String> _includes    = new LinkedList<String>();
    private final List<String> _defs        = new LinkedList<String>();
    private final List<String> _libdirs     = new LinkedList<String>();
    private final List<String> _libs        = new LinkedList<String>();

    public void AddIncludeDirectory (final String dir) {
        assert !IsUnixDirectory(dir.toString());
        assert !IsAbsoluteUnixPath(dir);
        _includes.add(dir);
    }

    public void AddIncludeDirectories (final Iterable<? extends String> dirs) {
        for (final String dir: dirs)
            AddIncludeDirectory(dir);
    }

    public void AddDefinition (final String def) {
        _defs.add(def);
    }

    public void AddLibraryDrectory (final String dir) {
        _libdirs.add(dir);
    }

    public void AddLibraryDrectories (final Iterable<? extends String> dirs) {
        for (final String dir: dirs)
            AddLibraryDrectory(dir);
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

    public Iterable<String> GetIncludeDirectories () {
        return unmodifiableList(_includes);
    }

    public Iterable<String> GetLibraryDirectories () {
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
