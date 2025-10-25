classdef ROSLoggingSpecifier < matlab.apps.AppBase
    %This class is for internal use only. It may be removed in the future.

    % ROSLoggingSpecifier opens a dialog that lets the user configure
    % logging options for logging ROS or ROS2 bus signals to a bag file. Once the
    % user accepts the changes, the information is saved in the specified
    % model workspace.
    %
    % Sample use:
    %  dlg = ros.slros.internal.dlg.ROSLoggingSpecifier(modelName);

    %   Copyright 2022-2024 The MathWorks, Inc.

    % Properties that correspond to app components
    properties (Access = public)
        FigContainer                      matlab.ui.Figure
        GridLayout                        matlab.ui.container.GridLayout
        LogOptionDropDown                 matlab.ui.control.DropDown
        LogOptionDropDownLabel            matlab.ui.control.Label
        LogNameEditField                  matlab.ui.control.EditField
        LogNameEditFieldLabel             matlab.ui.control.Label
        GenBagCheckbox                    matlab.ui.control.CheckBox
        MessageTable                      matlab.ui.control.Table
        EnableAllCheckbox                 matlab.ui.control.CheckBox
        CompFormatDropDown                matlab.ui.control.DropDown
        CompFormatDropDownLabel           matlab.ui.control.Label
        CompModeDropDown                  matlab.ui.control.DropDown
        CompModeDropDownLabel             matlab.ui.control.Label
        ChunkSizeEditField                matlab.ui.control.NumericEditField
        ChunkSizeEditFieldLabel           matlab.ui.control.Label
        CacheSizeEditField                matlab.ui.control.NumericEditField
        CacheSizeEditFieldLabel           matlab.ui.control.Label
        SplitSizeEditField                matlab.ui.control.NumericEditField
        SplitSizeEditFieldLabel           matlab.ui.control.Label
        SplitDurationEditField            matlab.ui.control.NumericEditField
        SplitDurationEditFieldLabel       matlab.ui.control.Label
        SerialFormatDropDown              matlab.ui.control.EditField
        SerialFormatDropDownLabel         matlab.ui.control.Label
        StorageFormatDropDown             matlab.ui.control.DropDown
        StorageFormatDropDownLabel        matlab.ui.control.Label
        StorageProfileDropDown            matlab.ui.control.DropDown
        StorageProfileDropDownLabel       matlab.ui.control.Label
        StorageConfigFileEditField        matlab.ui.control.EditField
        StorageConfigFileEditFieldLabel   matlab.ui.control.Label
        StorageConfigFileBrowserButton    matlab.ui.control.Button
        PlaceholderLabel                  matlab.ui.control.Label
        CancelButton                      matlab.ui.control.Button
        OKButton                          matlab.ui.control.Button
        HelpButton                        matlab.ui.control.Button
    end

    % Properties that define Simulink workspace variable names
    properties (Constant,Hidden)
        % MessageTableVarName contains block path/port index, message name,
        % and message type. For example:
        % {true, 'Blank Message', 'my_topic_blank_message_blk', ...
        % 'geometry_msgs/Transform'}
        MessageTableVarName = 'ROSLoggingTable_';
        % LoggingInfoVarName contains log file name, generate bag option, 
        % compression format, and chunk size. 
        LoggingInfoVarName = 'ROSLoggingInfo_';
        % ReloadInfoVarName contains BlockPathInfo, EnableInfo, and
        % TopicNameInfo for table reload.
        ReloadInfoVarName = 'ROSLoggingReload_';
    end

    properties (Access = private)
        ModelName % ModelName
        ModelWkspc % Model workspace
        FilePathPrefix % Custom file path prefix
        BlkPaths % Full path to blocks
        OriginalLogged  % Original logging setting for valid signals
        PreviousTopicNames % Previous topic name in MessageTable
        PreviousChunkSize  % Previous chunk size
        PreviousCacheSize % Previous cache size
        PreviousSplitSize  % Previous bag split size
        PreviousSplitDuration  % Previous bag split duration
        HighlightLineHandle % Line handle of the highlighted signal
        version % ROS version
    end

    methods (Access = private)
        function setPositionWrtModelWindow(app)
        % There is no way to set the size of the DDG Window (using MCOS)
        % without specifying the location as well. So set the location
        % relative to the model window
            pos = get_param(app.ModelName, 'Location'); % [x y width height] (in pixels)
                                                        % position the dialog 1/10 of the way from top-left corner
                                                        % When right monitor is primary and model is on left, width
                                                        % can be negative ([-1772 59 -958 589]) - hence using "abs"
            set(0,'units','pixels')  
            pixelSize = get(0,'screensize');
            xyPos = round([pos(1)+ abs(pos(3)/10) pos(2)+ abs(pos(4)/10)]);
            xPos = xyPos(1);
            yPos = pixelSize(4) - (xyPos(2) + app.FigContainer.Position(4));
            wd = app.FigContainer.Position(3);
            ht = app.FigContainer.Position(4);
            app.FigContainer.Position = [xPos yPos wd ht];
        end

        function throwError(app,errTitle,errMsg)
            uialert(app.FigContainer, errMsg, errTitle,'Icon','error','Modal',true);
        end

        function msgTableData = initializeMsgTable(app)
        % INITIALIZEMSGTABLE Generate the data table that will be used in
        % the 'MessageTable' widget.

            % Make sure all models has been loaded
            find_mdlrefs(app.ModelName,'KeepModelsLoaded',true, 'MatchFilter',@Simulink.match.allVariants);

            % Generate table contents from model
            % ros.slros.internal.ROSUtil(app.ModelName);
            [msgTableData, blkFullPaths] = ros.slros.internal.ROSUtil.generateTableFromTop(app.ModelName);
            
            % Close app if there is no valid message in model
            if ~isempty(msgTableData)
                % Reuse setup from last launch app if there is any
                logInfo = ros.slros.internal.ROSUtil.getROSLoggingSettings(app.ModelName);
                if ~isempty(logInfo.ROSLoggingReload)
                    for i = 1:numel(blkFullPaths)
                        % Compare with each row in logInfo.ROSLoggingReload
                        for j = 1:numel(logInfo.ROSLoggingReload(:,1))
                            if strcmp(blkFullPaths{i,1},logInfo.ROSLoggingReload{j,1})
                                % Update enable info (g2897686)
                                msgTableData{i,1} = msgTableData{i,1} && logInfo.ROSLoggingReload{j,2};
                                % Update topic name info
                                msgTableData{i,3} = logInfo.ROSLoggingReload{j,3};
                                % Move on to next message
                                break;
                            end
                        end
                    end
                end
    
                % Update variables in App
                app.BlkPaths = blkFullPaths;
                app.OriginalLogged = msgTableData(:,1);
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)
        % Code that executes after component creation
        function startupFcn(app, modelName)
            
            app.ModelWkspc = get_param(app.ModelName,'ModelWorkspace');
            logInfo = ros.slros.internal.ROSUtil.getROSLoggingSettings(modelName);

            if strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                app.CompFormatDropDown.Items = {'none', 'zstd'};
            end
            if isempty(logInfo.ROSLoggingInfo)
                % Never open App before or did not click "OK" to save
                % settings before. Use default settings.
                app.FilePathPrefix = '';
                app.LogOptionDropDown.Value = 'Default';
                app.LogNameEditField.Enable = 'off';
                app.GenBagCheckbox.Value = true;
                % Set the properties to the default value
                if strcmp(app.version,'Robot Operating System (ROS)')
                    app.CompFormatDropDown.Value = 'uncompressed';
                    app.ChunkSizeEditField.Value = 786432;
                elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                    app.CompFormatDropDown.Value = 'none';
                    app.CacheSizeEditField.Value = 104857600;
                    app.SerialFormatDropDown.Value = 'cdr';
                    app.StorageFormatDropDown.Value = 'sqlite3';
                    app.StorageProfileDropDown.Value = 'none';
                    app.StorageConfigFileEditField.Value = '';    
                    app.CompModeDropDown.Value = 'none';
                    app.CompModeDropDown.Enable = 'off';
                    app.SplitDurationEditField.Value = Inf;
                    app.SplitSizeEditField.Value = Inf;
                end
            else
                % Set parameters based on previous configuration.
                app.FilePathPrefix = logInfo.ROSLoggingInfo.FilePrefix;
                app.LogOptionDropDown.Value = logInfo.ROSLoggingInfo.LogOption;
                
                if strcmp(app.LogOptionDropDown.Value, 'Default')
                    app.LogNameEditField.Enable = "off";
                else
                    app.LogNameEditField.Enable = "on";
                end
                app.GenBagCheckbox.Value = logInfo.ROSLoggingInfo.GenBagFile;
                % Compression Format has different default values for ROS
                % and ROS 2
                if strcmp(app.version,'Robot Operating System (ROS)')
                    app.ChunkSizeEditField.Value = logInfo.ROSLoggingInfo.ChunkSize;
                    app.CompFormatDropDown.Value = logInfo.ROSLoggingInfo.CompressionFormat;
                elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                    app.CompFormatDropDown.Value = getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'CompressionFormat', 'none');
                    app.StorageFormatDropDown.Value = logInfo.ROSLoggingInfo.StorageFormat;
                    app.StorageProfileDropDown.Value = getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'StorageProfile', 'none');
                    app.StorageConfigFileEditField.Value = getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'StorageConfigFile', '');
                    app.CacheSizeEditField.Value = logInfo.ROSLoggingInfo.CacheSize;
                    % Compression mode dropdown, SplitDuration and
                    % SplitSize edit fields are available for ROS 2.
                    app.CompModeDropDown.Value =  getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'CompressionMode', 'none');
                    if isequal(app.CompModeDropDown.Value, 'none') || isequal(app.StorageFormatDropDown.Value, 'mcap') 
                        % Disable this drop down and default value is set to 'none' as
                        % the default compression format is 'none'
                        app.CompModeDropDown.Enable = 'off';
                    end
                    
                    enableOrDisableCompressionMode(app)
                    % Incase of mcap, disable the dropdown
                    if strcmp(app.StorageFormatDropDown.Value, 'sqlite3')
                        app.StorageProfileDropDown.Visible = 'off';
                        app.StorageProfileDropDownLabel.Visible = 'off';
                        app.StorageProfileDropDown.Value = 'none';
                    elseif strcmp(app.StorageFormatDropDown.Value, 'mcap')
                        app.StorageProfileDropDown.Visible = 'on';
                        app.StorageProfileDropDownLabel.Visible = 'on';
                    end
                    storageConfigProfileChanged(app)
                    app.SplitDurationEditField.Value = getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'SplitDuration', Inf); %logInfo.ROSLoggingInfo.SplitDuration;
                    app.SplitSizeEditField.Value = getFieldOrDefaultValue(app, logInfo.ROSLoggingInfo, 'SplitSize', Inf); %logInfo.ROSLoggingInfo.SplitSize;
                end
            end
            % Show Log name prefix based on previous record (g2903500)
            app.LogNameEditField.Value = app.FilePathPrefix;

            % Show the figure after all the data is enumerated
            app.FigContainer.Visible = 'on';

            % Display a progress bar while loading message information
            progDlg = uiprogressdlg(app.FigContainer,'Title',getString(message('ros:slros:roslogging:ProgressDlgTitle')),...
                'Indeterminate','on');
            drawnow

            % Table content should always grab from model directly.
            app.MessageTable.Data = initializeMsgTable(app);
            close(progDlg)

            if isempty(app.MessageTable.Data)
                mdlName = app.ModelName;

                if strcmp(app.version,'Robot Operating System (ROS)')
                    mdlVersion = 'ROS';
                elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                    mdlVersion = 'ROS2';
                end
                delete(app.FigContainer);
                msgStr = message('ros:slros:roslogging:NoROSMessage',mdlName,mdlVersion).getString;
                dlgTitle = message('ros:slros:roslogging:NoMsgTitle',mdlVersion).getString;
                dlgProvider = DAStudio.DialogProvider;
                dlgProvider.msgbox(msgStr, dlgTitle, true);
            else
                app.PreviousTopicNames = app.MessageTable.Data(:,3);
                
                
                
                if strcmp(app.version,'Robot Operating System (ROS)')
                    
                    app.PreviousChunkSize = app.ChunkSizeEditField.Value;
                    
                    app.FigContainer.Name = getString(message('ros:slros:roslogging:FigROSTitle'));
                    app.LogNameEditFieldLabel.Text = getString(message('ros:slros:roslogging:LogFileName'));
                    app.LogOptionDropDownLabel.Text = getString(message('ros:slros:roslogging:LogOptionFileName'));
                    app.GenBagCheckbox.Text = getString(message('ros:slros:roslogging:GenBagName','ROS'));
                elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                    app.PreviousCacheSize = app.CacheSizeEditField.Value;
                    app.PreviousSplitDuration = app.SplitDurationEditField.Value;
                    app.PreviousSplitSize = app.SplitSizeEditField.Value;

                    app.FigContainer.Name = getString(message('ros:slros:roslogging:FigROS2Title'));
                    app.LogNameEditFieldLabel.Text = getString(message('ros:slros:roslogging:LogFolderName'));
                    app.LogOptionDropDownLabel.Text = getString(message('ros:slros:roslogging:LogOptionFolderName'));
                    app.GenBagCheckbox.Text = getString(message('ros:slros:roslogging:GenBagName','ROS 2'));
                end
    
                % Set the highlight signal - by default, no signal shall be
                % highlighted
                app.HighlightLineHandle = 0.00;
            end
        end

        % Button pushed function: OKButton
        function okButtonPushed(app, ~)
            if ~bdIsLoaded(app.ModelName)
                warning(message('ros:slros:roslogging:ModelAlreadyClosed',app.ModelName));
                delete(app.FigContainer)
                return;
            end
            % Parse Logfile path and name
            if strcmp(app.LogOptionDropDown.Value, 'Default')
                % Default
                parsedFileName = app.ModelName;
            else
                % Custom
                parsedFileName = app.FilePathPrefix;
            end

            % Save logging information to model workspace
            w = app.ModelWkspc;
            tableToBeSaved = app.MessageTable.Data;
            removeIndex = cellfun(@(x) isequal(x,false), tableToBeSaved(:,1));
            tableToBeSaved(removeIndex,:)=[];
            assignin(w, app.MessageTableVarName, tableToBeSaved);

            %Store version specific propeties only
            if strcmp(app.version,'Robot Operating System (ROS)')
                loggingInfo = struct('GenBagFile', app.GenBagCheckbox.Value, ...
                                 'BagFileName', parsedFileName, ...
                                 'CompressionFormat', app.CompFormatDropDown.Value, ...
                                 'ChunkSize', app.ChunkSizeEditField.Value, ...
                                 'LogOption', app.LogOptionDropDown.Value, ...
                                 'FilePrefix',app.FilePathPrefix);
            elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                loggingInfo = struct('GenBagFile', app.GenBagCheckbox.Value, ...
                                 'BagFileName', parsedFileName, ...
                                 'SerializationFormat',app.SerialFormatDropDown.Value,...
                                 'StorageFormat',app.StorageFormatDropDown.Value,...
                                 'StorageProfile',app.StorageProfileDropDown.Value,...
                                 'StorageConfigFile',app.StorageConfigFileEditField.Value,...
                                 'CacheSize',app.CacheSizeEditField.Value,...
                                 'LogOption', app.LogOptionDropDown.Value, ...
                                 'FilePrefix',app.FilePathPrefix, ...
                                 'CompressionFormat', app.CompFormatDropDown.Value, ...
                                 'CompressionMode',app.CompModeDropDown.Value, ...
                                 'SplitDuration', app.SplitDurationEditField.Value, ...
                                 'SplitSize', app.SplitSizeEditField.Value);
            end
            assignin(w, app.LoggingInfoVarName, loggingInfo);

            reloadInfo = [app.BlkPaths, app.MessageTable.Data(:,1), app.MessageTable.Data(:,3)];
            assignin(w, app.ReloadInfoVarName, reloadInfo);

            % Enable signal logging based on new logging information
            originalLogging = app.OriginalLogged;
            updatedLogging = app.MessageTable.Data(:,1);
            needsUpdate = cellfun(@(x,y) x==false && y==true, originalLogging, updatedLogging);
            for updateIndex = 1:numel(needsUpdate)
                if needsUpdate(updateIndex)
                    % Get port handle for the targeting source block
                    portHandle = get_param(app.BlkPaths{updateIndex}, 'PortHandles');
                    % Get the output port number from table
                    targetSrcBlk = app.MessageTable.Data{updateIndex,2};
                    portNum = str2double(extractAfter(targetSrcBlk,':'));
                    % Set DataLogging to 'on'
                    set_param(portHandle.Outport(portNum),'DataLogging','on');
                end
            end

            % Add function to simulink stopFcn callback
            % Get StopFcn and attach save callback if it does not exist
            currentStopFcn = get_param(app.ModelName,"StopFcn");
            % Put a comment as well - "Do not delete, auto generated function to log
            % messages"
            if strcmp(app.version,'Robot Operating System (ROS)')
                commentToAdd = ['% ' getString(message('ros:slros:roslogging:CommentToAddText','ROS'))];
            elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                commentToAdd = ['% ' getString(message('ros:slros:roslogging:CommentToAddText','ROS 2'))];
            end
            
            internalFunctionToAdd = 'ros.slros.internal.ROSUtil.logROSMessageToBagFile(bdroot);';

            if contains(currentStopFcn, internalFunctionToAdd)
                % logging function already exist, no need to add
                set_param(app.ModelName, "StopFcn", currentStopFcn);
            else
                % logging function does not exist, add to stopFcn callback
                set_param(app.ModelName, "StopFcn", sprintf('%s \n %s \n %s', currentStopFcn, commentToAdd, internalFunctionToAdd));
            end
            
            
            currentStartFcn = get_param(app.ModelName, "StartFcn");

            StartFcnToAdd = sprintf("ros.slros.internal.ROSUtil.loggerStartFcn(bdroot)");

            if contains( currentStartFcn, StartFcnToAdd )
                set_param(app.ModelName, "StartFcn", currentStartFcn);
            else
                set_param(app.ModelName, "StartFcn", sprintf('%s \n %s \n %s', currentStartFcn, commentToAdd, StartFcnToAdd))
            end

       % Clear highlight
            if ~isequal(app.HighlightLineHandle, 0)
                hilite_system(app.HighlightLineHandle,'none');
            end

            % Close the dialog
            delete(app.FigContainer);
        end
        
        function value = getFieldOrDefaultValue(~, object, propName, defaultValue)
            value = defaultValue;
            if isfield( object, propName )
                value = object.(propName);
            end
        end

        % Button pushed function: CancelButton
        function cancelButtonPushed(app, ~)
            % Clear highlight
            if ~isequal(app.HighlightLineHandle, 0)
                hilite_system(app.HighlightLineHandle,'none');
            end

            % Close the dialog
            delete(app.FigContainer);
            clear app;
        end

        function configFileButtonPressCallback(app,~)
            title = getString(message('ros:slros:roslogging:TitleStorageConfigFileBrowser'));
            filter = { '*.yaml',getString(message('ros:slros:roslogging:FilterStorageConfigFileBrowser'))};
            [fileName, dirName] = uigetfile(filter, title);
            app.StorageConfigFileEditField.Value = fullfile(dirName, fileName);
        end

        % Button pushed function: HelpButton
        function helpButtonPushed(app, ~)
            if strcmp(app.version,'Robot Operating System (ROS)')
                ros.slros.internal.helpview('LogROSMessagesFromSimulinkToARosbagLogfileExample');
            elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                ros.slros.internal.helpview('LogROS2MessagesFromSimulinkToAROS2BagFileExample');
            end
        end

        %  Edit field value changed function: 
        function validateAndUpdateFileName(app, ~)
            % Naming validation will be handled in rosbagwriter.
            logFileName = convertStringsToChars(app.LogNameEditField.Value);

            [~, fileName, ext] = fileparts(logFileName);

            if isempty(ext)
                % No extension, pass directly
                app.FilePathPrefix = logFileName;
            elseif strcmpi(ext,'.bag') && ~isempty(fileName)
                app.FilePathPrefix = logFileName(1:end-4);
            else
                app.FilePathPrefix = '';
                app.LogNameEditField.Value = '';
                error(message('ros:mlros:bag:RosbagWriterInvalidFileError'));
            end
            
        end

        function updateLogNameDisplay(app, ~)
            if strcmp(app.LogOptionDropDown.Value, 'Default')
                % Default
                app.LogNameEditField.Enable = 'off';
            else
                % Custom
                app.LogNameEditField.Enable = 'on';
            end
        end

        function enableOrDisableCompressionMode(app, ~)
            if strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                if strcmp(app.CompFormatDropDown.Value, 'none')
                    % Default
                    app.CompModeDropDown.Items = {'none','file','message'};
                    app.CompModeDropDown.Enable = 'off';
                    app.CompModeDropDown.Value = 'none';
                elseif strcmp(app.CompFormatDropDown.Value, 'zstd')
                    % when zstd compression format is selected
                    app.CompModeDropDown.Enable = 'on';
                    app.CompModeDropDown.Items = {'file','message'};
                    app.CompModeDropDown.Value = 'file';
                else
                    app.CompModeDropDown.Enable = 'off';
                end
                
                % Incase of mcap, disable the dropdown
                if strcmp(app.StorageFormatDropDown.Value, 'mcap')
                    app.CompModeDropDown.Enable = 'off';
                end

            end
        end
        
        function storageFormatChanged(app, ~)
            
            enableOrDisableCompressionMode(app)

            % Incase of mcap, disable the dropdown
            if strcmp(app.StorageFormatDropDown.Value, 'sqlite3')
                app.StorageProfileDropDown.Visible = 'off';
                app.StorageProfileDropDownLabel.Visible = 'off';
            elseif strcmp(app.StorageFormatDropDown.Value, 'mcap')
                app.StorageProfileDropDown.Visible = 'on';
                app.StorageProfileDropDownLabel.Visible = 'on';
            end
            
            app.StorageProfileDropDown.Value = 'none';
            % As storage profile is none, hide the elements
            app.StorageConfigFileEditField.Visible = 'off';
            app.StorageConfigFileEditFieldLabel.Visible = 'off';
            app.StorageConfigFileBrowserButton.Visible = 'off';
        end
        
        function storageConfigProfileChanged(app, ~)
            if strcmp(app.StorageProfileDropDown.Value, 'custom')
                app.StorageConfigFileEditField.Visible = 'on';
                app.StorageConfigFileEditFieldLabel.Visible = 'on';
                app.StorageConfigFileBrowserButton.Visible = 'on';
            else
                app.StorageConfigFileEditField.Visible = 'off';
                app.StorageConfigFileEditFieldLabel.Visible = 'off';
                app.StorageConfigFileBrowserButton.Visible = 'off';
            end
        end

        function enableAllCheck(app, ~)
            numOfRows = numel(app.MessageTable.Data(:,1));
            if app.EnableAllCheckbox.Value
                % When user checked the "EnableAll", all signals should be
                % configured to enable logging. Note that since users can
                % trigger this back and forth, this callback function will
                % only update the UI. The datalogging will be handled at
                % the end of the program when click "OK".
                 
                app.MessageTable.Data(:,1) = repmat({true},numOfRows,1);
            else
                % When manually uncheck "EnableAll", all signals will be
                % configured to disable logging.

                app.MessageTable.Data(:,1) = repmat({false},numOfRows,1);
            end
        end

        function verifyTopicName(app, event)

            currentRow = event.Indices(1);

            % Ensure there is no duplicate topic name
            for i = 1:numel(app.MessageTable.Data(:,3))
                if ~isequal(i, currentRow) && isequal(app.MessageTable.Data{currentRow,3}, app.MessageTable.Data{i,3})
                    app.MessageTable.Data(:,3) = app.PreviousTopicNames;
                    if strcmp(app.version,'Robot Operating System (ROS)')
                        error(message('ros:slros:roslogging:TopicNameExists', app.MessageTable.Data{currentRow,3},'ROS'));
                    elseif strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                        error(message('ros:slros:roslogging:TopicNameExists', app.MessageTable.Data{currentRow,3},'ROS 2'));
                    end
                end
            end

            % Ensure the new name is valid and write to PreviousTopicNames
            function balancedBrackets()
                if contains(app.MessageTable.Data{currentRow,3},{'{','}'})
                    assert(eq(count(app.MessageTable.Data{currentRow,3},'{'),count(app.MessageTable.Data{currentRow,3},'}')));
                    substring=extractBetween(app.MessageTable.Data{currentRow,3},'{','}');
                    ros.internal.Namespace.canonicalizeName(substring);
                end
            end
            try
                validateattributes(app.MessageTable.Data{currentRow,3},...
                                   {'char', 'string'}, ...
                                   {'scalartext', 'nonempty'});
                
                app.PreviousTopicNames = app.MessageTable.Data(:,3);
                ros.internal.Namespace.canonicalizeName(app.MessageTable.Data{currentRow,3});
                if eq(app.MessageTable.Data{currentRow,3}(1),'~')
                    assert(contains(app.MessageTable.Data{currentRow,3}(1:2),'~/'));
                end
                assert(eq(contains(app.MessageTable.Data{currentRow,3},{'//','__'}),0));
                balancedBrackets();
            catch
                invalidName = app.MessageTable.Data{currentRow,3};
                app.MessageTable.Data(:,3) = app.PreviousTopicNames;
                newEx = ros.internal.ROSException(message('ros:slros:roslogging:TopicNameInvalid', ...
                                                        num2str(i), invalidName));
                errordlg(newEx.message,'Invalid Topic Name');
            end
        end

        function highlightSelectedSignal(app, event)
            rows = event.Indices;
            if isequal(size(rows,1),1) && isequal(rows(2), 2)
                selectedRow = rows(1);
                % Get port handle for the targeting source block
                % Note that this cannot be the second column of the table
                % since model reference will have different representation.
                portHandle = get_param(app.BlkPaths{selectedRow}, 'PortHandles');
                % Get the output port number from table
                targetSrcBlk = app.MessageTable.Data{selectedRow,2};
                portNum = str2double(extractAfter(targetSrcBlk,':'));
                % Get line handle
                outHandle = portHandle.Outport(portNum);
                lineHandle = get_param(outHandle,'Line');
                % Clear previous highlight if there exists
                if ~isequal(app.HighlightLineHandle, 0.00)
                    hilite_system(app.HighlightLineHandle,'none');
                end
                % Highlight selected line and update app.HighlightLineHandle
                hilite_system(lineHandle);
                app.HighlightLineHandle = lineHandle;
            end
        end

        function validateChunkSize(app, ~)
            newValue = app.ChunkSizeEditField.Value;
            app.ChunkSizeEditField.Value = app.PreviousChunkSize;
            validateattributes(newValue,{'numeric'}, ...
                               {'scalar','finite','positive','integer'}, ...
                               'ROS Logger', 'ChunkSize');
            app.ChunkSizeEditField.Value = newValue;
            app.PreviousChunkSize = newValue;
        end

        function validateCacheSize(app,~)
            newValue = app.CacheSizeEditField.Value;
            app.CacheSizeEditField.Value = app.PreviousCacheSize;
            validateattributes(newValue,{'numeric'}, ...
                               {'scalar','finite','nonnegative','integer'}, ...
                               'ROS Logger', 'CacheSize');
            app.CacheSizeEditField.Value = newValue;
            app.PreviousCacheSize = newValue;
        end

        function validateSplitSize(app,~)
            newValue = app.SplitSizeEditField.Value;
            app.SplitSizeEditField.Value = app.PreviousSplitSize;
            validateattributes(newValue,{'numeric'}, ...
                               {'nonempty','scalar','positive','>=', 84}, ...
                               'ROS Logger', 'SplitSize');
            app.SplitSizeEditField.Value = newValue;
            app.PreviousSplitSize = newValue;
        end

        function validateSplitDuration(app,~)
            newValue = app.SplitDurationEditField.Value;
            app.SplitDurationEditField.Value = app.PreviousSplitDuration;
            validateattributes(newValue,{'numeric'}, ...
                               {'nonempty','scalar','nonnegative'}, ...
                               'ROS Logger', 'SplitDuration');
            app.SplitDurationEditField.Value = newValue;
            app.PreviousSplitDuration = newValue;
        end
    end

    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            % Create FigContainer and hide until all components are created
            iconPath = fullfile(matlabroot,'toolbox','ros','sltoolstrip','icons','configureROSLogging_16.png');
            app.FigContainer = uifigure('Visible', 'off', 'Icon',iconPath,'Resize','off');
            app.FigContainer.NumberTitle = 'on';
            app.FigContainer.Position = [100 100 570 730];
            app.GridLayout = uigridlayout(app.FigContainer, ...
                [11 4], ...
                'RowHeight',{'fit','fit','fit','1x','fit','fit','fit','fit','fit','fit','fit'}, ...
                'ColumnWidth',{120,'fit',120,120});

            rowNum = 1;

            % Create LogOptionDropDownLabel and LogOptionDropDown 
            app.LogOptionDropDownLabel = uilabel(app.GridLayout);
            app.LogOptionDropDownLabel.Layout.Row = rowNum;
            app.LogOptionDropDownLabel.Layout.Column = 1;
            app.LogOptionDropDownLabel.Text = getString(message('ros:slros:roslogging:LogOptionFileName'));
            app.LogOptionDropDown = uidropdown(app.GridLayout);
            app.LogOptionDropDown.Items = {'Default', 'Custom'};
            app.LogOptionDropDown.Layout.Row = rowNum;
            app.LogOptionDropDown.Layout.Column = [2 3];
            app.LogOptionDropDown.ValueChangedFcn = createCallbackFcn(app, @updateLogNameDisplay, true);

            rowNum = rowNum + 1;

            % Create LogNameEditFieldLabel and LogNameEditField
            app.LogNameEditFieldLabel = uilabel(app.GridLayout);
            app.LogNameEditFieldLabel.Layout.Row = rowNum;
            app.LogNameEditFieldLabel.Layout.Column = 1;
            app.LogNameEditFieldLabel.Text = getString(message('ros:slros:roslogging:LogFileName'));
            

            app.LogNameEditField = uieditfield(app.GridLayout);
            app.LogNameEditField.Layout.Row = rowNum;
            app.LogNameEditField.Layout.Column = [2 3];
            app.LogNameEditField.Value = '';
            app.LogNameEditField.ValueChangedFcn = createCallbackFcn(app, @validateAndUpdateFileName, true);

            rowNum = rowNum + 1;

            % Create GenBagCheckbox
            app.GenBagCheckbox = uicheckbox(app.GridLayout);
            app.GenBagCheckbox.Text = '';
            app.GenBagCheckbox.Layout.Row = rowNum;
            app.GenBagCheckbox.Layout.Column = [1 3];

            rowNum = rowNum + 1;

            % Create MessageTable
            app.MessageTable = uitable(app.GridLayout,'ColumnWidth',{80,150,150,150});
            app.MessageTable.ColumnName = {'Enable'; 'Source'; 'Topic name'; 'Message Type'};
            app.MessageTable.RowName = {};
            app.MessageTable.ColumnSortable = [true false false false];
            app.MessageTable.ColumnEditable = [true false true false];
            app.MessageTable.CellEditCallback = createCallbackFcn(app, @verifyTopicName, true);
            app.MessageTable.CellSelectionCallback = createCallbackFcn(app, @highlightSelectedSignal, true);
            app.MessageTable.Layout.Row = rowNum;
            app.MessageTable.Layout.Column = [1 4];
            
            % Create EnableAllCheckbox
            app.EnableAllCheckbox = uicheckbox(app.FigContainer);
            app.EnableAllCheckbox.Text = '';
            app.EnableAllCheckbox.Position = [64 605 25 22];
            app.EnableAllCheckbox.ValueChangedFcn = createCallbackFcn(app, @enableAllCheck, true);

            % Create a PlaceholderLabel to prevent user from changing the 
            % width of the first column in MessageTable interactively 
            app.PlaceholderLabel = uilabel(app.FigContainer);
            app.PlaceholderLabel.Text = '   ';
            app.PlaceholderLabel.Position = [85 250 100 30];

            rowForInputs = rowNum + 1;

            if strcmp(app.version,'Robot Operating System (ROS)')
                rowNum = rowNum + 1;
                % ROS1: Create ChunkSizeEditFieldLabel and ChunkSizeEditField
                app.ChunkSizeEditFieldLabel = uilabel(app.GridLayout);
                app.ChunkSizeEditFieldLabel.Layout.Row = rowNum;
                app.ChunkSizeEditFieldLabel.Layout.Column = [1 2];
                app.ChunkSizeEditFieldLabel.Text = getString(message('ros:slros:roslogging:ChunkSizeName'));
    
                app.ChunkSizeEditField = uieditfield(app.GridLayout, 'numeric');
                app.ChunkSizeEditField.ValueDisplayFormat = '%.0f';
                app.ChunkSizeEditField.Layout.Row = rowNum;
                app.ChunkSizeEditField.Layout.Column = 2;
                app.ChunkSizeEditField.ValueChangedFcn = createCallbackFcn(app, @validateChunkSize, true);
            end

            if strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                rowNum = rowNum + 1;
    
                % Create StorageFormatDropDownLabel and StorageFormatDropDown
                app.StorageFormatDropDownLabel = uilabel(app.GridLayout);
                app.StorageFormatDropDownLabel.Layout.Row = rowNum;
                app.StorageFormatDropDownLabel.Layout.Column = [1 2];
                app.StorageFormatDropDownLabel.Text = getString(message('ros:slros:roslogging:StorageFormatLabel'));
    
                app.StorageFormatDropDown = uidropdown(app.GridLayout);
                app.StorageFormatDropDown.Items = {'sqlite3', 'mcap'};
                % Drop down menu does not like utf-8 characters
                app.StorageFormatDropDown.Value = 'sqlite3';
                app.StorageFormatDropDown.Layout.Row = rowNum;
                app.StorageFormatDropDown.Layout.Column = 2;

                app.StorageFormatDropDown.ValueChangedFcn = createCallbackFcn(app, @storageFormatChanged, true);
            end
            
            

            rowNum = rowNum + 1;
 
            % ROS1 & ROS2 : Create CompFormatDropDownLabel and CompFormatDropDown
            app.CompFormatDropDownLabel = uilabel(app.GridLayout);
            app.CompFormatDropDownLabel.Layout.Row = rowNum;
            app.CompFormatDropDownLabel.Layout.Column = [1 2];
            app.CompFormatDropDownLabel.Text = getString(message('ros:slros:roslogging:CompFormatLabel'));

            app.CompFormatDropDown = uidropdown(app.GridLayout);
            % Drop down menu does not like utf-8 characters
            app.CompFormatDropDown.Items = {'uncompressed', 'bz2', 'lz4'};
            app.CompFormatDropDown.Layout.Row = rowNum;
            app.CompFormatDropDown.Layout.Column = 2;
            app.CompFormatDropDown.ValueChangedFcn = createCallbackFcn(app, @enableOrDisableCompressionMode, true);

            
            if strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                rowNum = rowNum + 1;
    
                % ROS2: Create CompModeDropDownLabel and CompModeDropDown
                app.CompModeDropDownLabel = uilabel(app.GridLayout);
                app.CompModeDropDownLabel.Layout.Row = rowNum;
                app.CompModeDropDownLabel.Layout.Column = [1 2];
                app.CompModeDropDownLabel.Text = getString(message('ros:slros:roslogging:CompModeLabel'));
    
                app.CompModeDropDown = uidropdown(app.GridLayout);
                % Drop down menu does not like utf-8 characters
                % If compression format is none, compression drop down contains
                % drop down items as none, file, message and the drop down is
                % disabled. If the compression format is other that none, then
                % compression mode drop down items are file and message.
                if isequal(app.CompFormatDropDown.Value, 'zstd')
                    app.CompModeDropDown.Items = {'file','message'};
                    app.CompModeDropDown.Value = 'file';
                else
                    app.CompModeDropDown.Items = {'none', 'file','message'};
                    app.CompModeDropDown.Value = 'none';
                    app.CompModeDropDown.Enable = 'off';
                end
    
                % If storage format is mcap, disable the dropdown
                if isequal(app.StorageFormatDropDown.Value, 'mcap')
                    app.CompModeDropDown.Enable = 'off';
                end
    
                app.CompModeDropDown.Layout.Row = rowNum;
                app.CompModeDropDown.Layout.Column = 2;
    
                rowNum = rowNum + 1;
    
                % Create SerialFormatDropDownLabel and SerialFormatDropDown
                app.SerialFormatDropDownLabel = uilabel(app.GridLayout);
                app.SerialFormatDropDownLabel.Layout.Row = rowNum;
                app.SerialFormatDropDownLabel.Layout.Column = [1 2];
                app.SerialFormatDropDownLabel.Text = getString(message('ros:slros:roslogging:SerialFormatLabel'));
    
                app.SerialFormatDropDown = uieditfield(app.GridLayout);
                % Drop down menu does not like utf-8 characters
                app.SerialFormatDropDown.Value = 'cdr';
                app.SerialFormatDropDown.Layout.Row = rowNum;
                app.SerialFormatDropDown.Layout.Column = 2;
                app.SerialFormatDropDown.Editable = 'off';

                rowNum = rowNum + 1;
    
                % Create StorageFormatDropDownLabel and StorageFormatDropDown
                app.StorageProfileDropDownLabel = uilabel(app.GridLayout);
                app.StorageProfileDropDownLabel.Layout.Row = rowNum;
                app.StorageProfileDropDownLabel.Layout.Column = [1 2];
                app.StorageProfileDropDownLabel.Text = getString(message('ros:slros:roslogging:StorageConfigProfileLabel'));
    
                app.StorageProfileDropDown = uidropdown(app.GridLayout);
                app.StorageProfileDropDown.Items = {'none', 'fastwrite', 'zstd_fast', 'zstd_small', 'custom'};
                % Drop down menu does not like utf-8 characters
                app.StorageProfileDropDown.Value = 'none';
                app.StorageProfileDropDown.Layout.Row = rowNum;
                app.StorageProfileDropDown.Layout.Column = 3;
                
                % As default selection is sqlite3, make this hide
                app.StorageProfileDropDownLabel.Visible = "off";
                app.StorageProfileDropDown.Visible = "off";
                app.StorageProfileDropDown.ValueChangedFcn = createCallbackFcn(app, @storageConfigProfileChanged, true); 


                rowNum = rowNum + 1;

                % Create StorageConfigFileEditboxLabel and StorageConfigFileEditbox
                app.StorageConfigFileEditFieldLabel = uilabel(app.GridLayout);
                app.StorageConfigFileEditFieldLabel.Layout.Row = rowNum;
                app.StorageConfigFileEditFieldLabel.Layout.Column = [1 2];
                app.StorageConfigFileEditFieldLabel.Text = getString(message('ros:slros:roslogging:StorageConfigFileLabel'));

                app.StorageConfigFileEditField = uieditfield(app.GridLayout);

                app.StorageConfigFileEditField.Value = "";
                app.StorageConfigFileEditField.Layout.Row = rowNum;
                app.StorageConfigFileEditField.Layout.Column = 3;
                app.StorageConfigFileEditField.Editable = "off";

                app.StorageConfigFileBrowserButton = uibutton(app.GridLayout, 'push');
                app.StorageConfigFileBrowserButton.Layout.Row = rowNum;
                app.StorageConfigFileBrowserButton.Layout.Column = 4;
                app.StorageConfigFileBrowserButton.Text = 'Open';
                app.StorageConfigFileBrowserButton.ButtonPushedFcn = createCallbackFcn(app, @configFileButtonPressCallback, true);

                % As default selection is sqlite3, make this hide
                app.StorageConfigFileEditFieldLabel.Visible = "off";
                app.StorageConfigFileEditField.Visible = "off";
                app.StorageConfigFileBrowserButton.Visible = "off";
                
            end
            
            

            rowNum = rowNum + 1;

            % Create HelpButton
            app.HelpButton = uibutton(app.GridLayout, 'push');
            app.HelpButton.Layout.Row = rowNum;
            app.HelpButton.Layout.Column = 1;
            app.HelpButton.Text = 'Help';
            app.HelpButton.ButtonPushedFcn = createCallbackFcn(app, @helpButtonPushed, true);

            % Create OKButton
            app.OKButton = uibutton(app.GridLayout, 'push');
            app.OKButton.Layout.Row = rowNum;
            app.OKButton.Layout.Column = 3;
            app.OKButton.Text = 'OK';
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @okButtonPushed, true);

            % Create CancelButton
            app.CancelButton = uibutton(app.GridLayout, 'push');
            app.CancelButton.Layout.Row = rowNum;
            app.CancelButton.Layout.Column = 4;
            app.CancelButton.Text = 'Cancel';
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @cancelButtonPushed, true);

            % Start adding 2nd column
            rowNum = rowForInputs;
            
            if strcmp(app.version,'Robot Operating System 2 (ROS 2)')
                rowNum = rowNum + 1;
                % Create CacheSizeEditFieldLabel and CacheSizeEditField
                app.CacheSizeEditFieldLabel = uilabel(app.GridLayout);
                app.CacheSizeEditFieldLabel.Layout.Row = rowNum;
                app.CacheSizeEditFieldLabel.Layout.Column = [3 4];
                app.CacheSizeEditFieldLabel.Text = getString(message('ros:slros:roslogging:CacheSizeName'));
    
                app.CacheSizeEditField = uieditfield(app.GridLayout, 'numeric');
                app.CacheSizeEditField.ValueDisplayFormat = '%.0f';
                app.CacheSizeEditField.Layout.Row = rowNum;
                app.CacheSizeEditField.Layout.Column = 4;
                app.CacheSizeEditField.ValueChangedFcn = createCallbackFcn(app, @validateCacheSize, true);
    
                rowNum = rowNum + 1;
    
                % Create SplitDurationEditFieldLabel and SplitDurationEditField
                app.SplitDurationEditFieldLabel = uilabel(app.GridLayout);
                app.SplitDurationEditFieldLabel.Layout.Row = rowNum;
                app.SplitDurationEditFieldLabel.Layout.Column = [3 4];
                app.SplitDurationEditFieldLabel.Text = getString(message('ros:slros:roslogging:SplitDurationName'));
                app.SplitDurationEditField = uieditfield(app.GridLayout, 'numeric');
                app.SplitDurationEditField.ValueDisplayFormat = '%.0f';
                app.SplitDurationEditField.Layout.Row = rowNum;
                app.SplitDurationEditField.Layout.Column = 4;
                app.SplitDurationEditField.ValueChangedFcn = createCallbackFcn(app, @validateSplitDuration, true);
    
                rowNum = rowNum + 1;
    
                % Create SplitSizeEditFieldLabel and SplitSizeEditField
                app.SplitSizeEditFieldLabel = uilabel(app.GridLayout);
                app.SplitSizeEditFieldLabel.Layout.Row = rowNum;
                app.SplitSizeEditFieldLabel.Layout.Column = [3 4];
                app.SplitSizeEditFieldLabel.Text = getString(message('ros:slros:roslogging:SplitSizeName'));
                app.SplitSizeEditField = uieditfield(app.GridLayout, 'numeric');
                app.SplitSizeEditField.ValueDisplayFormat = '%.0f';
                app.SplitSizeEditField.Layout.Row = rowNum;
                app.SplitSizeEditField.Layout.Column = 4;
                app.SplitSizeEditField.ValueChangedFcn = createCallbackFcn(app, @validateSplitSize, true);
            end
        end
    end

    % App creation and deletion
    methods (Access = public)
        % Construct app
        function app = ROSLoggingSpecifier(varargin)
            runningApp = getRunningApp(app);
            % Check for running singleton app
            if isempty(runningApp)

                % Set app version and other model settings
                modelName = varargin{1};
                open_system(modelName);
                app.ModelName = modelName;
                activeConfigObj = getActiveConfigSet(app.ModelName);
                app.version=get_param(activeConfigObj,'HardwareBoard');

                % Create UIFigure and components
                createComponents(app);

                % Register the app with App Designer
                registerApp(app, app.FigContainer);

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}));
            else
                % Focus the running singleton app
                figure(runningApp.FigContainer);

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % Clear highlight
            if ~isequal(app.HighlightLineHandle, 0)
                hilite_system(app.HighlightLineHandle,'none');
            end

            % Delete UIFigure when app is deleted
            delete(app.FigContainer);
        end
    end
end
