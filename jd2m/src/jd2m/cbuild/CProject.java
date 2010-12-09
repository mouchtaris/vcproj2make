package jd2m.cbuild;

import jd2m.util.IterableConcatenationIterator;
import java.nio.file.Path;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Name;
import jd2m.util.PremadeIteratorWrapperIterable;
import jd2m.util.ProjectId;

import static jd2m.util.PathHelper.CreatePath;
import static java.util.Collections.unmodifiableList;

/**
 * @author TURBO_X
 */
public final class CProject {
    private final List<CProperties> _props = new LinkedList<>();
    private final Path              _location;
    private final Name              _name;
    private final ProjectId         _id;
    private final String            _configuration;
    private final String            _target;
    private final String            _targetExt;
    private final Path              _output;
    private final Path              _intermediate;
    private final Path              _api;
    private final CProjectType      _type;
    private final List<ProjectId>   _deps = new LinkedList<>();
    private final List<Path>        _sources = new LinkedList<>();

    /**
     *
     * @param location the project file's location (full pathname)
     * @param name the project's name
     * @param id the project's id
     * @param configuration the project's configuration name/description
     * @param target the project's result/output/target file base-name (without extension)
     * @param targetExt the project's result/output/target file extension
     * @param output the project's result/output/target directory
     * @param intermediate the project's intermediate directory
     * @param apiDirectory the project's API-related files containing directory
     * @param type the project's type ({@link CProjectType})
     */
    public CProject (   final Path          location,
                        final Name          name,
                        final ProjectId     id,
                        final String        configuration,
                        final String        target,
                        final String        targetExt,
                        final Path          output,
                        final Path          intermediate,
                        final Path          apiDirectory,
                        final CProjectType  type
    ) {
        _location       = location;
        _name           = name;
        _id             = id;
        _configuration  = configuration;
        _target         = target;
        _targetExt      = targetExt;
        _output         = output;
        _intermediate   = intermediate;
        _api            = apiDirectory;
        _type           = type;
    }

    public void AddProperties (final CProperties prop) {
        _props.add(prop);
    }
    public void AddProperties (final Collection<? extends CProperties> props) {
        _props.addAll(props);
    }

    public void AddDependency (final ProjectId depId) {
        _deps.add(depId);
    }

    public void AddSource (final Path path) {
        assert !path.isAbsolute();
        _sources.add(path);
    }
    public void AddSource (final String path) {
        AddSource(CreatePath(path));
    }

    ////////////////////////////////////////////
    // getters
    ////////////////////////////////////////////

    public ProjectId GetId () {
        return _id;
    }

    public Path GetLocation () {
        return _location;
    }

    public String GetConfiguration () {
        return _configuration;
    }

    public Iterable<String> GetDefinitions () {
        return _GetIterableOfSomethingFromProperties(DefinitionsGitter);
    }

    public Iterable<Path> GetIncludeDirectories () {
        return _GetIterableOfSomethingFromProperties(IncludeDirectoriesGitter);
    }

    public Iterable<Path> GetLibraryDirectories () {
        return _GetIterableOfSomethingFromProperties(LibraryDirectoriesGitter);
    }

    public Iterable<ProjectId> GetDependencies () {
        return unmodifiableList(_deps);
    }

    public Path GetOutput () {
        return _output;
    }

    public String GetTarget () {
        return _target;
    }

    public Iterable<String> GetAdditionalLibraries () {
        return _GetIterableOfSomethingFromProperties(AdditionalLibrariesGitter);
    }

    //////////////////////////////////////////////////////////////////////
    // ------------------------
    // Private

    private interface PropertyIterableOfSomethingGetter<T> {
        Iterable<T> git (CProperties props);
    }
    // ---
    private static final PropertyIterableOfSomethingGetter<String>
    DefinitionsGitter = new PropertyIterableOfSomethingGetter<>() {
        @Override
        public Iterable<String> git (final CProperties props) {
            return props.GetDefinitions();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<Path>
    IncludeDirectoriesGitter = new PropertyIterableOfSomethingGetter<>() {
        @Override
        public Iterable<Path> git (final CProperties props) {
            return props.GetIncludeDirectories();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<Path>
    LibraryDirectoriesGitter = new PropertyIterableOfSomethingGetter<>() {
        @Override
        public Iterable<Path> git (final CProperties props) {
            return props.GetLibraryDirectories();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<String>
    AdditionalLibrariesGitter = new PropertyIterableOfSomethingGetter<>() {
        @Override
        public Iterable<String> git (final CProperties props) {
            return props.GetAdditionalLibraries();
        }
    };
    // ---
    private <T> Iterable<T> _GetIterableOfSomethingFromProperties (
                            final PropertyIterableOfSomethingGetter<T> gitter)
    {
        final IterableConcatenationIterator<T> iterator =
                new IterableConcatenationIterator<>();
        final PremadeIteratorWrapperIterable<T> result =
                new PremadeIteratorWrapperIterable<>(iterator);

        for (final CProperties prop: _props)
            iterator.add(gitter.git(prop));

        return result;
    }
}
