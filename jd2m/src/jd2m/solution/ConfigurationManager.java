package jd2m.solution;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import jd2m.util.ProjectId;

public final class ConfigurationManager {
    public final class ProjectInfo {
        final String    configurationName;
        private boolean buildable;
        private ProjectInfo (final String _configurationId) {
            configurationName = _configurationId;
            buildable       = false;
        }

        private void MarkBuildable () {
            buildable = true;
        }

        public boolean IsBuildable () {
            return buildable;
        }

        public String GetConfigurationName () {
            return configurationName;
        }
    }
    /**
     * SolutionConfigurationId -> { ProhectID -> {@link
     * ProjectInfo} }
     */
    private final Map<String, Map<String, ProjectInfo>> _configurations =
            new HashMap<>(20);

    public void RegisterConfiguration (final String confName) {
        final Object previous = _configurations.put(confName,
                new HashMap<String, ProjectInfo>(100));
        assert previous == null;
    }

    public void RegisterProjectConfiguration (  final String solConfName,
                                                final String projId,
                                                final String projConfName)
    {
        assert ProjectId.Get(projId) != null;
        final Map<String, ProjectInfo> solConf =
                _configurations.get(solConfName);
        final Object previous =
                solConf.put(projId, new ProjectInfo(projConfName));
        assert previous == null;
    }

    public boolean HasRegisteredProjectConfiguration (  final String solConf,
                                                        final String projId)
    {
        boolean result = true;
        final Map<String, ProjectInfo> solutionRegistrations =
                _configurations.get(solConf);
        if (solutionRegistrations == null)
            result = false;
        else {
            final ProjectInfo pi = solutionRegistrations.get(projId);
            if (pi == null)
                result = false;
        }
        return result;
    }

    public void MarkBuildable ( final String solConfName, final String projId) {
        final Map<String, ProjectInfo> configurationInfo = _configurations.
                get(solConfName);
        final ProjectInfo projectInfo = configurationInfo.get(projId);
        projectInfo.MarkBuildable();
    }

    /**
     *
     * @return the internal {@link #_configurations}
     */
    public Map<String, Map<String, ProjectInfo>> GetConfigurations () {
        return Collections.unmodifiableMap(_configurations);
    }
}
