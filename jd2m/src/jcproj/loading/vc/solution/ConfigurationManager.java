package jcproj.loading.vc.solution;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.cbuild.ConfigurationId;

/**
 * @date 7th of august 2011
 * @author amalia
 */
public class ConfigurationManager {

	///////////////////////////////////////////////////////

	public void RegisterSolutionConfiguration (final ConfigurationId configid) throws ConfigurationReregisteredException {
		Loagger.log(Level.INFO, "Registered solution configuration: {0}", configid);

		if (configs.containsKey(configid))
			throw new ConfigurationReregisteredException(configid.toString());
		configs.put(configid, new HashSet<ProjectConfigurationEntry>(50));
	}

	///////////////////////////////////////////////////////

	public void RegisterProjectEntryUnder (final ConfigurationId configid, final ProjectConfigurationEntry entry) throws ConfigurationNotFoundException, ProjectConfigurationEntryReaddedException {
		Loagger.log(Level.INFO, "Registering project configuration entry {0} under {1}", new Object[]{entry, configid});

		final Set<ProjectConfigurationEntry> entries = configs.get(configid);
		if (entries == null)
			throw new ConfigurationNotFoundException(configid.toString());

		boolean added = entries.add(entry);
		if (!added)
			throw new ProjectConfigurationEntryReaddedException(entry.toString() + " under " + configid.toString());
	}

	///////////////////////////////////////////////////////

	/**
	 * @return { solution configuration id => { {@link ProjectConfigurationEntry}-s } }
	 */
	public Map<ConfigurationId, Set<ProjectConfigurationEntry>> GetProjectConfigurationEntries () {
		return Collections.unmodifiableMap(configs);
	}

	///////////////////////////////////////////////////////
	///////////////////////////////////////////////////////
	// Private
	private Map<ConfigurationId, Set<ProjectConfigurationEntry>> configs = new HashMap<ConfigurationId, Set<ProjectConfigurationEntry>>(20);

	private final static Logger Loagger = Logger.getLogger(ConfigurationManager.class.getName());

}
