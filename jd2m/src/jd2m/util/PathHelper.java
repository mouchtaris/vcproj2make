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

    public static Path CreatePath (final String pathname) {
        final Path result = Paths.get(pathname);
        return result;
    }
    
    public static boolean IsWindowsPath (final String pathname) {
        final int slashIndex = pathname.indexOf('/');
        final boolean result = slashIndex == -1;
        return result;
    }

    public static boolean IsFile (  final String pathname,
                                    final boolean withExtension)
    {
        // The IsFile() check works only on Unix paths. Assert that.
        assert !IsWindowsPath(pathname) || IsUnisexPath(pathname);
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
    public static boolean IsFile (final String pathname) {
        final boolean result = IsFile(pathname, true);
        return result;
    }

    public static boolean IsFileName (final String pathname) {
        final int slashIndex        = pathname.indexOf('/');
        final int backslashIndex    = pathname.indexOf('\\');
        final boolean result        =   slashIndex      == -1   &&
                                        backslashIndex  == -1   &&
                                        !IsUnisexDirectory(pathname);

        return result;
    }

    public static boolean IsUnisexPath (final String pathname) {
        boolean dbg0, dbg1;
        final boolean result =  (dbg0 = IsUnisexDirectory(pathname))    ||
                                (dbg1 = IsFileName(pathname));
        return result;
    }

    public static boolean IsUnisexDirectory (final String pathname) {
        boolean dbg0, dbg1;
        final boolean result =  (dbg0 = pathname.equals("."))   ||
                                (dbg1 = pathname.equals(".."));
        return result;
    }

    public static String UnixifyPath (final String pathname) {
        assert IsWindowsPath(pathname);
        final String result = pathname.replaceAll("\\\\", "/");
        return result;
    }

    public static String StripExtension (final String pathname) {
        final int dotIndex = pathname.lastIndexOf('.');
        assert dotIndex > 0;
        assert pathname.length() > dotIndex + 1;
        final String result = pathname.substring(0, dotIndex);
        return result;
    }

    public static String GetExtension (final String pathname) {
        final int dotIndex = pathname.lastIndexOf('.');
        assert dotIndex > 0;
        assert pathname.length() > dotIndex + 1;
        final String result = pathname.substring(dotIndex + 1);
        return result;
    }

    public static String ToMonotonousPath (final String pathname) {
        final String level0 = pathname.replaceAll("\\.\\./", "__/");
        final String level1 = level0.replaceAll("\\./", "_/");
        final String result = level1;
        return result;
    }
    
    public static boolean IsAbsoluteUnixPath (final String pathname) {
        final boolean isunix = !IsWindowsPath(pathname);
        final boolean isabsolute = pathname.charAt(0) == '/';
        return isunix && isabsolute;
    }
}
