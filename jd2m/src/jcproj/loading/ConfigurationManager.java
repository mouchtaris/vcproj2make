package jcproj.loading;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * @date 7th of august 2011
 * @author amalia
 */
public class ConfigurationManager {
    
    ///////////////////////////////////////////////////////
    
    public void RegisterSolutionConfiguration (final String config) {
        Loagger.log(Level.INFO, "Registered solution configuration: {0}", config);
        
        final String[] tokens = SplitConfig(config);
        AddConfiguration(tokens[0], tokens[1]);
    }
    
    ///////////////////////////////////////////////////////
    
    public void RegisterProjectEntryUnder (final String config, final ProjectConfigurationEntry entry) {
        Loagger.log(Level.INFO, "Registering entry {0} under {1}", new Object[]{entry, config});
        
        final String[] tokens = SplitConfig(config);
        final boolean inserted = GetConfiguration(tokens[0], tokens[1]).add(entry);
        assert inserted;
    }
    
    ///////////////////////////////////////////////////////
    
    /**
     * @return { solution configuration id => { {@link ProjectConfigurationEntry}-s } }
     */
    public Map<String, Set<ProjectConfigurationEntry>> GetProjectConfigurationEntries () {
        return Collections.unmodifiableMap(configs);
    }
    
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    // Private
    private Map<String, Set<ProjectConfigurationEntry>> configs = new HashMap<>(20);
    private Map<String, Set<String>>                    platforms = new HashMap<>(20);
        
    private final static Logger Loagger = Logger.getLogger(ConfigurationManager.class.getName());
    
    private void AddConfiguration (final String config, final String platform) {
        final Object previous = configs.put(config, new HashSet<ProjectConfigurationEntry>(50));
        
        if (previous != null) {
            final Set<String> plats = platforms.get(config);
            
            if (plats.contains(platform))
                throw new RuntimeException("Configuration/platform re-registration (" + config + "|" + platform + ")");
            else
                plats.add(platform);
        }
        else {
            final Set<String> plats = new HashSet<>(10);
            plats.add(platform);
            
            final Object previousPlatformsEntry = platforms.put(config, plats);
            assert previousPlatformsEntry == null;
        }
    }
    
    private Set<ProjectConfigurationEntry> GetConfiguration (final String configid, final String platform) {
        Set<ProjectConfigurationEntry> entry = configs.get(configid);
        
        if (entry != null && platform != null)
            if (!platforms.get(configid).contains(platform))
                entry = null;
        
        return entry;
    }
    
    private static final Pattern __static_Pattern_Pipe = Pattern.compile("\\|");
    private String[] SplitConfig (final String config) {
        String[] tokens = __static_Pattern_Pipe.split(config);
        if (tokens.length < 2)
            tokens = new String[] { tokens[0], null };
        return tokens;
    }
    
} // class SolutionConfigurationManager
