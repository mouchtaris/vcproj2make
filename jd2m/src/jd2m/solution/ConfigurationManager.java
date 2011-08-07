package jd2m.solution;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import jd2m.util.ProjectId;

import static java.util.Collections.unmodifiableMap;

public final class ConfigurationManager {
    /**
     * SolutionConfigurationId -> { ProhectID -> {@link
     * ProjectInfo} }
     */
    private final Map<String, Map<ProjectId, ProjectConfigurationEntry>> _configurations = new HashMap<String, Map<ProjectId, ProjectConfigurationEntry>>(20);

    public void RegisterConfiguration (final String confName) {
        final Object previous = _configurations.put(confName, new HashMap<ProjectId, ProjectConfigurationEntry>(100));
        assert previous == null;
    }

    public void RegisterProjectConfiguration (  final String solConfName,
                                                final String projIdStr,
                                                final String projConfName)
    {
        final Map<ProjectId, ProjectConfigurationEntry> solConf = _configurations.get(solConfName);
        
        if (solConf != null) {
            final ProjectId projId = ProjectId.GetIfExists(projIdStr);
            if (projId == null)
                throw new RuntimeException("Project " + projIdStr + " not registered"); // TODO proper error handling
            final Object previous = solConf.put(projId, new ProjectConfigurationEntry(projConfName));
            assert previous == null;
        }
        else
            LOG.log(Level.FINE, "Confiuration {0} is not registered and therefore project {1} is not registered under this configuration either.",
                        new Object[]{solConfName, projIdStr});
    }

    public boolean HasRegisteredProjectConfiguration (  final String solConf,
                                                        final String projIdStr)
    {
        boolean result = true;
        final Map<ProjectId, ProjectConfigurationEntry> solutionRegistrations = _configurations.get(solConf);
        
        if (solutionRegistrations == null)
            result = false;
        else {
                final ProjectId projId = ProjectId.GetIfExists(projIdStr);
                if (projId != null) {
                    final ProjectConfigurationEntry pi = solutionRegistrations.get(projId);
                    if (pi == null)
                        result = false;
                }
                else
                    result = false;
        }
        return result;
    }

    public void MarkBuildable (final String solConfName, final String pjIdStr) {
        final Map<ProjectId, ProjectConfigurationEntry> configurationInfo = _configurations.get(solConfName);
        final ProjectId projId = ProjectId.Get(pjIdStr);
        assert projId != null;
        final ProjectConfigurationEntry projectInfo = configurationInfo.get(projId);
        projectInfo.MarkBuildable();
    }

    /**
     *
     * @return the internal {@link #_configurations}
     */
    public Map<String, Map<ProjectId, ProjectConfigurationEntry>> GetConfigurations () {
        return unmodifiableMap(_configurations);
    }
    
    
    private static final Logger LOG = Logger.getLogger(ConfigurationManager.class.getName());
}
