package jd2m.util;

import java.nio.file.FileSystem;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class PathHelper {

    public static final String CPP_EXTENSION    = "cpp";
    public static final String OBJECT_EXTENSION = "o";
    public static final String DEPEND_EXTENSION = "d";

    private PathHelper () {
    }

    private final static FileSystem FileSystem = java.nio.file.FileSystems
            .getDefault();
    public static FileSystem GetFileSystem () {
        return FileSystem;
    }

    /**
     *
     * @param pathname
     * @return
     * @deprecated Why do you need a path?
     */
    @Deprecated
    public static Path CreatePath (final String pathname) {
        final Path result = Paths.get(pathname);
        return result;
    }

    /**
     * Checks if the given path could be a windows path. A windows path will
     * not contain a forward slash.
     *
     * @param pathname
     * @return {@code pathname.indexOf('/') == -1}
     */
    public static boolean CouldBeWindowsPath (final String pathname) {
        final int slashIndex = pathname.indexOf('/');
        boolean result = slashIndex == -1;
        return result;
    }

    /**
     * Checks if the given path is ".", ".." or ends with a forward slash
     * ('/').
     * @param pathname
     * @return {@code IsUnisexDirectory() || lastChar == '/'}
     */
    public static boolean IsUnixDirectory (final String pathname) {
        final boolean   b00         = IsUnisexDirectory(pathname);
        final char      lastChar    = pathname.charAt(pathname.length() - 1);
        final boolean   b01         = lastChar == '/';
        return b00 || b01;
    }

    /**
     * Checks if the given path is ".", ".." or ends with a backward slash
     * ('\\').
     *
     * @param pathname
     * @return {@link #IsUnisexDirectory IsUnisexDirectory()} {@code || lastChar == '\\' }
     */
    public static boolean IsWindowsDirectory (final String pathname) {
        final boolean   isunisex    = IsUnisexDirectory(pathname);
        final char      lastchar    = pathname.charAt(pathname.length() - 1);
        final boolean   isdir       = lastchar == '\\';
        return isunisex || isdir;
    }

    /**
     * Checks that the given path does not end with a Unix path separator
     * ('/') and that it has an extension, if {@code withExtension} is
     * {@code true}.
     *
     * @param pathname
     * @param withExtension
     * @return
     * @deprecated use {@link #IsUnixDirectory}
     */
    @Deprecated
    public static boolean IsFile (  final String pathname,
                                    final boolean withExtension)
    {
        // The IsFile() check works only on Unix paths. Assert that.
        assert !CouldBeWindowsPath(pathname) || IsUnisexPath(pathname);
        final int slashIndex = pathname.lastIndexOf('/');
        String pathToTest;
        if (slashIndex >= 0)
            pathToTest = pathname.substring(slashIndex + 1);
        else
            pathToTest = pathname;
        //
        boolean dbg0, dbg1;
        boolean result =    (dbg0 = !pathToTest.isEmpty())          &&
                           (dbg1 = !IsUnisexDirectory(pathToTest));
        if (result) { // so far
            boolean hasExtension = true;
            if (withExtension) {
                final int dotIndex = pathToTest.lastIndexOf('.');
                hasExtension = dotIndex > 0;
                assert dotIndex > slashIndex || !hasExtension;
            }
            result = result && hasExtension;
        }

        return result;
    }

    /**
     * {@link #IsFile(java.lang.String, boolean) IsFile(pathname, true)}
     * @param pathname
     * @return
     * @deprecated see {@link #IsFile(String,boolean)}
     */
    @Deprecated
    public static boolean IsFile (final String pathname) {
        final boolean result = IsFile(pathname, true);
        return result;
    }

    /**
     * Checks if the given path contains no forward or backward slashes and
     * is not "." or "..".
     * @param pathname
     * @return {@code !contains('/') && !contains('\\') && !IsUnisedDirectory()}
     */
    public static boolean IsFileName (final String pathname) {
        final int slashIndex        = pathname.indexOf('/');
        final int backslashIndex    = pathname.indexOf('\\');
        final boolean result        =   slashIndex      == -1   &&
                                        backslashIndex  == -1   &&
                                        !IsUnisexDirectory(pathname);

        return result;
    }

    /**
     * A unisex path is either a unisex directory ("." or "..") or a filename.
     * @param pathname
     * @return {@code IsUnisexDirectory() || IsFileName() }
     */
    public static boolean IsUnisexPath (final String pathname) {
        boolean dbg0, dbg1;
        final boolean result =  (dbg0 = IsUnisexDirectory(pathname))    ||
                                (dbg1 = IsFileName(pathname));
        return result;
    }

    /**
     * Checks if pathname is "." or "..".
     * @param pathname
     * @return {@code equals(".") || equals("..")}
     */
    public static boolean IsUnisexDirectory (final String pathname) {
        boolean dbg0, dbg1;
        final boolean result =  (dbg0 = pathname.equals("."))   ||
                                (dbg1 = pathname.equals(".."));
        return result;
    }

    /**
     * <p>Unixify a path: replace all backward slashes with forward ones.</p>
     * <p><strong>Preconditions:</strong> <ol>
     * <li> {@link #CouldBeWindowsPath CouldBeWindowsPath(pathname)} </li>
     * </ol></p>
     * @param pathname
     * @return
     */
    public static String UnixifyPath (final String pathname) {
        assert CouldBeWindowsPath(pathname);
        final String result = pathname.replaceAll("\\\\", "/");
        return result;
    }

    /**
     * Strips the extension from the given path (which may be a full path,
     * including directories).
     *
     * @param pathname
     * @return the pathname stripped of its extension
     */
    public static String StripExtension (final String pathname) {
        final int dotIndex = pathname.lastIndexOf('.');
        assert dotIndex > 0;
        assert pathname.length() > dotIndex + 1;
        final String result = pathname.substring(0, dotIndex);
        return result;
    }

    /**
     * Fetches the extension of the given path, which may be a full path
     * (including directories).
     *
     * @param pathname
     * @return the extension of the given path
     */
    public static String GetExtension (final String pathname) {
        final int dotIndex = pathname.lastIndexOf('.');
        assert dotIndex > 0;
        assert pathname.length() > dotIndex + 1;
        final String result = pathname.substring(dotIndex + 1);
        return result;
    }

    /**
     * Replaces all "." and ".." with "_" and "__", respectively.
     *
     * @param pathname
     * @return a path without upward elements
     */
    public static String ToMonotonousPath (final String pathname) {
        final String level0 = pathname.replaceAll("\\.\\./", "__/");
        final String level1 = level0.replaceAll("\\./", "_/");
        final String result = level1;
        return result;
    }

    /**
     *
     * @param pathname
     * @return {@code IsUnix() && pathname[0] == '/'}
     */
    public static boolean IsAbsoluteUnixPath (final String pathname) {
        final boolean isunix = !CouldBeWindowsPath(pathname);
        final boolean isabsolute = pathname.charAt(0) == '/';
        return isunix && isabsolute;
    }

    public static boolean IsAbsoluteWindowsPath (final String pathname) {
        final boolean iswindows     = CouldBeWindowsPath(pathname);
        final boolean isabsolute0   = pathname.charAt(0) == '\\';
        final boolean isabsolute1_0 = Character.isLetter(pathname.charAt(0));
        final boolean isabsolute1_1 = pathname.charAt(1) == ':';
        final boolean isabsolute1_2 = pathname.charAt(2) == '\\';
        final boolean result        = iswindows && (isabsolute0 || isabsolute1_0 && isabsolute1_1 && isabsolute1_2);
        return result;
    }
}
