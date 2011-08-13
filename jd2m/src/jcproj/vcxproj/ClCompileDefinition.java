package jcproj.vcxproj;

/**
 *
 * @date Sunday 7th of August 2011
 * @author amalia
 */
public class ClCompileDefinition extends ItemDefinition {
    
    ///////////////////////////////////////////////////////
    
    public String GetPrecompiledHeader () {
        return precompiledHeader;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetWarningLevel () {
        return warningLevel;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetOptimization () {
        return optimization;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetPreprocessorDefinitions () {
        return preprocessorDefinitions;
    }
    
    ///////////////////////////////////////////////////////

    public String GetPrecompiledHeaderFile () {
        return precompiledHeaderFile;
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetObjectFileName () {
        return objectFileName;
    }  
    
    ///////////////////////////////////////////////////////
    
    public String GetFunctionLevelLinking () {
        return functionLevelLinking;
        
    }
    
    ///////////////////////////////////////////////////////
    
    public String GetIntrinsicFunctions () {
        return intrinsicFunctions;
    }
    
    ///////////////////////////////////////////////////////
    
    public ClCompileDefinition (
            final String    precompiledHeader,
            final String    warningLevel,
            final String    optimization,
            final String    preprocessorDefinitions,
            final String    precompiledHeaderFile,
            final String    objectFileName,
            final String    functionLevelLinking,
            final String    intrinsicFunctions)
    {
        this.precompiledHeader          = precompiledHeader;
        this.warningLevel               = warningLevel;
        this.optimization               = optimization;
        this.preprocessorDefinitions    = preprocessorDefinitions;
        this.precompiledHeaderFile      = precompiledHeaderFile;
        this.objectFileName             = objectFileName;
        this.functionLevelLinking       = functionLevelLinking;
        this.intrinsicFunctions         = intrinsicFunctions;
    }
    
    ///////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////
    // Private
    
    ///////////////////////////////////////////////////////
    // State
    private final String precompiledHeader;
    private final String warningLevel;
    private final String optimization;
    private final String preprocessorDefinitions;
    private final String precompiledHeaderFile;
    private final String objectFileName;
    private final String functionLevelLinking;
    private final String intrinsicFunctions;
    
} // class ClCompile
