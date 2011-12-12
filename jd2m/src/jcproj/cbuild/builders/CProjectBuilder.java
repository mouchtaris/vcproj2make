package jcproj.cbuild.builders;

import java.util.LinkedList;
import java.util.List;
import jcproj.cbuild.CProject;
import jcproj.cbuild.CProperties;
import jcproj.vcxproj.ProjectGuid;
import jcproj.cbuild.CProjectType;
import jd2m.util.Name;

public final class CProjectBuilder {
    private boolean used = false;
    public CProject MakeProject () {
        if (used)
            throw new RuntimeException("Cannot reuse builder");
        if (_location       == null     ||
            _name           == null     ||
            _id             == null     ||
            _configuration  == null     ||
            _target         == null     ||
            _targetExt      == null     ||
            _output         == null     ||
            _intermediate   == null     ||
            _api            == null     ||
            _type           == null
        )
            throw new RuntimeException("Builder not complete");

        used = true;
        final CProject result = new CProject(_location, _name, _id, _configuration, _target, _targetExt, _output, _intermediate, _api, _type);
                
//                new CProject(_location, _name, _id,
//                _configuration, _target, _targetExt, _output, _intermediate,
//                _api, _type);
        for (final ProjectGuid depId: _deps)
            result.AddDependency(depId);
        result.AddProperties(_props);
        for (final String src: _sources)
            result.AddSource(src);

        return result;
    }

    private final List<CProperties> _props = new LinkedList<CProperties>();
    private String                  _location;
    private Name                    _name;
    private ProjectGuid             _id;
    private String                  _configuration;
    private String                  _target;
    private String                  _targetExt;
    private String                  _output;
    private String                  _intermediate;
    private String                  _api;
    private CProjectType            _type;
    private final List<ProjectGuid> _deps = new LinkedList<ProjectGuid>();
    private final List<String>      _sources = new LinkedList<String>();

    public void AddProperty      (final CProperties  p    ) { _props         .add(p);  }
    public void SetLocation      (final String       l    ) { _location      = l;      }
    public void SetName          (final Name         n    ) { _name          = n;      }
    public void SetId            (final ProjectGuid  id   ) { _id            = id;     }
    public void SetConfiguration (final String       c    ) { _configuration = c;      }
    public void SetTarget        (final String       trg  ) { _target        = trg;    }
    public void SetExt           (final String       ext  ) { _targetExt     = ext;    }
    public void SetOutput        (final String       out  ) { _output        = out;    }
    public void SetIntermediate  (final String       intm ) { _intermediate  = intm;   }
    public void SetApiDirectory  (final String       api  ) { _api           = api;    }
    public void SetType          (final CProjectType t    ) { _type          = t;      }
    public void AddDependency    (final ProjectGuid  dep  ) { _deps         .add(dep); }
    public void AddSource        (final String       src  ) { _sources      .add(src); }

    public String GetOutput () { return _output; }
}
