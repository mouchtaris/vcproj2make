package jd2m.solution;

public class SolutionLoadedData {

    private final ConfigurationManager  _m;
    private final ProjectEntryHolder    _h;
    private final PathResolver          _r;
    private final VariableEvaluator     _e;
    private final String                _n;
    public SolutionLoadedData ( ConfigurationManager m,
                                ProjectEntryHolder h,
                                PathResolver r,
                                VariableEvaluator e,
                                String n)
    {
        _m = m;
        _h = h;
        _r = r;
        _e = e;
        _n = n;
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

    /** e for Variable<strong>E</strong>valuator */
    public VariableEvaluator e () {
        return _e;
    }

    /** n for Solution<strong>N</strong>ame */
    public String n () {
        return _n;
    }
}
