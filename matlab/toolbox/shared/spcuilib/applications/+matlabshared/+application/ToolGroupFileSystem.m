classdef ToolGroupFileSystem < handle
    %
    
    %   Copyright 2020-2024 The MathWorks, Inc.
    
    properties (SetAccess = protected, Hidden)
        CurrentFileName = '';
        SaveAction
        IsDirty = false;
        IsLoading = false;
        CloseWhenFinishedLoading = false;
        AlertState = [];
    end
    
    properties (Access = protected)
        FileSection;
        ApplicationConstructedListener;
        ApplicationBeingDestroyedListener;
        ToolGroupConstructedListener;
        ToolGroupBeingDestroyedListener;
    end
    
    methods
        
        function this = ToolGroupFileSystem
            addQabButton(this, 'save', @this.saveCallback, 'Enabled', false);
            
            addApplicationKeyPress(this, 's', @this.saveCallback, {'control'});
            addApplicationKeyPress(this, 'o', @this.openCallback, {'control'});
            addApplicationKeyPress(this, 'n', @this.newCallback,  {'control'});
            
            this.ApplicationConstructedListener = event.listener(this, ...
                'ApplicationConstructed', @this.onApplicationConstructed);
            this.ApplicationBeingDestroyedListener = event.listener(this, ...
                'ApplicationBeingDestroyed', @this.onApplicationBeingDestroyed);
            this.ToolGroupConstructedListener = event.listener(this, ...
                'ToolGroupConstructed', @this.onApplicationConstructed);
            this.ToolGroupBeingDestroyedListener = event.listener(this, ...
                'ToolGroupBeingDestroyed', @this.onApplicationBeingDestroyed);
        end
        
        function b = showRecentFiles(~)
            b = false;
        end
        
        function new(this, ~)
            this.CurrentFileName = '';
            removeDirty(this);
            updateTitle(this);
        end
        
        function success = saveFile(this, fileName, tag)
            defaultTag = getDefaultSaveTag(this);
            if nargin < 3
                tag = defaultTag;
            end
            
            % If no name is passed, the CurrentFileName can be used if the
            % default type is being saved.
            if (nargin < 2 || isempty(fileName)) && strcmp(tag, defaultTag)
                fileName = this.CurrentFileName;
            end
            if isempty(fileName)
                success = saveFileAs(this, tag);
            else
                success = true;
                data = getSaveData(this, tag);
                save(fileName, 'data', 'tag');
                
                % Only set the current file name for the default file type.
                % This is normally "session"
                if strcmp(tag, defaultTag)
                    setCurrentFileName(this, fileName);
                end
                addRecentFile(this, fileName, tag);
                removeDirty(this);
                updateTitle(this);
            end
        end
        
        function success = saveFileAs(this, tag)
            if nargin < 2
                tag = getDefaultSaveTag(this);
            end
            [fileName, pathName] = uiputfile(getSaveFileSpecification(this, tag), getSaveDialogTitle(this, tag), this.CurrentFileName);
            if isequal(fileName, 0)
                success = false;
            else
                fileName = fullfile(pathName, fileName);
                success = true;
                saveFile(this, fileName, tag);
            end
        end
        
        function success = openFile(this, fileName, tag, addToRecent)
            success = false;
            if ~allowOpen(this)
                return;
            end
            if nargin < 2 || isempty(fileName)
                if nargin < 3
                    tag = getDefaultOpenTag(this);
                end
                path = getOpenFilePath(this, tag);
                if ~exist(path, 'dir')
                    path = '';
                end
                [fileName, pathName] = uigetfile(getOpenFileSpecification(this ,tag), getOpenDialogTitle(this, tag), path);
                if isequal(fileName, 0)
                    return;
                end
                fileName = fullfile(pathName, fileName);
            else
                [~,~,e] = fileparts(fileName);
                if isempty(e)
                    fileName = [fileName '.mat'];
                end
                fullFileName = which(fileName);
                if ~isempty(fullFileName)
                    fileName = fullFileName;
                end
            end

            % Ice the UI until the open is complete.
            cWait = freezeUserInterface(this);
            
            this.IsLoading = true;
            c = onCleanup(@() clearIsLoading(this));
            if exist('tag','var')
                tag = openFileImpl(this, fileName, tag, nargin);
            else
                tag = openFileImpl(this, fileName, "", nargin);
            end

            if nargin < 4 || addToRecent
                addRecentFile(this, fileName, tag);
            end
            if strcmp(tag, getDefaultOpenTag(this))
                setCurrentFileName(this, fileName);
                removeDirty(this);
            else
                % If a non default type is being opened, dirty the state.
                setDirty(this);
            end
            success = true;
            if ~isempty(cWait)
                delete(cWait);
            end
            updateTitle(this);
            if this.CloseWhenFinishedLoading
                close(this);
            end
        end
        
        function success = importItem(this, tag)
            % Open the file but do not add to recent
            success = openFile(this, '', tag, false);
        end
        
        function title = getTitle(this)
            fileName = getCurrentFileName(this);
            if isempty(fileName)
                fileName = 'untitled';
            end
            [~, fileName] = fileparts(char(fileName));
            title = [getName(this) ' - ' fileName];
            
            if this.IsDirty
                title = sprintf('%s*', title);
            end
        end
    end
    
    methods (Hidden)

        function b = useSvgIconsForFileSection(~)
            b = false;
        end
        function b = useCompactFileSection(~)
            b = false;
        end
        
        function attachAllPopups(this)
            attachAllPopups(this.FileSection);
        end

        function clearIsLoading(this)
            this.IsLoading = false;
        end
        
        function fileSection = getFileSection(this)
