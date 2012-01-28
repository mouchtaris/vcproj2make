package jcproj.cbuild;

import java.util.HashMap;
import java.util.Map;

public class ConfigurationIdManager {
	///////////////////////////////////////////////////////
	// state
	private final Map<String, ConfigurationId> configids = new HashMap<String, ConfigurationId>(20);
	
	///////////////////////////////////////////////////////
	//
	public ConfigurationId Register (final ConfigurationId configid) throws ConfigurationIdReregisteredException{
		if (configids.containsKey(configid.GetId()))
			throw new ConfigurationIdReregisteredException(configid.GetId());
		configids.put(configid.GetId(), configid);
		return configid;
	}
	
	public boolean Has (final String id) {
		return configids.containsKey(id);
	}
	
	public ConfigurationId Get (final String id) throws ConfigurationIdNotFoundException {
		if (!Has(id))
			throw new ConfigurationIdNotFoundException(id);
		return configids.get(id);
	}
}
