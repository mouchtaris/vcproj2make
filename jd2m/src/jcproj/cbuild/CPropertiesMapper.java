package jcproj.cbuild;

import java.nio.file.Path;

/**
 *
 * @author muhtaris
 */
public interface CPropertiesMapper extends CPropertiesTransformation {
    Path    MapIncludeDirectory (Path   includeDirectory);
    Path    MapLibraryDirectory (Path   libraryDirectory);
    String  MapDefinition       (String definition      );
    String  MapLibrary          (String library         );
}
