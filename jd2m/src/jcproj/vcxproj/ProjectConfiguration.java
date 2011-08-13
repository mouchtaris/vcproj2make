package jcproj.vcxproj;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class ProjectConfiguration extends Item {

    ///////////////////////////////////////////////////////
    
    public String GetConfiguration () {
        return configuration;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetPlatform () {
        return platform;
    }
    
    ///////////////////////////////////////////////////////
    
    public ProjectConfiguration (final String include, final String configuration, final String platform) {
        super(include);
        this.configuration = configuration;
        this.platform = platform;
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final String configuration;
    private final String platform;
    
} // class ProjectConfiguration

