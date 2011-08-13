package jcproj.cbuild.exceptions;

/**
 *
 * @author muhtaris
 */
public class SimpleMappingAndOrderingCPropertiesTransformationException
    extends RuntimeException
{
    private static final long serialVersionUID = 234782l;
    
    public SimpleMappingAndOrderingCPropertiesTransformationException (final Throwable cause) {
        super(cause);
    }

    public SimpleMappingAndOrderingCPropertiesTransformationException (final String message, final Throwable cause) {
        super(message, cause);
    }

    public SimpleMappingAndOrderingCPropertiesTransformationException (final String message) {
        super(message);
    }

    public SimpleMappingAndOrderingCPropertiesTransformationException () {
    }
}
