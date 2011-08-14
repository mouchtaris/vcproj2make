package jcproj.vcxproj.xml;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class Property extends Element {
    
    ///////////////////////////////////////////////////////
    
    public String GetId () {
        return id;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetValue () {
        return value;
    }
    
    ///////////////////////////////////////////////////////
    
    public Property (final String id, final String value) {
        this.id = id;
        this.value = value;
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final String id;
    private final String value;

} // class Property
