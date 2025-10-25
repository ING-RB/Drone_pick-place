function uid = generateUidFromFilepath(filepath)
    %GENERATEUIDFROMFILEPATH 

%   Copyright 2023-2024 The MathWorks, Inc.

    arguments
        filepath string
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    fileContent = appdesigner.internal.cacheservice.readAppFile(char(filepath));

    componentXmlString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
        fileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);
    
    uid = appdesigner.internal.cacheservice.generateUid(filepath + componentXmlString);
end
