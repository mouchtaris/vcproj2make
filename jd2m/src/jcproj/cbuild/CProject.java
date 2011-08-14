package jcproj.cbuild;

import jcproj.vcxproj.ProjectGuid;
import jd2m.util.IterableConcatenationIterator;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import jd2m.util.Name;
import jd2m.util.PremadeIteratorWrapperIterable;

import static jd2m.util.PathHelper.IsAbsoluteUnixPath;
import static java.util.Collections.unmodifiableList;

/**
 * @author TURBO_X
 */
public final class CProject {

    private final List<CProperties> _props = CreatePropertiesList();
    private final String            _location;
    private final Name              _name;
    private final ProjectGuid       _id;
    private final String            _configuration;
    private final String            _target;
    private final String            _targetExt;
    private final String            _output;
    private final String            _intermediate;
    private final String            _api;
    private final CProjectType      _type;
    private final List<ProjectGuid> _deps = new LinkedList<>();
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
     * Package-protected so that {@link CPropertiesTransformationApplicator}
     * can create a properties list in the same way that this class
     * internally would.
     * @return {@link #_props}
     */
    static List<CProperties> CreatePropertiesList () {
        return new LinkedList<>();
    }
    

    /**
     *
     * @param location the project file's location (relative pathname)
     * @param name the project's name
     * @param id the project's id
     * @param configuration the project's configuration name/description
     * @param target the project's result/output/target file base-name (without extension)
     * @param targetExt the project's result/output/target file extension
     * @param output the project's result/output/target directory (relative pathname)
     * @param intermediate the project's intermediate directory (relative pathname)
     * @param apiDirectory the project's API-related files containing directory (relative pathname)
     * @param type the project's type ({@link CProjectType})
     */
    public CProject (   final String        location,
                        final Name          name,
                        final ProjectGuid   id,
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

    public void AddDependency (final ProjectGuid depId) {
        _deps.add(depId);
    }

    public void AddSource (final String pathname) {
        assert !IsAbsoluteUnixPath(pathname);
        _sources.add(pathname);
    }

    ////////////////////////////////////////////
    // getters
    ////////////////////////////////////////////

    public ProjectGuid GetId () {
        return _id;
    }

    public String GetLocation () {
        return _location;
    }

    public String GetConfiguration () {
        return _configuration;
    }

    public Iterable<String> GetDefinitions () {
        return _GetIterableOfSomethingFromProperties(DefinitionsGitter);
    }

    public Iterable<String> GetIncludeDirectories () {
        return _GetIterableOfSomethingFromProperties(IncludeDirectoriesGitter);
    }

    public Iterable<String> GetLibraryDirectories () {
        return _GetIterableOfSomethingFromProperties(LibraryDirectoriesGitter);
    }

    public Iterable<ProjectGuid> GetDependencies () {
        return unmodifiableList(_deps);
    }
    public int GetNumberOfDependencies () {
        return _deps.size();
    }

    public String GetOutput () {
        return _output;
    }

    public String GetTarget () {
        return _target;
    }

    public Iterable<String> GetAdditionalLibraries () {
        return _GetIterableOfSomethingFromProperties(AdditionalLibrariesGitter);
    }

    public Iterable<String> GetSources () {
        return unmodifiableList(_sources);
    }
    public int GetNumberOfSources () {
        return _sources.size();
    }

    public String GetIntermediate () {
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
    private static final PropertyIterableOfSomethingGetter<String>
    IncludeDirectoriesGitter = new PropertyIterableOfSomethingGetter<String>() {
        @Override
        public Iterable<String> git (final CProperties props) {
            return props.GetIncludeDirectories();
        }
    };
    // ---
    private static final PropertyIterableOfSomethingGetter<String>
    LibraryDirectoriesGitter = new PropertyIterableOfSomethingGetter<String>() {
        @Override
        public Iterable<String> git (final CProperties props) {
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
        final IterableConcatenationIterator<T> iterator = new IterableConcatenationIterator<>();
        final PremadeIteratorWrapperIterable<T> result = new PremadeIteratorWrapperIterable<>(iterator);

        for (final CProperties prop: _props)
            iterator.add(gitter.git(prop));

        return result;
    }
}
