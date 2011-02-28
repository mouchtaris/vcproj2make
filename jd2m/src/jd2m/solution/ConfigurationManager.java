package jd2m.solution;

import java.util.HashMap;
import java.util.Map;
import jd2m.util.ProjectId;

import static java.util.Collections.unmodifiableMap;

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
    private final Map<String, Map<ProjectId, ProjectInfo>> _configurations =
            new HashMap<String, Map<ProjectId, ProjectInfo>>(20);

    public void RegisterConfiguration (final String confName) {
        final Object previous = _configurations.put(confName,
                new HashMap<ProjectId, ProjectInfo>(100));
        assert previous == null;
    }

    public void RegisterProjectConfiguration (  final String solConfName,
                                                final String projIdStr,
                                                final String projConfName)
    {
        final Map<ProjectId, ProjectInfo> solConf =
                _configurations.get(solConfName);
        final ProjectId projId = ProjectId.GetIfExists(projIdStr);
        if (projId == null)
            throw new RuntimeException("Project " + projIdStr + " not registered"); // TODO proper error handling
        final Object previous = solConf
                .put(projId, new ProjectInfo(projConfName));
        assert previous == null;
    }

    public boolean HasRegisteredProjectConfiguration (  final String solConf,
                                                        final String projIdStr)
    {
        boolean result = true;
        final Map<ProjectId, ProjectInfo> solutionRegistrations =
                _configurations.get(solConf);
        if (solutionRegistrations == null)
            result = false;
        else {
                final ProjectId projId = ProjectId.GetIfExists(projIdStr);
                if (projId != null) {
                    final ProjectInfo pi = solutionRegistrations.get(projId);
                    if (pi == null)
                        result = false;
                }
                else
                    result = false;
        }
        return result;
    }

    public void MarkBuildable (final String solConfName, final String pjIdStr) {
        final Map<ProjectId, ProjectInfo> configurationInfo = _configurations.
                get(solConfName);
        final ProjectId projId = ProjectId.Get(pjIdStr);
        assert projId != null;
        final ProjectInfo projectInfo = configurationInfo.get(projId);
        projectInfo.MarkBuildable();
    }

    /**
     *
     * @return the internal {@link #_configurations}
     */
    public Map<String, Map<ProjectId, ProjectInfo>> GetConfigurations () {
        return unmodifiableMap(_configurations);
    }
}
