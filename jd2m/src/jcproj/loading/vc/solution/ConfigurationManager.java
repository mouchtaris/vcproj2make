package jcproj.loading.vc.solution;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import jcproj.cbuild.ConfigurationId;

/**
 * @date 7th of august 2011
 * @author amalia
 */
public class ConfigurationManager {
	
	///////////////////////////////////////////////////////
	// State
	private Map<ConfigurationId, Map<ProjectEntry, ProjectEntryConfiguration>> configs = new HashMap<ConfigurationId, Map<ProjectEntry, ProjectEntryConfiguration>>(20);
	private Map<ConfigurationId, Map<ProjectEntry, ProjectEntryConfiguration>> unmodifiables = Collections.unmodifiableMap(configs);
	

	///////////////////////////////////////////////////////

	public void RegisterSolutionConfiguration (final ConfigurationId configid) throws ConfigurationReregisteredException {
		Loagger.log(Level.INFO, "Registered solution configuration: {0}", configid);

		final HashMap<ProjectEntry, ProjectEntryConfiguration> entries = new HashMap<ProjectEntry, ProjectEntryConfiguration>(50);
		Object previous = configs.put(configid, entries);
		if (previous != null)
			throw new ConfigurationReregisteredException(configid.toString());
		
		previous = unmodifiables.put(configid, Collections.unmodifiableMap(entries));
		assert previous == null;
	}

	///////////////////////////////////////////////////////

	public void RegisterProjectEntryUnder (final ConfigurationId configid, final ProjectEntry entry, final ProjectEntryConfiguration entryconfig)
			throws
				ConfigurationNotFoundException,
				ProjectConfigurationEntryReaddedException
	{
		Loagger.log(Level.INFO, "Registering project configuration entry {0} under {1}", new Object[]{entry, configid});

		final Map<ProjectEntry, ProjectEntryConfiguration> entries = configs.get(configid);
		if (entries == null)
			throw new ConfigurationNotFoundException(configid.toString());

		final Object previous = entries.put(entry, entryconfig);
		if (previous != null)
			throw new ProjectConfigurationEntryReaddedException(entry.toString() + " under " + configid.toString());
	}

	///////////////////////////////////////////////////////

	/**
	 * @return Map_of{ Solution_{@link ConfigurationId} => Map_of{ {@link ProjectEntry} => {@link ProjectEntryConfiguration} } }
	 */
	@SuppressWarnings("ReturnOfCollectionOrArrayField")
	public Map<ConfigurationId, Map<ProjectEntry, ProjectEntryConfiguration>> GetConfiguration () {
		return unmodifiables;
	}

	///////////////////////////////////////////////////////
	///////////////////////////////////////////////////////
	// Private

	private final static Logger Loagger = Logger.getLogger(ConfigurationManager.class.getName());

}
