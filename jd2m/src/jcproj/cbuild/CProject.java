package jcproj.cbuild;

import jd2m.util.IterableConcatenationIterator;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Name;
import jd2m.util.PremadeIteratorWrapperIterable;
import jd2m.util.ProjectId;

import static jd2m.util.PathHelper.CreatePath;
import static jd2m.util.PathHelper.IsAbsoluteUnixPath;;
import static java.util.Collections.unmodifiableList;

/**
 * @author TURBO_X
 */
public final class CProject {
    static List<CProperties> CreatePropertiesList () {
        return new LinkedList<>();
    }

    private final List<CProperties> _props = CreatePropertiesList();
    private final String            _location;
    private final Name              _name;
    private final ProjectId         _id;
    private final String            _configuration;
    private final String            _target;
    private final String            _targetExt;
    private final String            _output;
    private final String            _intermediate;
    private final String            _api;
    private final CProjectType      _type;
    private final List<ProjectId>   _deps = new LinkedList<>();
    private final List<String>      _sources = new LinkedList<>();

    /**
     * Package-protected so that {@link CPropertiesTransformationApplicator}
     * can access the properties list and replace properties with the
     * modified ones.
     * @return {@link #_props}
     */
    List<CProperties> GetProps () {
        return _props;
    }

    /**
     *
     * @param location the project file's location (relative pathname)
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
    public CProject (   final String        location,
                        final Name          name,
                        final ProjectId     id,
                        final String        configuration,
                        final String        target,
                        final String        targetExt,
                        final String        output,
                        final String        intermediate,
                        final String        apiDirectory,
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

    public void AddSource (final String pathname) {
        assert !IsAbsoluteUnixPath(pathname);
        _sources.add(pathname);
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
    public int GetNumberOfDependencies () {
        return _deps.size();
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

    public Iterable<Path> GetSources () {
        return unmodifiableList(_sources);
    }
    public int GetNumberOfSources () {
        return _sources.size();
    }

    public Path GetIntermediate () {
        return _intermediate;
    }

    public Name GetName () {
        return _name;
    }

    public CProjectType GetType () {
        return _type;
    }

    //////////////////////////////////////////////////////////////////////
    // ------------------------
    // Private

    private interface PropertyIterableOfSomethingGetter<T> {
        Iterable<T> git (CProperties props);
    }
    // ---
    private static final PropertyIterableOfSomethingGetter<String>
    DefinitionsGitter = new PropertyIterableOfSomethingGetter<String>() {
        @Override
        public Iterable<String> git (final CProperties props) {
            return props.GetDefinitions();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<Path>
    IncludeDirectoriesGitter = new PropertyIterableOfSomethingGetter<Path>() {
        @Override
        public Iterable<Path> git (final CProperties props) {
            return props.GetIncludeDirectories();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<Path>
    LibraryDirectoriesGitter = new PropertyIterableOfSomethingGetter<Path>() {
        @Override
        public Iterable<Path> git (final CProperties props) {
            return props.GetLibraryDirectories();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<String>
    AdditionalLibrariesGitter = new PropertyIterableOfSomethingGetter<String>() {
        @Override
        public Iterable<String> git (final CProperties props) {
            return props.GetAdditionalLibraries();
        }
    };
    // ---
    private <T> Iterable<T> _GetIterableOfSomethingFromProperties (
                            final PropertyIterableOfSomethingGetter<T> gitter)
    {
        final IterableConcatenationIterator<T> iterator = new IterableConcatenationIterator<T>();
        final PremadeIteratorWrapperIterable<T> result = new PremadeIteratorWrapperIterable<T>(iterator);

        for (final CProperties prop: _props)
            iterator.add(gitter.git(prop));

        return result;
    }
}
