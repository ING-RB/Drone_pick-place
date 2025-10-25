classdef FileExtensionLiaison < handle
    % This class is undocumented and will change in a future release.
    
    % FileExtensionLiaison - Class to handle communication between FileExtensionServices.
    %
    % See Also: FileExtensionService, Service, ServiceLocator, ServiceFactory
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        ShortFile string;
        ResolvedFile string;
        ContainingFolder string;
        ParentName string;
        Extension string;
        UseResolvedFile logical = false;
        
        ClassFolder string = "";
        ClassFolderMethod string = "";
    end
    
    methods
        function liaison = FileExtensionLiaison(testFile, options)
            arguments
                testFile
                options.UseResolvedFile (1,1) logical = false
            end
            import matlab.unittest.internal.fileResolver;
            import matlab.unittest.internal.getParentNameFromFilename;
            import matlab.unittest.internal.getBaseFolderFromFilename;
            
            liaison.ShortFile = testFile;
            liaison.ResolvedFile = fileResolver(testFile);
            liaison.UseResolvedFile = options.UseResolvedFile;
            
            [~, methodOrClassName, ...
                liaison.Extension] = fileparts(liaison.ResolvedFile);
            liaison.ContainingFolder = getBaseFolderFromFilename(liaison.ResolvedFile);
            liaison.ParentName = getParentNameFromFilename(liaison.ResolvedFile);
            
            if liaison.ResolvedFile.contains(filesep + "@")
                liaison.ClassFolderMethod = methodOrClassName;
                liaison.ClassFolder = extractBetween(liaison.ResolvedFile, filesep+"@", filesep);
            end
        end
    end
end

