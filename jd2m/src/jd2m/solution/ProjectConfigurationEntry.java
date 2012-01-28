
package jd2m.solution;

/**
 *
 * @author amalia
 */
public final class ProjectConfigurationEntry {
    final String configurationName;
    private boolean buildable;

    ProjectConfigurationEntry(final String _configurationId) {
        configurationName = _configurationId;
        buildable = false;
    }

    void MarkBuildable() {
        buildable = true;
    }

    public boolean IsBuildable() {
        return buildable;
    }

    public String GetConfigurationName() {
        return configurationName;
    }

}
