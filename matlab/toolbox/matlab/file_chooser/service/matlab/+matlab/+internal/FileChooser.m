classdef FileChooser < handle
    % FileChooser creates file IO dialog in MATLAB Desktop Environment

    % Copyright 2020-2025 The MathWorks, Inc.

    events
        SelectionComplete
    end

    properties
        dialogTitle
        filePath
        fileName
        fileTypeFilters
        multiSelection
        selectionResults
        startSubscription
        resultSubscription
        serviceReady
        channelID
        MessageChannel = '/filechooser/MatlabToJS/';
        ResponseChannel = '/filechooser/JSToMatlab/';
        openDirSubChannel = '/openDirDialog/';
        openFileSubChannel = '/openFileDialog/';
        saveFileSubChannel = '/saveFileDialog/';
        openDirHandle = @matlab.internal.openDirectoryImpl
        openFileHandle = @matlab.internal.openFileImpl
        saveFileHandle = @matlab.internal.saveFileImpl
        filterProvider
    end

    methods
        function this = FileChooser(varargin)
            this.selectionResults = struct();
            this.multiSelection = false;
            this.filePath = pwd;
            this.filterProvider = matlab.internal.FileTypeFilters;
            this.serviceReady = false;
            if (nargin == 1)
                this.serviceReady = varargin{1};
            else
                this.startService();
            end
        end

        function delete(this)
            import matlab.internal.capability.Capability;

            if ~Capability.isSupported(Capability.LocalClient) || desktop('-inuse')
                message.unsubscribe(this.startSubscription);
                message.unsubscribe(this.resultSubscription);
            end
            this.serviceReady = false;
            this.startSubscription = '';
            this.resultSubscription = '';
        end

        function startService(this)
            import matlab.internal.capability.Capability;

            if ~Capability.isSupported(Capability.LocalClient) || desktop('-inuse')
                connector.ensureServiceOn;
                this.startSubscription = message.subscribe([this.ResponseChannel '/start'], @(msg)this.verifyServiceStarted(msg));
                message.publish([this.MessageChannel '/start'],'startService');
                waitfor(this, 'serviceReady', true);
            end
        end

        function deleteSubscription(this)
            message.unsubscribe(this.resultSubscription);
            this.resultSubscription = '';
        end

        function verifyServiceStarted(this, response)
            if ~strcmp(response.msg,'serviceStarted')
                ME = MException('file_chooser:unableToStartService','JS FileChooserService not Started');
                throw(ME)
            else
                this.serviceReady = true;
                this.channelID = response.id;
            end
        end

        % set methods
        function setDialogTitle(this,title)
            narginchk(2,2);
            if checkIfValidStringArgument(title)
                this.dialogTitle = title;
            % If title is empty char vector or string, default title will
            % be used in show method. Do not throw exception.
            elseif ~(isempty(title) || isStringScalar(title) && strlength(title)==0)
                ME = MException('file_chooser:invalidInputParameterExpectedCharOrString',message('file_chooser:fc_svc_resources:invalidInputParameterExpectedCharOrString', 'Dialog Title'));
                throw(ME)
            end
        end

        function setDirectory(this,path)
            narginchk(2,2);
            if checkIfValidStringArgument(path) && isfolder(path)
                this.filePath = convertStringsToChars(path);
            else
                ME = MException('file_chooser:invalidInputParameterExpectedValidPathWhichIsCharOrString',message('file_chooser:fc_svc_resources:invalidInputParameterExpectedValidPathWhichIsCharOrString', 'Initial file path'));
                throw(ME)
            end
        end

        function setFileName(this,name)
            narginchk(2,2);
            if checkIfValidFileNameArgument(name)
                this.fileName = convertStringsToChars(name);
            else
                ME = MException('file_chooser:invalidInputParameterExpectedCharOrString',message('file_chooser:fc_svc_resources:invalidInputParameterExpectedCharOrString', 'File Name'));
                throw(ME)
            end
        end

        function setFileTypeFilters(this,fileTypes)
            narginchk(2,2);

            if iscellstr(fileTypes) || ischar(fileTypes) || isstring(fileTypes)
                this.fileTypeFilters = cellstr(fileTypes);
            else
                ME = MException('file_chooser:invalidInputParameterExpectedCellArray',message('file_chooser:fc_svc_resources:invalidInputParameterExpectedCellArray'));
                throw(ME)
            end
        end

        function setMultiSelection(this,multiSelectValue)
            if islogical(multiSelectValue)
                this.multiSelection = multiSelectValue;
            else
                ME = MException('file_chooser:invalidInputParameterExpectedLogical',message('file_chooser:fc_svc_resources:invalidInputParameterExpectedLogical'));
                throw(ME)
            end
        end

        % get methods
        function title = getDialogTitle(this)
            title = this.dialogTitle;
        end

        function path = getFilePath(this)
            path = '';
            if isfield(this.selectionResults, "path")
                path = this.selectionResults.path;
            end
        end

        function filename = getFileName(this)
            filename = '';
            if isfield(this.selectionResults, "fileName")
                filename = this.selectionResults.fileName;
            end
        end

        function filterList = getFileTypeFilters(this, type)
            filterList = '';
            if nargin == 1
                if ~isempty(this.fileTypeFilters)
                    filterList = this.fileTypeFilters;
                end
            else
                if strcmpi(type, 'open')
                    filterList = this.getOpenFileExtensionFilters();
                elseif strcmpi(type,'save')
                    filterList = this.getSaveFileExtensionFilters();
                else
                    ME = MException('file_chooser:invalidFilterType',message('file_chooser:fc_svc_resources:invalidFilterType'));
                    throw(ME)
                end
            end
        end

        function fileTypeFilters = getSelectedFileTypeFilter(this)
            fileTypeFilters = '';
            if isfield(this.selectionResults, "fileTypeFilters")
                fileTypeFilters = this.selectionResults.fileTypeFilters;
            end
        end

        function fileTypeFilterIndex = getFileTypeFilterIndex(this)
            fileTypeFilterIndex = 0;
            if isfield(this.selectionResults, "fileTypeFilters")
                fileTypeFilterIndex = this.selectionResults.fileTypeFilterIndex;
            end
        end

        function error = getError(this)
            error = '';
            if isfield(this.selectionResults, "error")
                error = this.selectionResults.error;
            end
        end

        function multiSelectValue = getMultiSelection(this)
            multiSelectValue = this.multiSelection;
        end

        function filterDescriptor = getFilterDescription(this, pattern)
            filterDescriptor = this.filterProvider.getFilterDescription(pattern);
        end

        % show dialog methods
        function showOpenDirDialog(this)
            if isempty(this.dialogTitle)
                this.setDialogTitle(getMessageString('file_chooser:fc_svc_resources:openDirDialogTitle'));
            end

            if (~this.iscefDialogRequested)
                % call the built-in function to open Open-Directory dialog
                this.createNativeDialog(this.openDirHandle, convertStringsToChars(this.dialogTitle), convertStringsToChars(this.filePath));
            else
                if ~isempty(this.resultSubscription)
                    this.deleteSubscription();
                end
                dialogOptions = struct('dialogTitle', this.dialogTitle, 'filePath', this.filePath);
                this.createDialog(this.openDirSubChannel, dialogOptions);
            end
        end


        function showOpenFileDialog(this)
            this.selectionResults = struct();
            if isempty(this.dialogTitle)
                this.setDialogTitle(getMessageString('file_chooser:fc_svc_resources:openFileDialogTitle'));
            end


            if (~this.iscefDialogRequested)
                if isempty(this.fileTypeFilters)
                    this.setFileTypeFilters(this.getOpenFileExtensionFilters());
                else
                    this.fileTypeFilters = processFilters(this.fileTypeFilters);
                end
                this.setMultiSelection(this.multiSelection);
                % call the built-in function to open Open-File dialog
                this.createNativeDialog(this.openFileHandle, convertStringsToChars(this.dialogTitle), convertStringsToChars(strcat(this.filePath,getFilePathSeparator(),this.fileName)), cellstr(this.fileTypeFilters), this.multiSelection);
            else
                if ~isempty(this.resultSubscription)
                    this.deleteSubscription();
                end

                dialogOptions = struct('dialogTitle', this.dialogTitle, 'filePath', this.filePath, 'multiSelection', this.multiSelection);
                if ~isempty(this.fileName)
                    dialogOptions.fileName = this.fileName;
                end
                if ~isempty(this.fileTypeFilters)
                    dialogOptions.fileTypeFilters =  formatFilters(this.fileTypeFilters);
                end
                this.createDialog(this.openFileSubChannel, dialogOptions);
            end
        end

        function showSaveFileDialog(this)
            if isempty(this.dialogTitle)
                this.setDialogTitle(getMessageString('file_chooser:fc_svc_resources:saveFileDialogTitle'));
            end

            if (~this.iscefDialogRequested)
                if isempty(this.fileTypeFilters)
                    this.setFileTypeFilters(this.getSaveFileExtensionFilters());
                else
                    this.fileTypeFilters = processFilters(this.fileTypeFilters);
                end
                % call the built-in function to open Save file dialog
                this.createNativeDialog(this.saveFileHandle, convertStringsToChars(this.dialogTitle), convertStringsToChars(strcat(this.filePath,getFilePathSeparator(),this.fileName)), cellstr(this.fileTypeFilters));
            else
                if ~isempty(this.resultSubscription)
                    this.deleteSubscription();
                end

                dialogOptions = struct('dialogTitle', this.dialogTitle, 'filePath', this.filePath);
                if ~isempty(this.fileName)
                    dialogOptions.fileName = this.fileName;
                end
                if ~isempty(this.fileTypeFilters)
                    dialogOptions.fileTypeFilters =  formatFilters(this.fileTypeFilters);
                end
                this.createDialog(this.saveFileSubChannel, dialogOptions);
            end
        end

        % Process Results
        function handleResultMessage(this, result)
            this.deleteSubscription();
            this.selectionResults = result;
            if isfield(this.selectionResults, 'path')
                if iscell(result.path)
                    result.path = result.path';
                end
                this.selectionResults.path = cellstr(result.path);
            end
            this.processResult();
            this.notify('SelectionComplete');
        end

        function processResult(this)
            if isfield(this.selectionResults,'fileTypeFilters')
                [this.selectionResults.fileName, this.selectionResults.path] = cellfun(@getFileNameAndParentPath, this.selectionResults.path, 'UniformOutput', false);
                if ~isfield(this.selectionResults,'fileTypeFilterIndex')
                    this.selectionResults.fileTypeFilterIndex = this.computeFilterIndex();
                end
            end
        end

        function index = computeFilterIndex(this)
            index = find(strcmp(this.fileTypeFilters(:,2), this.selectionResults.fileTypeFilters));
        end
    end

    methods(Access=private)
        function res = iscefDialogRequested(this)
            import matlab.internal.capability.Capability;
            winSignature = matlab.internal.getWindowSignature;
            % if the call is being made from a qt window or the desktop is
            % not in use(deployed mode or nodesktop mode) and is from a
            % local client then we expect the PF dialog to be opened
            if (winSignature == "qt" || ~desktop('-inuse')) && Capability.isSupported(Capability.LocalClient) 
                res = false;
            else
                res = true;
            end
        end

         % Open Native Dialog
         function createNativeDialog (this, handle, title, filePath, varargin)
            if ispc && ~isempty(varargin)
                % Workaround for Windows Qt bu g2806190, remove filter extension that is provided in parentheses and keep text only. If there is no label text provided then keep the extension and remove only the parentheses.
                if startsWith(varargin{1}{1,2} , {'('})
                    varargin{1}{1,2} = replace(varargin{1}{1,2}, {'(',')','*','.'}, '');
                else
                    varargin{1}{1,2} = strtrim(replaceBetween(varargin{1}{1,2}, '(', ')', '' , 'Boundaries','inclusive'));
                end
                this.fileTypeFilters{1,2} = varargin{1}{1,2};
            end
            % Call is made to function handle with the inputs in the correct order. When there are 6 arguments, call was for Open file dialog, 5 for Save file.
            if nargin == 6
                result = handle(varargin{1}, title, filePath, varargin{2});
            elseif nargin == 5
                result = handle(varargin{1}, title, filePath);
            else
                result = handle(title,filePath);
            end

            this.selectionResults = result;
            this.processResult();
            this.notify('SelectionComplete');
        end

        function createDialog (this, subChannel, dialogOptions)
            this.resultSubscription = message.subscribe([this.ResponseChannel subChannel this.channelID], @(msg)this.handleResultMessage(msg));
            message.publish([this.MessageChannel subChannel this.channelID], jsonencode(dialogOptions));
        end

        % Get default filter lists
        function openFileTypeFilters = getOpenFileExtensionFilters(this)
            openFileTypeFilters = this.filterProvider.getOpenFileExtensionFilters();
        end

        function saveFileTypeFilters = getSaveFileExtensionFilters(this)
            saveFileTypeFilters = this.filterProvider.getSaveFileExtensionFilters();
        end
    end
