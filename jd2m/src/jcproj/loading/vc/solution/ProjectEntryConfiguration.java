package jcproj.loading.vc.solution;

import jcproj.cbuild.ConfigurationId;

public class ProjectEntryConfiguration {
	
	///////////////////////////////////////////////////////
	// State
	private final boolean buildable;
	private final ConfigurationId configuration;
	
	///////////////////////////////////////////////////////
	// Constructors
	public ProjectEntryConfiguration (
			final boolean			buildable,
			final ConfigurationId	configuration) {
		this.buildable		= buildable;
		this.configuration	= configuration;
	}
	
	///////////////////////////////////////////////////////
	//
	public boolean IsBuildable () {
		return buildable;
	}
	
	public ConfigurationId GetConfiguration () {
		assert IsBuildable();
		return configuration;
	}
}
