package jcproj.loading;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * @date 7th of august 2011
 * @author amalia
 */
public final class ConfigurationManager {
    
    ///////////////////////////////////////////////////////
    
    public void RegisterSolutionConfiguration (final String config) {
        Loagger.log(Level.INFO, "Registered solution configuration: {0}", config);
        
        final Object previous = configs.put(config, new HashSet<ProjectConfigurationEntry>());
        assert previous == null;
    }
    
    ///////////////////////////////////////////////////////
    
    public void RegisterProjectEntryUnder (final String configid, final ProjectConfigurationEntry entry) {
        Loagger.log(Level.INFO, "Registering entry {0} under {1}", new Object[]{entry, configid});
        
        final boolean inserted = configs.get(configid).add(entry);
        assert inserted;
    }
    
    ///////////////////////////////////////////////////////
    
    /**
     * @return { solution configuration id => { {@link ProjectConfigurationEntry}-s } }
     */
    public Map<String, Set<ProjectConfigurationEntry>> GetProjectConfigurationEntries () {
        return configs;
    }
    
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    // Private
    private Map<String, Set<ProjectConfigurationEntry>> configs = new HashMap<>();
    
    private final static Logger Loagger = Logger.getLogger(ConfigurationManager.class.getName());
    
} // class SolutionConfigurationManager