%             fileSection = this.FileSection;
%             if isempty(fileSection)
                fileSection = matlabshared.application.FileSection(this, 'UseSvgIcons', useSvgIconsForFileSection(this), ...
                  'CompactMode', useCompactFileSection(this));
                this.FileSection = fileSection;
%             end
        end
        
        function removeDirty(this)
            oldDirty = this.IsDirty;
            this.IsDirty = false;
            setQabEnabled(this, 'save', false);
            fileSection = this.FileSection;
            if oldDirty
                if ~isempty(fileSection)
                    updateSaveIcons(fileSection);
                end
                updateTitle(this);
            end
        end
        
        function setDirty(this)
            oldDirty = this.IsDirty;
            this.IsDirty = true;
            setQabEnabled(this, 'save', true);
            fileSection = this.FileSection;
            if ~oldDirty
                if ~isempty(fileSection)
                    updateSaveIcons(fileSection);
                end
                updateTitle(this);
            end
        end
        
        function f = getCurrentFileName(this)
            f = this.CurrentFileName;
        end
        
        function setCurrentFileName(this, f)
            this.CurrentFileName = f;
        end
        
        function tag = getDefaultNewTag(this)
            spec = getNewSpecification(this);
            if iscell(spec)
                spec = spec{1}{2};
            end
            tag = spec(1).tag;
        end
        
        function spec = getNewSpecification(~)
            spec = struct('text', getString(message('Spcuilib:application:NewText')), ...
                'tag', 'default');
        end
        
        function tag = getDefaultSaveTag(this)
            spec = getSaveSpecification(this);
            if iscell(spec)
                spec = spec{1}{2};
            end
            tag = spec(1).tag;
        end
        
        function spec = getSaveSpecification(~)
            spec = struct('text', getString(message('Spcuilib:application:SaveText')), ...
                'tag', 'default');
        end
        
        function tag = getDefaultOpenTag(this)
            spec = getOpenSpecification(this);
            if iscell(spec)
                spec = spec{1}{2};
            end
            tag = spec(1).tag;
        end
        
        function spec = getOpenSpecification(~)
            spec = struct('text', getString(message('Spcuilib:application:OpenText')), ...
                'tag', 'default');
        end
        
        function info = getImportDescription(this)
            if useSvgIconsForFileSection(this)
                icon = matlab.ui.internal.toolstrip.Icon('import_data');
            else
                icon = matlab.ui.internal.toolstrip.Icon.IMPORT_24;
            end
            info = struct('text', getString(message('Spcuilib:application:ImportText')), ...
                'tag', 'import', ...
                'icon', icon, ...
                'description', '');
        end
        
        function spec = getImportSpecification(~)
            spec = [];
        end
        
        % Specification methods do not need to be overloaded but most
        % subclasses will want to overload them.
        function spec = getSaveFileSpecification(~)
            spec = {'*.*', getString(message('Spcuilib:application:AllFilesTypeDescription'))};
        end
        
        function spec = getOpenFileSpecification(this, tag)
            spec = getSaveFileSpecification(this, tag);
        end
        
        function title = getSaveDialogTitle(~, ~)
            title = getString(message('Spcuilib:application:SaveDialogTitle'));
        end
        
        function title = getOpenDialogTitle(~, ~)
            title = getString(message('Spcuilib:application:OpenDialogTitle'));
        end
        
        function files = getRecentFiles(this, varargin)
            tag   = getTag(this);
            id    = getRecentFilesId(this);
            files = getpref(tag, id, cell(0, 2));
            indx  = 1;
            
            if size(files, 2) == 1
                defTag = getDefaultOpenTag(this);
                files = [files(:) repmat({defTag}, numel(files), 1)];
                saveFiles = true;
            else
                saveFiles = false;
            end
            
            files = vertcat(files, varargin{:});
            
            % Remove any files saved as recent that are no longer present.
            while indx <= size(files, 1)
                % remove any duplicates, keep the first one as this was the
                % most recently recent file.
                repeatIndex = find(strcmp(files{indx, 1}, files(:, 1)));
                files(repeatIndex(2:end), :) = [];
                if exist(files{indx, 1}, 'file')
                    indx = indx + 1;
                else
                    saveFiles = true;
                    files(indx, :) = [];
                end
            end
            if saveFiles
                setpref(tag, id, files);
            end
        end
        
        function [icon, label] = getInfoForRecentFile(~, fileName, ~)
            icon = [];
            label = fileName;
        end
        
        function fileName = getRecentFileNameFromText(~, fileName)
            % NO OP
        end
        
        function b = allowImport(this)
            b = alertDirtyState(this, 'import', true);
        end
        
        function b = allowOpen(this)
            b = alertDirtyState(this, 'open', true);
        end
        
        function b = allowNew(this)
            b = alertDirtyState(this, 'new', true);
        end
        
        function b = allowClose(this, varargin)
            if this.IsLoading
                this.CloseWhenFinishedLoading = true;
                b = false;
                return;
            end
            
            try
                b = alertDirtyState(this, 'close', varargin{:});
            catch ME
                errorMessage(this, ME, getString(message('Spcuilib:application:SaveErrorTitle')));
                b = false;
            end
        end
        
        function b = alertDirtyState(this, type, canCancel)
            if ~this.IsDirty
                b = true;
                return;
            end
            if nargin < 3
                canCancel = true;
            end
            yes    = getString(message('Spcuilib:application:Yes'));
            no     = getString(message('Spcuilib:application:No'));
            cancel = getString(message('Spcuilib:application:Cancel'));
            if canCancel
                default = cancel;
                buttons = {yes no cancel};
            else
                default = yes;
                buttons = {yes no};
            end
            title = getName(this);
            text  = getDirtyWarningString(this, type);
            alertState = uiconfirm(this, text, title, buttons, default);
            switch alertState
                case yes
                    if saveFile(this)
                        b = true;
                    else
                        b = ~canCancel;
                    end
                case no
                    b = true;
                case {cancel, []} % escape returns []
                    b = false;
            end
        end
 
        function openSplitOpening(~)
            % NO OP
        end
        
        function openSplitOpened(~)
            % NO OP
        end
    end
    
    methods (Access = protected)
        function tag = openFileImpl(this, fileName, tag, inputArgs)
            data = loadDataFile(this, fileName, tag);
            if ~isfield(data, 'data')
                error(message(getInvalidFileFormatId(this)));
            end
            if inputArgs < 3
                
                % If no tag is passed, try to get it from the file, and
                % then use the default if it is not found in the file.
                if isfield(data, 'tag')
                    tag = data.tag;
                else
                    tag = getDefaultOpenTag(this);
                end
            end
            tag = updateTag(this, tag);
            this.processOpenData(data.data, tag);
        end
        
        function data = loadDataFile(~, fileName, ~)
            
            data = load(fileName, '-mat');
        end

        function b = onCloseRequest(this, varargin)
            b = false;
            if this.IsLaunching
                return;
            end
            b = allowClose(this, true);
            
            if b
                this.ToolGroupBeingDestroyedListener = [];
                this.ApplicationBeingDestroyedListener = [];
                this.IsWindowDeleting = true;
                close(this);
            end
        end
        
        function onApplicationConstructed(this, ~, ~)
            attachCloseRequest(this, @this.onCloseRequest);
        end
        
        function onApplicationBeingDestroyed(this, ~, ~)
            allowClose(this, false);
        end
        
        function saveCallback(this, ~, ~)
            try
                saveFile(this);
            catch ME
                errorMessage(this, ME, getString(message('Spcuilib:application:SaveErrorTitle')));
            end
        end
        
        function newCallback(this, ~, ~)
            new(this);
        end
        
        function openCallback(this, ~, ~)
            try
                openFile(this);
            catch ME
                errorMessage(this, ME, getString(message('Spcuilib:application:OpenErrorTitle')));
            end
        end
        
        function id = getInvalidFileFormatId(~)
            id = 'Spcuilib:application:InvalidFileFormat';
        end
        
        function data = getSaveData(~)
            data = [];
            
            % This method should be overloaded.
        end
        
        function processOpenData(~, ~)
            % NO OP
            % This method should be overloaded
        end
        
        function path = getOpenFilePath(this, ~)
            path = fileparts(this.CurrentFileName);
        end
        
        function newTag = updateTag(~, tag)
            % This method is overloaded in a derived class 
            % 'Designer.m' where the tag is actually updated.
            % This method will be considered for reimplementation 
            % in a future release. 
            newTag = tag;
        end
        
        function id = getRecentFilesId(~)
            id = 'RecentFiles';
        end
        
        function addRecentFile(this, fileName, fileTag)
            fileName = string(fileName);
            filePath = fileparts(fileName);
            if isempty(filePath)
                fileName = fullfile(pwd, fileName);
            end
            tag = getTag(this);
            id  = getRecentFilesId(this);
            fileInfo = getpref(tag, id, cell(0, 2));
            
            % If we find the new file name in the existing list, remove it.
            foundIndex = strcmp(string(fileInfo(:, 1)), fileName);
            fileInfo(foundIndex, :) = [];
            
            % Old formats had no tags saved.  Make sure to fix that.
            if size(fileInfo, 2) == 1
                fileInfo = [fileInfo repmat({getDefaultSaveTag(this)}, size(fileInfo, 1), 1)];
            end
            
            % Add the new name to the top of the list.
            fileInfo = [{fileName, fileTag}; fileInfo];
            
            % Allow only 10 items
            fileInfo(11:end, :) = [];
            
            % Save the settings.
            setpref(tag, id, fileInfo);
        end
        
        function str = getDirtyWarningString(~, type)
            switch type
                case 'new'
                    str = getString(message('Spcuilib:application:NewDirtyStateWarning'));
                case 'open'
                    str = getString(message('Spcuilib:application:OpenDirtyStateWarning'));
                case 'close'
                    str = getString(message('Spcuilib:application:CloseDirtyStateWarning'));
                case 'import'
                    str = getString(message('Spcuilib:application:ImportDirtyStateWarning'));
            end
        end
    end
end
