package jcproj.cbuild;

public enum CProjectType {
    DynamicLibrary  ("so"),
    StaticLibrary   ("a"),
    Executable      ("exe")
    ;

    private final String _extension;
    private CProjectType (final String extension) {
        _extension = extension;
    }

    public String GetExtension () {
        return _extension;
    }
}
