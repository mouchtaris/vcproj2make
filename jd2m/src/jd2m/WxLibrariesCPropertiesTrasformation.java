package jd2m;


import java.util.Map.Entry;
import java.util.HashMap;
import java.util.Map;
import jd2m.cbuild.SimpleMappingAndOrderingCPropertiesTransformation;

import static java.util.Collections.unmodifiableMap;

/**
 *
 * @author muhtaris
 */
final class WxLibrariesCPropertiesTrasformation extends
                            SimpleMappingAndOrderingCPropertiesTransformation
{

    public static final Map<String, String>     WinToLinuxNames;
    public static final Map<String, Integer>    OrderingMapping;

    // Windows Libraries Names
    public static final String WX28UD_ADV_WIN   = "wxmsw28ud_adv";
    public static final String WX28UD_AUI_WIN   = "wxmsw28ud_aui";

    // Linux Libraries Names
    public static final String WX28UD_ADV_LINUX  = null;//"SOMETHING_LINUX_wxmsw28ud_adv";
    public static final String WX28UD_AUI_LINUX  = null;//"SOMETHING_LINUX_wxmsw28ud_aui";
    public static final String UNIX_DYNAMIC_LIBRARY_LOADING_AND_LINKING_LIBRARY = "dl";
    public static final String UNIX_POSIX_THREADS_LIBRARY = "pthread";

    // Linux Libraries Ordering Values
    public static final int WX28UD_ADV_ORDER = 20; // TODO replace with actual value
    public static final int WX28UD_AUI_ORDER = 10; // TODO replace with actual value

    static {
        final Map<String, String> wxWinToLinuxName = new HashMap<String, String>(20);
        wxWinToLinuxName.put(WX28UD_ADV_WIN, WX28UD_ADV_LINUX);
        wxWinToLinuxName.put(WX28UD_AUI_WIN, WX28UD_AUI_LINUX);
        // TODO complete win to linux wx libs name mapping
        WinToLinuxNames = unmodifiableMap(wxWinToLinuxName);

        // ----

        final Map<String, Integer> orderingMapping = new HashMap<String, Integer>(20);
        orderingMapping.put(WX28UD_ADV_LINUX, WX28UD_ADV_ORDER);
        orderingMapping.put(WX28UD_AUI_LINUX, WX28UD_AUI_ORDER);
        // TODO complete linux wx lib ordering
        OrderingMapping = unmodifiableMap(orderingMapping);
    }
    

    public WxLibrariesCPropertiesTrasformation () {
        for (final Entry<String, String> libMapping: WinToLinuxNames.entrySet())
            SetLibraryMapping(libMapping.getKey(), libMapping.getValue());

        for (final Entry<String, Integer> libOrdering: OrderingMapping.entrySet())
            SetLibraryOrderingValue(libOrdering.getKey(), libOrdering.getValue());

        SetDefinitionMapping("WIN32", null);
        SetDefinitionMapping("_WINDOWS", null);
        SetDefinitionMapping("_WIN32_", null);
        //
        AddDefinition("_LINUX_");
        AddDefinition("_UNIX_");
        AddDefinition("DELTA_SUICIDAL_VM_ERROR");
        AddDefinition("DELTA_ZOMBIE_VM_ERROR");
        AddDefinition("DELTA_PROFILE_ACTIVATED");
        AddDefinition("NO_VLD");
        AddDefinition("DELTA_ENABLE_ASSIGNMENT_AND_RETURN_WARNINGS");
        //
        for (final String lib2nullify: new String[]{
                "winmm", "ws2_32", "wxmsw28ud_html", "wxmsw28ud_core",
                "wxmsw28ud_richtext", "wxbase28ud", "wxbase28ud_xml",
                "wxtiffd", "wxjpegd", "wxpngd", "wxzlibd", "wxexpatd",
                "comctl32", "rpcrt4", "wsock32", "oleacc", "iphlpapi",
                "odbc32", "odbccp32", "wxmsw28u_adv", "wxmsw28u_aui",
                "wxmsw28u_html", "wxmsw28u_core", "wxmsw28u_richtext",
                "wxbase28u", "wxbase28u_xml", "wxtiff", "wxjpeg",
                "wxpng", "wxzlib", "wxexpat"})
            SetLibraryMapping(lib2nullify, null);
        //
        AddLibrary(UNIX_DYNAMIC_LIBRARY_LOADING_AND_LINKING_LIBRARY);
        AddLibrary(UNIX_POSIX_THREADS_LIBRARY);
    }
}
