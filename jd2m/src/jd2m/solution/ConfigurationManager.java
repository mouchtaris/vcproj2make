package jd2m.solution;

import java.util.HashMap;
import java.util.Map;
import jd2m.util.ProjectId;

public final class ConfigurationManager {
    private final class ProjectInfo {
        final String    configurationId;
        private boolean buildable;
        ProjectInfo (final String _configurationId) {
            configurationId = _configurationId;
            buildable       = false;
        }

        void MarkBuildable () {
            buildable = true;
        }
    }
    /**
     * SolutionConfigurationId -> { ProjectConfigurationId -> {@link
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
                                                        final String projConf)
    {
        boolean result = true;
        final Map<String, ProjectInfo> solutionRegistrations =
                _configurations.get(solConf);
        if (solutionRegistrations == null)
            result = false;
        else {
            final ProjectInfo pi = solutionRegistrations.get(projConf);
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
}