end

function [fileName, parentPath] = getFileNameAndParentPath(filePath)
pathSplit = split(filePath, getFilePathSeparator());
fileName = pathSplit{end};
parentPath = strjoin(pathSplit(1:end-1), getFilePathSeparator());
end

function separator = getFilePathSeparator()
separator = "/";
if ispc
    separator = "\";
end
end

function messageStr = getMessageString(id)
messageStr = message(id).getString();
end

function value  = checkIfValidStringArgument(str)
value = ischar(str)&& sum(size(str) == 1) || isStringScalar(str) && strlength(str) > 0;
end

function value  = checkIfValidFileNameArgument(str)
value = ischar(str)&& (sum(size(str) == 1) || sum(size(str) == 0)) || isStringScalar(str) && strlength(str) >= 0;
end

% format filters for JS File chooser
function filterStruct =  formatFilters(filter)
filter = string(filter);
patterns = filter(:,1);
labels = filter(:,2);
filterStruct = struct('label', labels,'patterns', patterns);
end

% Add '(*.extn)' as label if the user provided filter label is empty
function filterList = processFilters(filterList)
    for i= 1:height(filterList)
        if isempty(filterList{i,2})
            filterList{i,2} = strcat('(', strrep(filterList{i,1}, ';',', '),')');
        end
    end
end

