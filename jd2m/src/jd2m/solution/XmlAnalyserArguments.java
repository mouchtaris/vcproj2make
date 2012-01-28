package jd2m.solution;

final class XmlAnalyserArguments {
    final ConfigurationManager  configurationManager;
    final ProjectEntryHolder    projectEntryHolder;
    final PathResolver          pathResolver;

    XmlAnalyserArguments (  final ConfigurationManager  _configurationManager,
                            final ProjectEntryHolder    _projectEntryHolder,
                            final PathResolver          _pathResolver)
    {
        configurationManager    = _configurationManager;
        projectEntryHolder      = _projectEntryHolder;
        pathResolver            = _pathResolver;
    }
}
