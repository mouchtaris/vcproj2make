package jd2m.project;

import jd2m.util.ProjectId;

final class XmlAnalyserArguments {
    // for validation
    final String        name;
    final ProjectId     id;

    XmlAnalyserArguments (  final String        _name,
                            final ProjectId     _id)
    {
        name        = _name;
        id          = _id;
    }
}
