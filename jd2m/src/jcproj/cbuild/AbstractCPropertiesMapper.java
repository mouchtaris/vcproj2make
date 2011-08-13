package jcproj.cbuild;

import java.nio.file.Path;

/**
 *
 * @author muhtaris
 */
public abstract class AbstractCPropertiesMapper implements CPropertiesMapper {

    @Override
    public Path MapIncludeDirectory (final Path includeDirectory) {
        return includeDirectory;
    }

    @Override
    public Path MapLibraryDirectory (final Path libraryDirectory) {
        return libraryDirectory;
    }

    @Override
    public String MapDefinition (final String definition) {
        return definition;
    }

    @Override
    public String MapLibrary (final String library) {
        return library;
    }

    @Override
    public CProperties ApplyTo (final CProperties props) {
        final CProperties result = new CProperties();
        CopyIncludeDirectories(props, result);
        CopyDefinitions(props, result);
        CopyLibraryDirectories(props, result);
        CopyLibraries(props, result);
        return result;
    }

    @Override
    public CProperties ApplyIfApplicableTo (final CProperties props) {
        if (IsApplicableTo(props))
            return ApplyTo(props);
        return props;
    }

    // -------------------------------------------
    // Utilities

    public final void CopyIncludeDirectories (  final CProperties from,
                                                final CProperties to)
    {
        if (from == to)
            throw new RuntimeException("from == to");

        for (final Path incl: from.GetIncludeDirectories())
            to.AddIncludeDirectory(MapIncludeDirectory(incl));
    }

    public final void CopyDefinitions (         final CProperties from,
                                                final CProperties to)
    {
        if (from == to)
            throw new RuntimeException("from == to");

        for (final String def: from.GetDefinitions())
            to.AddDefinition(MapDefinition(def));
    }

    public final void CopyLibraryDirectories (  final CProperties from,
                                                final CProperties to)
    {
        if (from == to)
            throw new RuntimeException("from == to");

        for (final Path libdir: from.GetLibraryDirectories())
            to.AddLibraryDrectory(MapLibraryDirectory(libdir));
    }

    public final void CopyLibraries (           final CProperties from,
                                                final CProperties to)
    {
        if (from == to)
            throw new RuntimeException("from == to");

        for (final String lib: from.GetAdditionalLibraries())
            to.AddLibrary(MapLibrary(lib));
    }

}
