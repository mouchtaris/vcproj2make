package jd2m.cbuild;

import java.nio.file.Path;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;
import jd2m.cbuild.exceptions.SimpleMappingAndOrderingCPropertiesTransformationException;

/**
 * <p>A {@code null} mapping value implies that the mappable of the given mapping
 * should be left out from the resulting transformation.</p>
 *
 * <p>A {@code null} ordering value implies that the mappable of the given mapping
 * does not take part in the ordering and, therefore, will be placed before
 * any orderable mappable.</p>
 * 
 * @author muhtaris
 */
public class SimpleMappingAndOrderingCPropertiesTransformation
        extends AbstractCPropertiesMapper
{
    private final Map<String, String>   _libMappings        = new HashMap<>(50);
    private final Map<String, String>   _defMappings        = new HashMap<>(50);
    private final Map<Path, Path>       _libdirMappings     = new HashMap<>(50);
    private final Map<Path, Path>       _incldirMappings    = new HashMap<>(50);
    //
    private final Map<String, Integer>  _libsValues         = new HashMap<>(50);
    private final Map<String, Integer>  _defsValues         = new HashMap<>(50);
    private final Map<Path, Integer>    _libdirsValues      = new HashMap<>(50);
    private final Map<Path, Integer>    _incldirsValues     = new HashMap<>(50);

    public void SetLibraryMapping (final String from, final String to) {
        _u_addMappingIfNotExistent(_libMappings, from, to);
    }

    public void SetDefinitionMapping (final String from, final String to) {
        _u_addMappingIfNotExistent(_defMappings, from, to);
    }

    public void SetLibraryDirectoryMapping (final Path from, final Path to){
        _u_addMappingIfNotExistent(_libdirMappings, from, to);
    }

    public void SetIncludeDirectoryMapping (final Path from, final Path to){
        _u_addMappingIfNotExistent(_incldirMappings, from, to);
    }

    // -----
    
    public void SetLibraryOrderingValue (final String lib, final int value) {
        _u_addMappingIfNotExistent(_libsValues, lib, value);
    }

    public void SetDefinitionOrderingValue (final String def, final int value) {
        _u_addMappingIfNotExistent(_defsValues, def, value);
    }

    public void SetLibraryDirectoryOrderingValue (final Path d, final int v) {
        _u_addMappingIfNotExistent(_libdirsValues, d, v);
    }

    public void SetIncludeDirectoryOrderingValue (final Path d, final int v) {
        _u_addMappingIfNotExistent(_incldirsValues, d, v);
    }
    
    // -----
    
    public boolean LibraryHasMapping (final String lib) {
        return _libMappings.containsKey(lib);
    }

    public boolean DefinitionHasMapping (final String def) {
        return _defMappings.containsKey(def);
    }

    public boolean LibraryDirectoryHasMapping (final Path libdir) {
        return _libdirMappings.containsKey(libdir);
    }

    public boolean IncludeDirectoryHasMapping (final Path incldir) {
        return _incldirMappings.containsKey(incldir);
    }

    // -----

    public boolean LibraryHasOrderingValue (final String lib) {
        return _libsValues.containsKey(lib);
    }

    public boolean DefinitionHasOrderingValue (final String def) {
        return _defsValues.containsKey(def);
    }

    public boolean LibraryDirectoryHasOrderingValue (final Path libdir) {
        return _libdirsValues.containsKey(libdir);
    }

    public boolean IncludeDirectoryHasOrderingValue (final Path incldir) {
        return _incldirsValues.containsKey(incldir);
    }

    // -----

    @Override
    public String MapDefinition (final String def) {
        final String result  = _u_getMappingIfExistent(_defMappings, def);
        return result;
    }

    @Override
    public Path MapIncludeDirectory (final Path incldir) {
        final Path result = _u_getMappingIfExistent(_incldirMappings, incldir);
        return result;
    }

    @Override
    public String MapLibrary (final String lib) {
        final String result = _u_getMappingIfExistent(_libMappings, lib);
        return result;
    }

    @Override
    public Path MapLibraryDirectory (final Path libdir) {
        final Path result = _u_getMappingIfExistent(_libdirMappings, libdir);
        return result;
    }

    // -----

    public boolean HasMappableLibrary (final CProperties props) {
        for (final String lib: props.GetAdditionalLibraries())
            if (LibraryHasMapping(lib))
                return true;
        return false;
    }

    public boolean HasMappableDefinition (final CProperties props) {
        for (final String def: props.GetDefinitions())
            if (DefinitionHasMapping(def))
                return true;
        return false;
    }

    public boolean HasMappableIncludeDirectory (final CProperties props) {
        for (final Path incldir: props.GetIncludeDirectories())
            if (IncludeDirectoryHasMapping(incldir))
                return true;
        return false;
    }

    public boolean HasMappableLibraryDirectory (final CProperties props) {
        for (final Path libdir: props.GetLibraryDirectories())
            if (LibraryDirectoryHasMapping(libdir))
                return true;
        return false;
    }

    // ----

    public boolean HasOrderableLibrary (final CProperties props) {
        for (final String lib: props.GetAdditionalLibraries())
            if (LibraryHasOrderingValue(lib))
                return true;
        return false;
    }

    public boolean HasOrderableDefinition (final CProperties props) {
        for (final String def: props.GetDefinitions())
            if (DefinitionHasOrderingValue(def))
                return true;
        return false;
    }

    public boolean HasOrderableLibraryDirectory (final CProperties props) {
        for (final Path libdir: props.GetLibraryDirectories())
            if (LibraryDirectoryHasOrderingValue(libdir))
                return true;
        return false;
    }

    public boolean HasOrderableIncludeDirectory (final CProperties props) {
        for (final Path incldir: props.GetIncludeDirectories())
            if (IncludeDirectoryHasOrderingValue(incldir))
                return true;
        return false;
    }

    // -----
    
    @Override
    public CProperties ApplyTo (final CProperties props) {
        final CProperties result = new CProperties();

        // Update libraries
        _u_transform(   _libMappings, _libsValues,
                        props.GetAdditionalLibraries(),
                        LibraryMappabilityChecker,
                        LibraryOrderabilityChecker,
                        new LibraryResultStorer(result));

        // Update definitions
        _u_transform(   _defMappings, _defsValues,
                        props.GetDefinitions(),
                        DefinitionMappabilityChecker,
                        DefinitionOrderabilityChecker,
                        new DefinitionResultStorer(result));

        // Update libraries directories
        _u_transform(   _libdirMappings, _libdirsValues,
                        props.GetLibraryDirectories(),
                        LibraryDirectoryMappabilityChecker,
                        LibraryDirectoryOrderabilityChecker,
                        new LibraryDirectoryResultStorer(result));

        // Update include directories
        _u_transform(   _incldirMappings, _incldirsValues,
                        props.GetIncludeDirectories(),
                        IncludeDirectoryMappabilityChecker,
                        IncludeDirectoryOrderabilityChecker,
                        new IncludeDirectoryResultStorer(result));

        return result;
    }

    @Override
    public boolean IsApplicableTo (final CProperties props) {
        Boolean v0, v1, v2, v3, v4, v5, v6, v7; // for debugging inspection
        final boolean result =  (v0 = HasMappableDefinition(props))         ||
                                (v2 = HasMappableIncludeDirectory(props))   ||
                                (v1 = HasMappableLibrary(props))            ||
                                (v3 = HasMappableLibraryDirectory(props))   ||
                                //
                                (v4 = HasOrderableDefinition(props))        ||
                                (v5 = HasOrderableIncludeDirectory(props))  ||
                                (v6 = HasOrderableLibrary(props))           ||
                                (v7 = HasOrderableLibraryDirectory(props));
        return result;
    }

    // ---------------------------------------------
    // Private

    // -------------------
    // utilities
    private static <K,V> void _u_addMappingIfNotExistent (  final Map<K,V> map,
                                                            final K from,
                                                            final V to)
    {
        if (map.containsKey(from))
            throw new
                    SimpleMappingAndOrderingCPropertiesTransformationException(
                            from + " already in mapping");
        map.put(from, to);
    }

    private static <K,V> V _u_getMappingIfExistent (final Map<K,V> map,
                                                    final K key)
    {
        final boolean hasMapping = map.containsKey(key);
        if (!hasMapping)
            throw new
                    SimpleMappingAndOrderingCPropertiesTransformationException(
                            "No such key: " + key);
        final V result = map.get(key);
        return result;
    }

    // ------------------------------------

    private static final class OrderingComparator<V> implements Comparator<V> {
        private final Map<V, Integer> _orderingValues;
        public OrderingComparator (final Map<V, Integer> orderingValues) {
            _orderingValues = orderingValues;
        }
        @Override
        public int compare (final V o1, final V o2) {
            final Integer value1 = _orderingValues.get(o1);
            assert value1 != null;
            final Integer value2 = _orderingValues.get(o2);
            assert value2 != null;
            final int result = value1.compareTo(value2);
            return result;
        }
        
    }

    // -------------------------------------

    private interface MappabilityChecker<V> {
        boolean IsMappable (V value);
    }
    private final MappabilityChecker<String> LibraryMappabilityChecker =
            new MappabilityChecker<>() {
                @Override
                public boolean IsMappable (final String value) {
                    return LibraryHasMapping(value);
                }
            };
    private final MappabilityChecker<String> DefinitionMappabilityChecker =
            new MappabilityChecker<>() {
                @Override
                public boolean IsMappable (final String value) {
                    return DefinitionHasMapping(value);
                }
            };
    private final MappabilityChecker<Path> LibraryDirectoryMappabilityChecker=
            new MappabilityChecker<>() {
                @Override
                public boolean IsMappable (final Path value) {
                    return LibraryDirectoryHasMapping(value);
                }
            };
    private final MappabilityChecker<Path> IncludeDirectoryMappabilityChecker =
            new MappabilityChecker<>() {
                @Override
                public boolean IsMappable (final Path value) {
                    return IncludeDirectoryHasMapping(value);
                }
            };

    // -------------------------------------

    private interface OrderabilityChecker<V> {
        boolean IsOrderable (V value);
    }
    private final OrderabilityChecker<String> LibraryOrderabilityChecker =
            new OrderabilityChecker<>() {
                @Override
                public boolean IsOrderable (final String value) {
                    return LibraryHasMapping(value);
                }
            };
    private final OrderabilityChecker<String> DefinitionOrderabilityChecker =
            new OrderabilityChecker<>() {
                @Override
                public boolean IsOrderable (final String value) {
                    return DefinitionHasMapping(value);
                }
            };
    private final OrderabilityChecker<Path> LibraryDirectoryOrderabilityChecker=
            new OrderabilityChecker<>() {
                @Override
                public boolean IsOrderable (final Path value) {
                    return LibraryDirectoryHasMapping(value);
                }
            };
    private final OrderabilityChecker<Path> IncludeDirectoryOrderabilityChecker=
            new OrderabilityChecker<>() {
                @Override
                public boolean IsOrderable (final Path value) {
                    return IncludeDirectoryHasMapping(value);
                }
            };

    // -------------------------------------

    private abstract class CPropertiesResultStorer<V> {
        protected CProperties props;
        protected CPropertiesResultStorer (final CProperties _props) {
            props = _props;
        }
        public abstract void Store (V value);
    }
    //
    private class LibraryResultStorer extends CPropertiesResultStorer<String>{
        public LibraryResultStorer (final CProperties _props) {
            super(_props);
        }
        @Override
        public void Store (final String lib) {
            props.AddLibrary(lib);
        }
    };
    //
    private class DefinitionResultStorer
            extends CPropertiesResultStorer<String>
    {
        public DefinitionResultStorer (final CProperties _props) {
            super(_props);
        }
        @Override
        public void Store (final String def) {
            props.AddDefinition(def);
        }
    };
    //
    private class LibraryDirectoryResultStorer
            extends CPropertiesResultStorer<Path>
    {
        public LibraryDirectoryResultStorer (final CProperties _props) {
            super(_props);
        }
        @Override
        public void Store (final Path libdir) {
            props.AddLibraryDrectory(libdir);
        }
    };
    //
    private class IncludeDirectoryResultStorer
            extends CPropertiesResultStorer<Path>
    {
        public IncludeDirectoryResultStorer (final CProperties _props) {
            super(_props);
        }
        @Override
        public void Store (final Path incldir) {
            props.AddIncludeDirectory(incldir);
        }
    };

    // -------------------------------------

    private static <K,V> void _u_transform (final Map<V,V> mappings,
                                            final Map<V,Integer> orderings,
                                            final Iterable<? extends V> items,
                                            final MappabilityChecker<V> mc,
                                            final OrderabilityChecker<V> oc,
                                            final CPropertiesResultStorer<V> rs)
    {
        final List<V> unordered = new LinkedList<>();
        final SortedSet<V> ordered =
                new TreeSet<>(new OrderingComparator<V>(orderings));

        for (final V value: items) {
            V newValue = value;
            if (mc.IsMappable(value))
                newValue = mappings.get(value);

            if (newValue != null) {
                if (oc.IsOrderable(value))
                    ordered.add(newValue);
                else
                    unordered.add(newValue);
            }
            // else: newValue == null => should be omitted
        }

        for (final V val: unordered)
            rs.Store(val);
        for (final V val: ordered)
            rs.Store(val);
    }
}
