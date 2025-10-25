%   This class is unsupported and might change or be removed without
%   notice in a future version. 
classdef ImportableFileIdentifier
    %

    % Copyright 2016-2020 The MathWorks, Inc.
    %
    % This class is used primarily by uiimport and its associated
    % functionality.
    
    methods(Static)
        function multiFileImport = supportsMultiFileImport(filelist)
            % Given a list of files, returns whether they will all support
            % being opened for import simultaneously.  For example, some
            % import tools support multiple files (like the spreadsheet
            % import tool), while others do not.
            import internal.matlab.importtool.ImportableFileIdentifier;
            
            filelist = string(filelist);
            
            multiFileImport = true;
            importWizardCount = 0;
            for idx = 1:length(filelist)
                if ImportableFileIdentifier.usesImportWizard(filelist(idx))
                    importWizardCount = importWizardCount + 1;
                    
                    if importWizardCount > 1
                        multiFileImport = false;
                        break;
                    end
                end
            end
        end
        
        function b = usesImportWizard(filename)
            % Returns true if the given file is imported using the Import
            % Wizard, false otherwise.
            import internal.matlab.importtool.ImportableFileIdentifier;
            
            type = finfo(char(filename));
            if ImportableFileIdentifier.useSpreadsheetImportTool(false, type)
                b = false;
            elseif ImportableFileIdentifier.useTextImportTool(false, filename)
                b = false;
            else
                b = true;
            end
        end
        
        function b = isImportWizardOpen
            % Returns true if the Import Wizard is currently open
            import internal.matlab.importtool.ImportableFileIdentifier;
            i = ImportableFileIdentifier.getSetImportWizardInstance;
            b = ~isempty(i);
        end
        
        function bringImportWizardToFront
            % Brings the Import Wizard to the front if it is currently open
            import internal.matlab.importtool.ImportableFileIdentifier;
            i = ImportableFileIdentifier.getSetImportWizardInstance;
            if ~isempty(i)
                i.toFront;
            end
        end
        
        function b = getSetImportWizardInstance(varargin)
            mlock;
            % Returns the singleton instance of the Import Wizard
            persistent asynchronousInstance;
            if nargin == 1
                newInstance = varargin{1};
                asynchronousInstance = newInstance;
            else
                b = asynchronousInstance;
            end
        end
        
        function state = useSpreadsheetImportTool(isSynchronous, type)
            % Returns true if the file of the given type and synchronous
            % flag will import using the Spreadsheet Import Tool
            state =  ~isSynchronous && ...
                any(strcmpi(type, ...
                internal.matlab.importtool.ImportableFileExtension.getSpreadsheetFileExtensions(false)));
        end
        
        function state = useTextImportTool(isSynchronous, fileAbsolutePath, varargin)
            % Returns true if the given file and synchronous flag will
            % import using the Text Import Tool
            state = ~isSynchronous;
            
            if state
                if nargin == 3
                    finfoType = varargin{1};
                else
                    finfoType = finfo(char(fileAbsolutePath));
                end
                state = internal.matlab.importtool.ImportableFileIdentifier.isTextFile(fileAbsolutePath, finfoType);
            end
        end
        
        function textfile = isTextFile(fileAbsolutePath, finfoType)
            % Returns true if the given file is a text file which will open
            % in the Text Import Tool
            import internal.matlab.importtool.ImportableFileExtension;
            [~, ~, fileExt] = fileparts(char(fileAbsolutePath));
            textfile = any(strcmpi(fileExt, ImportableFileExtension.getTextFileExtensions));
            if ~textfile                
                try
                    % extracting video file extensions
                    videoFileExt = ImportableFileExtension.getVideoFileExtensions(false);
                catch me %#ok<NASGU>
                    % Ideally should not get in here. No need to throw error.
                    videoFileExt = {};
                end
                
                try
                    % Get the list of supported audio file formats
                    audioFileExt = ImportableFileExtension.getAudioFileExtensions(false);
                catch me %#ok<NASGU>
                    % Ideally should not get in here. No need to throw error.
                    audioFileExt = {};
                end
                
                if any(strcmp(finfoType,{'ods','avi','audio','video','im','mat'}))
                    % Well-known audio/video types, and mat files are not text
                    textfile = false;
                elseif any(strcmp(finfoType, internal.matlab.importtool.ImportableFileExtension.getSpreadsheetFileExtensions(false)))
                    % Spreadsheet extension files are not text
                    textfile = false;
                elseif (any(strcmp(finfoType, videoFileExt))) || (any(strcmp(finfoType, audioFileExt)))
                    % Any additional platform video/audio types are also not
                    % text
                    textfile = false;
                else
                    % try to treat as hidden mat file
                    try
                        load('-mat', fileAbsolutePath); %#ok<LOAD>
                    catch exception  %#ok<NASGU>
                        textfile = true; % Not a known extension so try as text file
                    end
                end
            end
        end
    end
end
