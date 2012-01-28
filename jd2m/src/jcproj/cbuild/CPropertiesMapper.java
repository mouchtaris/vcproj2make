package jcproj.cbuild;

/**
 *
 * @author muhtaris
 */
public interface CPropertiesMapper extends CPropertiesTransformation {
    String	MapIncludeDirectory	(String includeDirectory);
    String	MapLibraryDirectory	(String libraryDirectory);
    String	MapDefinition		(String definition		);
    String	MapLibrary			(String library			);
}
