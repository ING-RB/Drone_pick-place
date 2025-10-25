classdef MATLABCodeFileExtensionService < matlab.unittest.internal.services.fileextension.FileExtensionService
    % This class is undocumented and will change in a future release.
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    properties (Constant)
        IncludedInNamespaces = true;
    end
    
    methods (Sealed)
        function suite = createSuiteExplicitly(~, liaison, modifier, externalParameters, varargin)
            import matlab.unittest.TestSuite;
            import matlab.unittest.internal.TestSuiteFactory;
            import matlab.unittest.internal.whichFile;
            import matlab.unittest.internal.services.namingconvention.AllowsAnythingNamingConventionService;
            
            if liaison.UseResolvedFile
                filenameFromIdentifier = liaison.ResolvedFile;
            else
                filenameFromIdentifier = getFilenameFromIdentifier(liaison);
            end
            [~, ~, extensionFromIdentifier] = fileparts(filenameFromIdentifier);
            if liaison.Extension ~= extensionFromIdentifier
                error(message("MATLAB:unittest:TestSuite:ShadowedFile", liaison.ShortFile, extensionFromIdentifier));
            end
            if liaison.ResolvedFile ~= filenameFromIdentifier
                error(message("MATLAB:unittest:TestSuite:FileShadowedByFile", liaison.ShortFile, filenameFromIdentifier));
            end
            
            if liaison.ClassFolderMethod == liaison.ClassFolder
                factory = TestSuiteFactory.fromParentName(liaison.ParentName, ...
                    AllowsAnythingNamingConventionService);
                suite = factory.createSuiteExplicitly(modifier, externalParameters, varargin{:});
            else
                mainClassFile = whichFile(liaison.ParentName);
                if strlength(mainClassFile) == 0
                    error(message("MATLAB:unittest:TestSuite:UnsupportedFile", liaison.ShortFile));
                end
                if fileparts(liaison.ResolvedFile) ~= fileparts(mainClassFile)
                    error(message("MATLAB:unittest:TestSuite:FileShadowedByFile", liaison.ShortFile, mainClassFile));
                end
                
                testClass = meta.class.fromName(liaison.ParentName);
                suite = TestSuite.fromMethod(testClass, liaison.ClassFolderMethod, modifier,...
                    "ExternalParameters",externalParameters);
            end
        end
        
        function suite = createSuiteImplicitly(~, liaison, modifier, externalParameters, varargin)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestSuiteFactory;
            import matlab.unittest.internal.testSuiteFileExtensionServices;
            
            filenameFromIdentifier = getFilenameFromIdentifier(liaison);
            if liaison.ResolvedFile == filenameFromIdentifier
                % This method assumes we are not creating a test suite for a
                % file in a class folder.
                assert(liaison.ClassFolderMethod == liaison.ClassFolder);
                
                factory = TestSuiteFactory.fromParentName(liaison.ParentName);
                suite = factory.createSuiteImplicitly(modifier, externalParameters, varargin{:});
                return;
            end
            
            services = testSuiteFileExtensionServices;
            [~, ~, extensionFromIdentifier] = fileparts(filenameFromIdentifier);
            if isempty(services.findServiceThatSupports(extensionFromIdentifier))
                warning(message("MATLAB:unittest:TestSuite:FileExcludedByShadowing", liaison.ShortFile, extensionFromIdentifier));
            end
            
            suite = Test.empty(1,0);
        end
    end
end

function filenameFromIdentifier = getFilenameFromIdentifier(liaison)
import matlab.unittest.internal.getFilenameFromParentName;
import matlab.unittest.internal.whichFile;
import matlab.unittest.internal.fileResolver;

if liaison.ClassFolderMethod == liaison.ClassFolder
    whichInput = liaison.ParentName;
else
    % Method in an @ folder
    whichInput = getFilenameFromParentName(liaison.ParentName) + ...
        "/" + liaison.ClassFolderMethod;
end

exception = MException.empty;
try
    filenameFromIdentifier = fileResolver(whichFile(whichInput));
catch exception
end
if ~isempty(exception) || strlength(filenameFromIdentifier) == 0
    filenameFromIdentifier = liaison.ResolvedFile;
end
end

% LocalWords:  fileextension strlength namingconvention
