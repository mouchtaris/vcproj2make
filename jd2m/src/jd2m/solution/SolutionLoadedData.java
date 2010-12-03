package jd2m.solution;

public class SolutionLoadedData {

    private final ConfigurationManager  _m;
    private final ProjectEntryHolder    _h;
    public SolutionLoadedData (ConfigurationManager m, ProjectEntryHolder h) {
        _m = m;
        _h = h;
    }

    /** m for Manager
     */
    public ConfigurationManager m () {
        return _m;
    }

    /** h for Holder */
    public ProjectEntryHolder h () {
        return _h;
    }
}
