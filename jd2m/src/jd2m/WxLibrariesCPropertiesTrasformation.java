package jd2m;


import java.util.Set;
import java.util.LinkedList;
import java.util.List;
import java.util.Comparator;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Map;
import jd2m.cbuild.AbstractCPropertiesMapper;
import jd2m.cbuild.CProperties;

import static java.util.Collections.unmodifiableMap;

/**
 *
 * @author muhtaris
 */
public class WxLibrariesCPropertiesTrasformation extends 
                                                    AbstractCPropertiesMapper
{

    public static final Map<String, String>     WinToLinuxNames;
    public static final Map<String, Integer>    OrderingMapping;

    // Windows Libraries Names
    public static final String WX28UD_ADV_WIN   = "wxmsw28ud_adv";
    public static final String WX28UD_AUI_WIN   = "wxmsw28ud_aui";

    // Linux Libraries Names
    public static final String WX28UD_ADV_LINUX  = "SOMETHING_LINUX_wxmsw28ud_adv";
    public static final String WX28UD_AUI_LINUX  = "SOMETHING_LINUX_wxmsw28ud_aui";

    // Linux Libraries Ordering Values
    public static final int WX28UD_ADV_ORDER = 20; // TODO replace with actual value
    public static final int WX28UD_AUI_ORDER = 10; // TODO replace with actual value

    static {
        final Map<String, String> wxWinToLinuxName = new HashMap<>(20);
        wxWinToLinuxName.put(WX28UD_ADV_WIN, WX28UD_ADV_LINUX);
        wxWinToLinuxName.put(WX28UD_AUI_WIN, WX28UD_AUI_LINUX);
        // TODO complete win to linux wx libs name mapping
        WinToLinuxNames = unmodifiableMap(wxWinToLinuxName);

        // ----

        final Map<String, Integer> orderingMapping = new HashMap<>(20);
        orderingMapping.put(WX28UD_ADV_LINUX, WX28UD_ADV_ORDER);
        orderingMapping.put(WX28UD_AUI_LINUX, WX28UD_AUI_ORDER);
        // TODO complete linux wx lib ordering
        OrderingMapping = unmodifiableMap(orderingMapping);
    }
    private static final Set<String> WindowsReplacableLibraries =
                                                    WinToLinuxNames.keySet();
    private final static Comparator<String> LinuxLibsOrderingComparator =
            new Comparator<>() {
                @Override
                public int compare (final String lib0, final String lib1) {
                    final Integer ordering0 = OrderingMapping.get(lib0);
                    if (ordering0 == null)
                        throw new RuntimeException("Lib " + lib0 +
                                " not found in orderings");
                    final Integer ordering1 = OrderingMapping.get(lib1);
                    if (ordering1 == null)
                        throw new RuntimeException("Lib " + lib1 +
                                " not found in orderings");

                    final int result = ordering0.compareTo(ordering1);
                    return result;
                }
            };


    public static boolean IsAReplacableWindowLibrary (final String lib) {
        final boolean result = WindowsReplacableLibraries.contains(lib);
        return result;
    }

    public static String TranslateWinLib (final String lib) {
        if (lib == null)
            throw new RuntimeException("null argument"); // TODO correct error handling

        final String result = WinToLinuxNames.get(lib);
        if (result == null)
            throw new RuntimeException("mapping for " + lib +
                    " does not exist");  // TODO correct error handling

        return result;
    }

    @Override
    public boolean IsApplicableTo (final CProperties props) {
        boolean thereIsReplacableLibrary = false;
        
        final Iterator<String> libsIter =   props.GetAdditionalLibraries()
                                                .iterator();
        while (!thereIsReplacableLibrary && libsIter.hasNext())
            thereIsReplacableLibrary = IsAReplacableWindowLibrary(
                                                            libsIter.next());

        return thereIsReplacableLibrary;
    }

    @Override
    public CProperties ApplyTo (final CProperties props) {
        final CProperties result = new CProperties();
        //
        CopyDefinitions(props, result);
        CopyIncludeDirectories(props, result);
        CopyLibraryDirectories(props, result);
        {
            final List<String> normalLibs = new LinkedList<>();
            final SortedSet<String> replacedLibs = new TreeSet<>(
                                                LinuxLibsOrderingComparator);
            for (final String lib: props.GetAdditionalLibraries())
                if (IsAReplacableWindowLibrary(lib))
                    replacedLibs.add(TranslateWinLib(lib));
                else
                    normalLibs.add(lib);

            for (final String lib: normalLibs)
                result.AddLibrary(lib);
            for (final String lib: replacedLibs)
                result.AddLibrary(lib);
        }
        return result;
    }

}
