package jd2m.util;

import java.nio.file.FileSystem;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class PathHelper {
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
        assert !IsWindowsPath(pathname) || IsFileName(pathname);
        final boolean test0 = pathname.charAt(pathname.length()-1) != '/';
        boolean test1 = true;
        if (withExtension) {
            final int dotIndex = pathname.lastIndexOf('.');
            test1 = dotIndex > 0;
        }
        final boolean result = test0 && test1;
        return result;
    }
    public static boolean IsFile (final String pathname) {
        final boolean result = IsFile(pathname, true);
        return result;
    }
    
    public static boolean IsFileName (final String pathname) {
        final int slashIndex        = pathname.indexOf('/');
        final int backslashIndex    = pathname.indexOf('\\');
        final boolean result        =   slashIndex      == -1    &&
                                        backslashIndex  == -1;
        return result;
    }

    public static String UnixifyPath (final String pathname) {
        assert IsWindowsPath(pathname);
        final String result = pathname.replaceAll("\\\\", "/");
        return result;
    }

}
