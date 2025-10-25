classdef (Abstract) FileDialogHelper < handle
    %Helper class for all filedialog services

%   Copyright 2018-2023 The MathWorks, Inc.
    
    methods (Static, Hidden)
        function hUIFigure = getUIFigure()            
            % find existing uifigure
            hUIFigure = findall(groot, 'Type', 'figure');
        end

        function fileFilter = getFileExtensionFiltersWeb(fileFilter, dialogType)
            persistent fileTypeFiltersObj
            if isempty(fileTypeFiltersObj)
                fileTypeFiltersObj = matlab.internal.FileTypeFilters();
            end

            if ~isempty(fileFilter)
                fileFilter = matlab.ui.internal.dialog.FileDialogHelper.validateFileFilter(fileFilter);
    
                % If no filter descriptions provided (Only 1 column provided in dialog_filter),
                % then append another column and include any filter descriptions that we have by default.
                % Refer to g2639276 for more info
                filterSize = size(fileFilter);
                if filterSize(2) == 1
                    for idx = 1:filterSize(1)
                        fileFilter{idx, 2} = fileTypeFiltersObj.getFilterDescription(fileFilter{idx, 1});
                    end
                end
            end

            if isempty(fileFilter) || (iscell(fileFilter) && any(cellfun(@isempty, fileFilter(:))))
                if (dialogType == 0)
                    fileFilter = fileTypeFiltersObj.getOpenFileExtensionFilters();
                else
                    fileFilter = fileTypeFiltersObj.getSaveFileExtensionFilters();
                end
            end

            % After setting up filters, make one last check to remove
            % filters that use invalid format

            % cellstr is used on the finalized filter list to convert arrays 
            % of strings into character arrays so that they can be properly 
            % compared with the filter list that's returned by the file dialog.
            fileFilter = matlab.ui.internal.dialog.FileDialogHelper.removeInvalidFilters(cellstr(fileFilter));
        end

        function newFilters = removeInvalidFilters(oldFilters)
            % Valid filter formats are filters that starts with "*." and
            % includes a string afterwards. Any filters that do not fit
            % this criteria are removed and a warning is displayed.

            % First remove any leading white spaces in the file filters
            oldFilters(:,1) = strtrim(oldFilters(:,1));
            % Afterwards, remove any file filters that are '*' since that is
            % the same as 'All Files'
            oldFilters = oldFilters(~strcmp(oldFilters(:,1),'*'),:);
            if ~isempty(oldFilters)
                patterns = oldFilters(:,1);
                validPatternIdx = cellfun(@(s) strlength(s) && startsWith(s,'*.') && ~strcmp(s,'*.'), patterns, UniformOutput=true);
                invalidPatterns = oldFilters(~validPatternIdx);
                if ~isempty(invalidPatterns)
                    warningstatus = warning('OFF', 'BACKTRACE');
                    warnStatusCleanup = onCleanup(@()warning(warningstatus));
                    warning(message('MATLAB:AbstractFileDialog:InvalidFileFilter', strjoin(string(invalidPatterns), ', ')));
                end
                newFilters = oldFilters(validPatternIdx,:);
                % In scenarios where the resulting array is empty, default
                % to the All Files filter
                if isempty(newFilters)
                    newFilters = {'*.*', 'All Files'};
                end
            else
                % If the revised oldFilters ends up empty, default to 'All
                % Files'
                newFilters = {'*.*', 'All Files'};
            end
        end
        
        function processedFilter = getFileExtensionFilters(fileFilter, dialogType)
            if (matlab.ui.internal.dialog.FileDialogHelper.isWebUI())
                filterCell = matlab.ui.internal.dialog.FileDialogHelper.getFileExtensionFiltersWeb(fileFilter, dialogType);
                processedFilter = struct();
                processedFilter.FilterValue = filterCell(:,1);
                processedFilter.FilterDescription = cellstr(filterCell(:,2));
                return;
            end

            % get the size of FileFilter;
            [~, columns] = size(fileFilter);
            
            % construct struct with filter value and description based on 
            % fileFilter input
            if isempty(fileFilter)
                javaFileExtensionFilters = getPeer(matlab.ui.internal.dialog.FileExtensionFilter);
                processedFilter = matlab.ui.internal.dialog.FileDialogHelper.getFilterValueAndDescription(javaFileExtensionFilters);
            elseif (columns == 1)
                % first remove existing all file filter before adding new
                javaFileExtensionFilters = getPeer(matlab.ui.internal.dialog.FileExtensionFilter(fileFilter));
                processedFilter = matlab.ui.internal.dialog.FileDialogHelper.getFilterValueAndDescription(javaFileExtensionFilters);
            else
                processedFilter.FilterValue = fileFilter(:,1);
                processedFilter.FilterDescription = fileFilter(:,2);
            end               
        end
        
        function fileFilter = getFilterValueAndDescription(javaFileExtensionFilters)                
            % Synchronize object state with the static set of filters
            % that we show as default.
            filterValue = cell(numel(javaFileExtensionFilters),1);
            filterDescription = cell(numel(javaFileExtensionFilters),1);
            for j = 1:size(filterValue,1)
                % PATTERNS
                pattern = javaFileExtensionFilters{j}.getPatterns;
                if length(pattern)>1
                    cellPatterns = arrayfun(@(x) [char(x) ';'], pattern,'UniformOutput',false);
                    filterValue{j} = [cellPatterns{:}];
                else
                    filterValue{j} = char(pattern);
                end

                % DESCRIPTIONS
                filterDescription{j} = char(javaFileExtensionFilters{j}.getDescription);
            end
            
            % construct struct with filter value and description
            fileFilter.FilterValue = filterValue;
            fileFilter.FilterDescription = filterDescription; 
        end
        
        function sessionDirectory = getDeployedEnvPath()            
            % return pathName for deployed web apps environment
            sessionDirectory = getappdata( matlab.ui.internal.dialog.FileDialogHelper.getUIFigure(), 'MW_SessionDirectory');
            
            % pwd if sessionDirectory is empty
            if(isempty(sessionDirectory))
                sessionDirectory = pwd;
            end
        end
        
        function fileIOTransactionNumber = getTransactionNumber()            
            hUIFigure =  matlab.ui.internal.dialog.FileDialogHelper.getUIFigure();            
            % return FileIOTransactionNumber
            fileIOTransactionNumber = getappdata( hUIFigure, 'MW_FileIOTransactionNumber');
            
            % set MW_FileIOTransactionNumber when empty
            if isempty(fileIOTransactionNumber)
               setappdata( hUIFigure, 'MW_FileIOTransactionNumber', 1);
               fileIOTransactionNumber = getappdata( hUIFigure, 'MW_FileIOTransactionNumber');
            end
        end
        
        function setTransactionNumber(transactionNo)            
            % set MW_FileIOTransactionNumber
            setappdata( matlab.ui.internal.dialog.FileDialogHelper.getUIFigure(), 'MW_FileIOTransactionNumber', transactionNo);
        end
        
        function contentURLPath = getStaticContentPath()
            % persistent variable for adding static content on path
            persistent contentPath;
            
            % add fullpath on connector path
            if(isempty (contentPath))                                     
                contentPath = connector.addStaticContentOnPath('fileIO', ...
                    fullfile(matlab.ui.internal.dialog.FileDialogHelper.getDeployedEnvPath()));
            end
            contentURLPath = contentPath;
        end
        
        function returnController = setupFileIODialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.FileIODialogController;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end

        function returnFileChooser = setupFileChooser(mockFileChooser)
            % Create a persistent variable that preserves the current
            % stack of mock file chooser handles
            persistent mockFileChooserStack;
            if isempty(mockFileChooserStack)
                mockFileChooserStack = {};
            end

            if nargin == 0
                % For no arguments, if the mock file chooser stack is
                % empty, use default FileChooser, otherwise pop the stack
                if ~isempty(mockFileChooserStack)
                    if isscalar(mockFileChooserStack)
                        % Check if the single-item stack is a cell
                        if iscell(mockFileChooserStack)
                            returnFileChooser = mockFileChooserStack{1};
                            mockFileChooserStack = {};
                        else
                            returnFileChooser = mockFileChooserStack;
                            mockFileChooserStack = {};
                        end
                    else
                        returnFileChooser = mockFileChooserStack{end};
                        mockFileChooserStack = mockFileChooserStack(1:end-1);
                    end
                else
                    returnFileChooser = @matlab.internal.FileChooser;
                end
            elseif nargin == 1
                assert(isa(mockFileChooser, 'function_handle'));
                % If the input argument is the default FileChooser
                % function handle, clear the stack. Otherwise, add it to
                % the to the mock file chooser stack for future use
                if strcmp(func2str(mockFileChooser),'matlab.internal.FileChooser')
                    if ~isempty(mockFileChooserStack)
                        warning(message("MATLAB:AbstractFileDialog:HandleStackNotEmpty"));
                    end
                    mockFileChooserStack = {};
                else
                    mockFileChooserStack{end+1} = mockFileChooser;
                end
                returnFileChooser = mockFileChooser;
            end
        end
        
        % File listener function using timer
        function fileListener(fullPathName, channelId)
            %create an unique timer object for each function call
            timerObject = timer();
            
            % set tag as fileIO
            timerObject.Tag = 'fileIO';
            % timer callback function executes only once
            timerObject.executionmode = 'singleShot';
            % skip timerFcn calls when busy
            timerObject.BusyMode = 'drop';
            
            % timer callback function
            timerObject.TimerFcn = @matlab.ui.internal.dialog.FileDialogHelper.timerCallback;
             
            % start timer by setting with userdata value
            ud.fullPathName = fullPathName;
            ud.channelId = channelId;
            % number of times to execute task before starting timer
            ud.tasksToExecute = 1200;
            % to add addStaticContentOnPath
            ud.contentUrlPath = matlab.ui.internal.dialog.FileDialogHelper.getStaticContentPath();
            timerObject.UserData = ud;
            
            % start the timer object
            start(timerObject);            
        end
        
        % Timer callback function
        function timerCallback(tHandle, ~)
            % call timer callback impl using drawnow callback
            matlab.graphics.internal.drawnow.callback(@()matlab.ui.internal.dialog.FileDialogHelper.timerCallbackImpl(tHandle));
        end
        
        % Actual timer callback function implementation
        function timerCallbackImpl(tHandle)            
            if (exist(tHandle.UserData.fullPathName, 'file') == 2)                
                % pause for 0.25 secs before triggering download
                pause(0.25);                
                % contruct url and publish message to view
                matlab.ui.internal.dialog.FileDialogHelper.constructUrlAndPublishMessage(tHandle.UserData.fullPathName, ...
                    tHandle.UserData.contentUrlPath, tHandle.UserData.channelId);                
                % delete timer 
                delete(tHandle);
            else
                if (tHandle.UserData.tasksToExecute > 0)
                    % decrement tasksToExecute
                    tHandle.UserData.tasksToExecute = tHandle.UserData.tasksToExecute - 1;
                    tHandle.StartDelay = 1;
                    % restart the timer
                    start(tHandle);
                end
            end
        end
        
        % Function to trigger file download
        function triggerFileDownload(fileWithPathName)
            if (matlab.internal.environment.context.isWebAppServer)
                fullFileName = fullfile(fileWithPathName);
                % construct channelId for publishing message
                figure = matlab.ui.internal.dialog.FileDialogHelper.getUIFigure();
                [~, figureID] = matlab.ui.internal.dialog.DialogHelper.validateUIfigure(figure);                
                channelId = ['/gbt/figure/DialogService/' figureID];

                % get static content path
                contentUrlPath = matlab.ui.internal.dialog.FileDialogHelper.getStaticContentPath();
                % contruct url and publish message to view
                matlab.ui.internal.dialog.FileDialogHelper.constructUrlAndPublishMessage(fullFileName, ...
                    contentUrlPath, channelId);
            end
        end
        
        % Function to construct url and publish message to view
        function constructUrlAndPublishMessage(fullFileName, contentUrlPath, channelId)
            % get transaction number for url
            [pathName,fileName,fileExt] = fileparts(fullFileName);
            [~,transactionNo,~] = fileparts(pathName);
            
            % construct url for download
            url = [contentUrlPath, '/',transactionNo,'/', fileName, fileExt];
            urltoDownload = matlab.ui.internal.URLUtils.applyNonceAndCSRFTokenToDownloadURL(url);
            
            % construct viewData
            ViewData.action = 'handleFileDownload';
            ViewData.fileName = strcat(fileName, fileExt);
            ViewData.urltoDownload = urltoDownload;    
            % publish message to view
            message.publish(channelId, ViewData);
        end

        % -----------------------------------------------------------------
        % Functions for validating file dialog inputs and outputs
        % -----------------------------------------------------------------

        % Function to validate PathName property
        function pathName = validatePathName(pathName)
            if ~isempty(pathName)
                % check pathName value and parse it
                matlab.ui.internal.dialog.FileDialogHelper.validateInputType(pathName, 'PathName');
                pathName = matlab.ui.internal.dialog.FileDialogHelper.pathParser(pathName);
            else
                % Assign pwd when pathName is empty
                pathName = pwd;
            end
        end

        % Function to validate Title property
        function validateTitle(title)
            if ~isempty(title)
                matlab.ui.internal.dialog.FileDialogHelper.validateInputType(title, 'Title');
            end
        end

        % Function to validate MultiSelection property
        function validateMultiSelection(multiSelect)
            % Error for non-logical values
            if ~islogical(multiSelect)
                error(message('MATLAB:UiFileOpenDialog:InvalidMultiSelection'));
            end
        end

        % Function to validate fileFilter property
        function fileFilter = validateFileFilter(fileFilter)
            % Check for char type and convert it cell array
            if ischar(fileFilter)
                fileFilter = {fileFilter};
            end
            % Error when fileFilter is not a cell array or its size is > 2
            if ~iscell(fileFilter)
                error(message('MATLAB:AbstractFileDialog:IllegalFileFilterParameter'));
            end
            fileFilterColumns = size(fileFilter, 2);
            if fileFilterColumns > 2
                error(message('MATLAB:AbstractFileDialog:IllegalFileFilterSpecification'));
            end
            
            % convert to cell array of char vectors. This is required when
            % fileFilter contains string values. unique function does not
            % support string values.
            arrayToFilter = cellstr(fileFilter);
            % Remove duplicate file filter rows
            if fileFilterColumns == 2
                arrayToFilter = strcat(arrayToFilter(:,1), arrayToFilter(:,2));
            end
            [~, idx] = unique(arrayToFilter, 'stable');
            fileFilter = fileFilter(idx, :);
        end
        
        % Function to validate fileName property
        function fileName = validateFileName(fileName)
            matlab.ui.internal.dialog.FileDialogHelper.validateInputType(fileName, 'FileName');
            % Allowed filename values
            if any(ismember({'.', '..'}, fileName))
                fileName = '';
            end
        end

        % Check to see if the non-empty input variable is really a char type
        % if not, error out and tell the user which variable is bad.
        function validateInputType(value, varName)
            stringsz = size(value);
            if ~isempty(value) && ~(ischar(value) && isvector(value) && stringsz(1) == 1)
                error(message('MATLAB:AbstractBaseFileDialog:BadStringArgument', varName))
            end
        end

        % Sets the path using the cd function and takes care of all
        % platforms. The initial directory to be set is
        % determined in MATLAB code using the CD function since it can
        % handle special paths like ../.. , ~ , etc. Note that the isfolder
        % function only determines if a given directory is a valid
        % directory. However, we need to rely on CD to convert special
        % characters to a full meaningful string directory name. 
        function full = pathParser(pathName)
            if (isfolder(pathName) && ~strcmp(pwd,pathName)) % Optimization for g848532
                nameconflictwarning = warning('off','MATLAB:dispatcher:nameConflict');
                pathwarning = warning('off','MATLAB:dispatcher:pathWarning');
                c = onCleanup(@() matlab.ui.internal.dialog.FileDialogHelper.warnGuard(pathwarning,nameconflictwarning));
                try
                    % g3234938- If the platform is Windows, use "_canonicalizepath"
                    % as a quick sanity check before returning the original
                    % pathName, as the new JSD Windows file dialogs can
                    % read special paths like "../.." and truncation. Mac
                    % and Linux will continue to use "cd" because they do
                    % not truncate file paths and cannot read special paths
                    if ispc
                        builtin("_canonicalizepath", pathName);
                        full = pathName;
                    else
                         cur = cd(pathName);
                         full = cd(cur);
                    end
                catch ex
                    newEx = MException(ex.identifier,'%s', getString(message('MATLAB:AbstractBaseFileDialog:InvalidDirectoryToOperateOn')));
                    newEx.addCause(ex);
                    newEx.throw;
                end
            else
                full = pwd;
            end
        end

        % Function for warning used in pathParser
        function warnGuard(pathwarning,nameconflictwarning)
            warning(pathwarning);
            warning(nameconflictwarning);
        end

        % Function to update pathname from filename given
        function [pathName, fileName] = updatePathName(pathName, fileName)
            if isempty(fileName)
                pathName = [pathName, filesep];
                fileName = '';
            else
                x = warning('off','MATLAB:dispatcher:nameConflict');
                % try to check if the path and file make up a valid path.
                % Then we need to call setCurrentDirectory.
                % Example uigetfile('D:/Work') parses into
                % pathName - D:/
                % fileName - Work
                % while we actually need pathName to be
                % 'D:/Work'. Hence we try to concat the path and
                % filename to see if we can make up a valid path
                % and then try to cd to it. This way, we eliminate
                % the need for a trailing slash after 'D:/Work'.
                dir = [pathName, filesep, fileName];
                if isfolder(dir)
                    pathName = dir;
                    fileName = '';
                end
                warning(x);
            end
        end

        function isWebUI = isWebUI(newSetting)
            % This determines whether MATLAB is web-enabled, which decides
            % whether the web-based file dialogs and filters should be used
            import matlab.internal.capability.Capability;
            persistent webUIsetting
            if isempty(webUIsetting)
                useLocal = Capability.isSupported(Capability.LocalClient);
                % Web-based file dialogs are already enabled in MATLAB
                % Online, so return true if environment is MO
                % g3456332 - Remove the isMATLABOnline check and other
                % "webui"-related checks when we're OBD in R2025a
                isMATLABOnline = ~useLocal && ~(isdeployed && matlab.internal.environment.context.isWebAppServer);
                webUIsetting = logical(feature('webui')) || isMATLABOnline;
            end
            if nargin == 1
                % Added for testing purposes
                assert(isa(newSetting, 'logical'))
                webUIsetting = newSetting;
            end
            isWebUI = webUIsetting;
        end

        function isDeployedEnv = isDeployedEnv(newSetting)
            % This mainly checks whether the environment is a Web App
            % Server. The function will return "false" if the deployed
            % environment is a standalone app.
            persistent deployed
            if isempty(deployed)
                s = settings;
                deployed = s.matlab.ui.dialog.fileIO.ShowInWebApps.ActiveValue || ...
                    (isdeployed && matlab.internal.environment.context.isWebAppServer);
            end
            if nargin == 1
                % Added for testing purposes
                assert(isa(newSetting, 'logical'))
                deployed = newSetting;
            end
            isDeployedEnv = deployed;
        end
    end
end
