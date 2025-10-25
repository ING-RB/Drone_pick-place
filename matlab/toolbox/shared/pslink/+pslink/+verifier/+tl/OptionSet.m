classdef OptionSet < pslink.verifier.OptionSet
    %OPTIONSSET

% Copyright 2020-2024 The MathWorks, Inc.

    methods(Access=public)

        %% Public Method: OptionsSet --------------------------------------
        %  Abstract:
        %    Constructor.
        function self = OptionSet(varargin)
            self = self@ pslink.verifier.OptionSet(varargin{:});
            self.tplFlags = cell(0, 2);
            self.tplElemFlags = cell(0, 2);
        end

        %% Public Method: delete ------------------------------------------
        %  Abstract:
        %    Destructor.
        function delete(~)
        end

        %% Public Method: fixSrcFiles -------------------------------------
        %  Abstract:
        %
        function [ovwOpts, archiveFiles] = fixSrcFiles(self, ovwOpts, pslinkOptions)
            archiveFiles = {};
            sysDirInfo = pslink.util.Helper.getConfigDirInfo(self.coderObj.slSystemName, pslink.verifier.tl.Coder.CODER_ID);
            for ii = 1:numel(self.fileInfo.source)
                self.fileInfo.source{ii} = strrep(self.fileInfo.source{ii}, sysDirInfo.CodeGenFolder, '..');
                % Handle LUT stub file generated if exists
                if numel(self.coderObj.stubFile) > 0
                    idx = strcmpi(self.fileInfo.source{ii},self.coderObj.stubFile);
                    if any(idx)
                        [~, fName, fExt] = fileparts(self.fileInfo.source{ii});
                        self.fileInfo.source{ii} = ['.' filesep fName fExt];
                    end
                end
            end

            % For additional file list, fix source list file with relative path
            if pslinkOptions.EnableAdditionalFileList && numel(pslinkOptions.AdditionalFileList) > 0
                for ii=1:numel(pslinkOptions.AdditionalFileList)
                    currFile = pslinkOptions.AdditionalFileList{ii};
                    if exist(currFile, 'file') == 2
                        idx = strcmpi(self.fileInfo.source,currFile);
                        if any(idx)
                            [~, fName, fExt] = fileparts(currFile);
                            self.fileInfo.source{idx} = ['.' filesep fName fExt];
                        end
                    else
                        error('pslink:badAdditionalSourceListFile', ...
                            message('polyspace:gui:pslink:badAdditionalSourceListFile', ...
                            strrep(currFile, '\', '\\')).getString())
                    end
                end
            end
        end

        %% Public Method: fixIncludes -------------------------------------
        %  Abstract:
        %
        function ovwOpts = fixIncludes(self, ovwOpts, ~)
            sysDirInfo = pslink.util.Helper.getConfigDirInfo(self.coderObj.slSystemName, pslink.verifier.tl.Coder.CODER_ID);
            fieldName = 'include';
            if isfield(ovwOpts, fieldName)
                for ii = 1:numel(ovwOpts.(fieldName))
                    if startsWith(ovwOpts.(fieldName){ii},sysDirInfo.CodeGenFolder)
                        ovwOpts.(fieldName){ii} = strrep(ovwOpts.(fieldName){ii}, sysDirInfo.CodeGenFolder, '..');
                    end
                end
                % Handle LUT stub folder generated if exists as current
                % folder
                if numel(self.coderObj.stubFile) > 0
                    ovwOpts.(fieldName){end+1} = '.';
                end
            end
            % Remove all remaining absolute path
            for ii = 1:numel(ovwOpts.(fieldName))
                if ~startsWith(ovwOpts.(fieldName){ii}, {'..', '.'})
                    ovwOpts.(fieldName){ii} = [];
                end
            end            
        end

        %% Public Method: getTypeInfo -------------------------------------
        %  Abstract:
        %
        function getTypeInfo(self, systemName, sysDirInfo) 
            self.typeInfo = pssharedprivate('getTypeInfo', systemName, ...
                pslink.verifier.tl.Coder.CODER_ID, sysDirInfo.SystemCodeGenDir, sysDirInfo.ModelRefCodeGenDir);
        end

        %% Public Method: getTplFlags -------------------------------------
        %  Abstract:
        %
        function getTplFlags(self, modelLang)
            if strcmpi(modelLang,'C')
                lang = 'C';
            else
                lang = 'CPP';
            end
            self.tplFlags = {...
                '-lang', {lang};...
                '-boolean-types', {'Bool'};...
                '-signed-integer-overflows', {'warn-with-wrap-around'};...
                '-allow-negative-operand-in-shift', {};...
                '-mbd', {} ...
                };
        end

        %% Public Method: checkConfiguration ------------------------------
        %  Abstract:
        %     Method to be implemented by a derived class for applying
        %     specific checks to the current system.
        function hasError = checkConfiguration(self, systemName, pslinkOptions)

            % Check options
            if ~isempty(self.coderObj)
                opts.isMdlRef = self.coderObj.isMdlRef;
                opts.CheckConfigBeforeAnalysis = pslinkOptions.CheckConfigBeforeAnalysis;
            end
            [ResultDescription, ResultDetails, ResultType, hasError] = pslink.verifier.tl.Coder.checkOptions(systemName, opts);
            pssharedprivate('printCheckOptionsResults', ResultDescription, ResultDetails, ResultType);
        end

        %% Public Method: getArchiveName ----------------------------------
        %  Abstract: Get the generated archive name and handle related
        %  errors
        %
        function archiveName = getArchiveName(self)
            % TargetLink does not have base zip file, so use modelName as default value
            archiveName = bdroot(self.coderObj.slSystemName);
        end

        %% Public Method: appendToArchive ---------------------------------
        %  Abstract:
        %
        function packageName = appendToArchive(self, pslinkOptions, isMdlRef)
            % TargetLink does not have base zip file, so use modelName as default value
            packageName = self.archiveName;
            polyspaceFolder = 'polyspace';
            sysDirInfo = pslink.util.Helper.getConfigDirInfo(self.coderObj.slSystemName, pslink.verifier.tl.Coder.CODER_ID);

            startFolder = fileparts(self.optionsFileName);
            psFiles = {...
                self.optionsFileName,...
                self.drsFileName,...
                self.lnkFileName ...
                };
            if isMdlRef
                psFolderName = fullfile(startFolder, [polyspaceFolder '_' self.coderObj.slModelName]);
            else
                psFolderName = fullfile(startFolder, polyspaceFolder);
            end

            % Check for existing Polyspace files existence
            if ~isfolder(psFolderName)
                mkdir(psFolderName);
            end
            for ii=1:numel(psFiles)
                psTargetFile = fullfile(psFolderName, psFiles{ii});
                if isfile(psTargetFile)
                    delete(psTargetFile);
                end
                if isfile(psFiles{ii})
                    movefile(psFiles{ii}, psFolderName);
                else
                    warning('pslink:missingFile', ...
                        message('polyspace:gui:pslink:missingFile', strrep(psFiles{ii}, '\', '\\')).getString());
                end
            end

            % Prepare folder hierarchy for TL generated files to copy
            srcFolder = {};
            for ii=1:numel(self.fileInfo.source)
                currentSrcFolder = fileparts(self.fileInfo.source{ii});
                if startsWith(currentSrcFolder, '..')
                    currentSrcFolder = currentSrcFolder(2:end);
                end
                srcFolder{end+1} = currentSrcFolder; %#ok<AGROW>
            end
            
            for ii=1:numel(self.fileInfo.include)
                % Add includes to archive only if under codeGenfolder
                if contains(self.fileInfo.include{ii}, sysDirInfo.CodeGenFolder)
                    incFolder = strrep(self.fileInfo.include{ii}, sysDirInfo.CodeGenFolder, '.');
                    if ~isempty(incFolder) && ~strcmpi(incFolder, '.')
                        srcFolder{end+1} = incFolder; %#ok<AGROW>
                    end
                end
            end
            srcFolder = unique(srcFolder);

            % Polypate zip list with Polyspace generated files
            archiveFiles = {};
            archiveFiles{end+1} = psFolderName;

            for ii=1:numel(srcFolder)
                archiveFiles{end+1} = srcFolder{ii}; %#ok<AGROW>
            end

            % Add the additional sources files within package to be rebuilt
            if pslinkOptions.EnableAdditionalFileList && numel(pslinkOptions.AdditionalFileList) > 0
                for ii=1:numel(pslinkOptions.AdditionalFileList)
                    if exist(pslinkOptions.AdditionalFileList{ii}, 'file') == 2
                        % Add the file within archive
                        currFile = pslinkOptions.AdditionalFileList{ii};
                        copyfile(currFile, startFolder, 'f');
                        [~, fName, fExt] = fileparts(currFile);
                        archiveFiles{end+1} = fullfile(startFolder, [fName fExt]); %#ok<AGROW>
                    end
                end
            end
            
            % Add the generated stub files for LUT
            for ii=1:numel(self.coderObj.stubFile)
                if exist(self.coderObj.stubFile{ii}, 'file') == 2
                    % Add the file within archive
                    currFile = self.coderObj.stubFile{ii};
                    copyfile(currFile, startFolder, 'f');
                    [~, fName, fExt] = fileparts(currFile);
                    archiveFiles{end+1} = fullfile(psFolderName, [fName fExt]); %#ok<AGROW>
                end
            end
            
            zip(packageName, archiveFiles, sysDirInfo.CodeGenFolder);
        end

        %% Public Method: writeLinksDataFile ------------------------------
        %  Abstract:
        %
        function writeLinksDataFile(self)
            if ~isempty(self.dataLinkInfo)
                pslink.util.LinksData.writeNewDataLinkFile(self.dataLinkInfo, self.lnkFileName, pslink.verifier.tl.Coder.CODER_NAME);
            end
        end
    end

    methods(Static=true)

        %% Static Method: fixOptsFromSettings -----------------------------
        %  Abstract:
        %
        function ovwOpts = fixOptsFromSettings(ovwOpts, pslinkOptions) %#ok<INUSD>
        end
    end    
end

% LocalWords:  optionset POLYSPACE pslink
