package jd2m.solution;

public class SolutionLoadedData {

    private final ConfigurationManager  _m;
    private final ProjectEntryHolder    _h;
    private final PathResolver          _r;
    public SolutionLoadedData ( ConfigurationManager m, ProjectEntryHolder h,
                                PathResolver r)
    {
        _m = m;
        _h = h;
        _r = r;
    }

    /** m for <strong>M</strong>anager
     */
    public ConfigurationManager m () {
        return _m;
    }

    /** h for <strong>H</strong>older */
    public ProjectEntryHolder h () {
        return _h;
    }

    /** r for Path<strong>R</strong>esolver */
    public PathResolver r () {
        return _r;
    }
}
