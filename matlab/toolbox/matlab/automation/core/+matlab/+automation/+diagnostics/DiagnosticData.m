classdef(Hidden) DiagnosticData < matlab.mixin.Heterogeneous
    % DiagnosticData - Data that ExtendedDiagnostic instances may react to
    %
    %   The testing framework passes in a DiagnosticData instance to the
    %   diagnoseWith method of the ExtendedDiagnostic subclass which
    %   contains data specific to the current test run environment.
    %
    %   DiagnosticData properties:
    %       ArtifactsStorageFolder - Folder where diagnostic artifacts should be saved
    %       Verbosity - Level of detail diagnostics should provide when diagnosed
    %       ArtifactsDisplayFolder - Folder where diagnostic artifacts can be accessed
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess=private)
        % ArtifactsStorageFolder - Folder where diagnostic artifacts should be saved
        ArtifactsStorageFolder (1,1) string = missing;
        
        % Verbosity - Level of detail diagnostics should provide when diagnosed
        Verbosity (1,1) matlab.automation.Verbosity;
        
        % ArtifactsDisplayFolder - Folder from where diagnostic artifacts
        % can be accessed after test run
        ArtifactsDisplayFolder (1,1) string = missing;
    end
    
    properties(Constant, Hidden)
        DefaultInstance = matlab.automation.diagnostics.DiagnosticData();
    end
    
    properties (Hidden,SetAccess = private)
        FilesepToCreateDisplayFilename string
    end
    
    methods(Hidden)
        function diagData = DiagnosticData(namedargs)
            arguments
                namedargs.ArtifactsStorageFolder (1,1) string {matlab.automation.internal.mustBeTextScalar(namedargs.ArtifactsStorageFolder, "ArtifactsStorageFolder")};
                namedargs.ArtifactsDisplayFolder (1,1) string {matlab.automation.internal.mustBeTextScalar(namedargs.ArtifactsDisplayFolder, "ArtifactsDisplayFolder")}
                namedargs.Verbosity (1,1) matlab.automation.Verbosity = matlab.automation.Verbosity.Detailed;
                namedargs.FilesepToCreateDisplayFilename (1,1) string = string(filesep);
            end
            
            if isfield(namedargs, "ArtifactsStorageFolder")
                diagData.ArtifactsStorageFolder = namedargs.ArtifactsStorageFolder;
            end
            
            if isfield(namedargs, "ArtifactsDisplayFolder")
                diagData.ArtifactsDisplayFolder = namedargs.ArtifactsDisplayFolder;
            end            
            diagData.Verbosity = namedargs.Verbosity;
            diagData.FilesepToCreateDisplayFilename = namedargs.FilesepToCreateDisplayFilename;
        end
        
        function displayFileName = createDisplayFileName(diagData,file)
            [~,fileName,ext] = fileparts(file);
            displayFileName = strip(diagData.ArtifactsDisplayFolder, 'right', diagData.FilesepToCreateDisplayFilename) + ...
                diagData.FilesepToCreateDisplayFilename + fileName + ext;
        end
        
        function outDiagData = createDiagnosticDataFromPrototype(protoDiagData, namedargs)
            arguments
                protoDiagData (1,1) matlab.automation.diagnostics.DiagnosticData %#ok<INUSA>
                namedargs.ArtifactsStorageFolder (1,1) string {matlab.automation.internal.mustBeTextScalar(namedargs.ArtifactsStorageFolder, "ArtifactsStorageFolder")} = protoDiagData.ArtifactsStorageFolder;
                namedargs.ArtifactsDisplayFolder (1,1) string {matlab.automation.internal.mustBeTextScalar(namedargs.ArtifactsDisplayFolder, "ArtifactsDisplayFolder")} = protoDiagData.ArtifactsDisplayFolder
                namedargs.Verbosity (1,1) matlab.automation.Verbosity = protoDiagData.Verbosity
                namedargs.FilesepToCreateDisplayFilename (1,1) string = populateDefaultFilesep(protoDiagData)
            end
            
            outDiagData = matlab.automation.diagnostics.DiagnosticData('ArtifactsStorageFolder',namedargs.ArtifactsStorageFolder,...
                'ArtifactsDisplayFolder',namedargs.ArtifactsDisplayFolder,...
                'FilesepToCreateDisplayFilename',namedargs.FilesepToCreateDisplayFilename,...
                'Verbosity',namedargs.Verbosity);
        end
        
        function folder = getArtifactsStorageFolder(~, rawFolderValue)
            folder = rawFolderValue;
            if ismissing(folder)
                folder = string(tempdir);
            end
        end
    end
    
    methods
        function folder = get.ArtifactsStorageFolder(diagData)
            folder = diagData.getArtifactsStorageFolder(diagData.ArtifactsStorageFolder);
        end
        
        function folder = get.ArtifactsDisplayFolder(diagData)
            folder = diagData.ArtifactsDisplayFolder;
            if ismissing(folder)
                folder = diagData.ArtifactsStorageFolder;
            end
        end
    end
end

function defaultFilesep = populateDefaultFilesep(diagData)
defaultFilesep = diagData.FilesepToCreateDisplayFilename;
if isempty(defaultFilesep)
    defaultFilesep = string(filesep);
end
end

% LocalWords:  namedargs ismissing
