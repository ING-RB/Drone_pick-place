%   Generate C++ Interface live task

%   Copyright 2022 The MathWorks, Inc.
classdef GenerateCppInterfaceTask < matlab.task.LiveTask
    properties (SetAccess = private, Transient, Hidden, GetAccess = public)
        TabGroup                            matlab.ui.container.TabGroup
        Platform                            clibgen.task.internal.PlatformView
        SelectedPlatform                    double
        NewPlatformAlert                    (1,1) logical = false
    end
    properties (Hidden, SetAccess = private, GetAccess = public)
        % Listeners
        TaskStateChangedListener            event.listener
    end
    properties (Access = private, Hidden)
        % True only if the live task is embedded in the live script
        % named publishInterfaceWorkflowTemplate
        CurrentTaskInTemplate                 (1,1) logical = false
    end
    properties
        State
        Summary
    end
    methods (Access = protected)
        function setup(task)
            % Detect embedded live task in retail template script
            currentLiveScript = matlab.desktop.editor.getActiveFilename;
            if ~isempty(currentLiveScript)
                retailLiveScript = fullfile(matlabroot,'toolbox','matlab','external', ...
                    'interfaces','cpp','internal','publishInterfaceWorkflowTemplate.mlx');
                if strcmp(currentLiveScript,retailLiveScript)
                    task.CurrentTaskInTemplate = true;
                end
            end
            % Return if template script
            if task.CurrentTaskInTemplate
                task.AutoRun = false;
                return;
            end
            task.TabGroup = uitabgroup(task.LayoutManager,'TabLocation','top',...
                'Tooltip',getString(message('MATLAB:CPPUI:TabGroupTooltip')),...
                'SelectionChangedFcn', @(e,d) task.tabSelectionChanged(d.OldValue,d.NewValue));
            task.AutoRun = false;
        end
    end
    methods
        function state = get.State(task)
            state.platforms = [];
            % Return if template script
            if task.CurrentTaskInTemplate
                return;
            end
            %  Set state each available platform tab
            if (isempty(task.Platform))
                return;
            end
            for idx = 1:length(task.TabGroup.Children)
                currentPlatform = task.TabGroup.Children(idx).Tag;
                platform = task.Platform(idx);
                state.platforms.(currentPlatform) = platform.getStateForPlatform(currentPlatform);
            end
        end
        function set.State(task, state)
            % Return if template script
            if task.CurrentTaskInTemplate
                return;
            end
            if isempty(task.SelectedPlatform)
                currentPlatform = computer("arch");
                % Special case with no tabs for template script
                if isempty(state.platforms)
                    task.platformAdd(currentPlatform);
                    task.SelectedPlatform = 1;
                    return;
                end
                platformTabNames = fieldnames(state.platforms);
                for idx = 1:length(platformTabNames)
                    % Create tab if non-existent for state.platforms(tabName)
                    tabName = char(platformTabNames(idx));
                    task.platformAdd(tabName);
                    task.Platform(idx).setStateForPlatform(state.platforms.(tabName));
                end
                % Determine tab to select and give focus
                [tabExist,tabIndex] = task.isTabExist(currentPlatform);
                if tabExist
                    task.TabGroup.SelectedTab = task.TabGroup.Children(tabIndex);
                else
                    task.TabGroup.SelectedTab = task.TabGroup.Children(end);
                end
                task.tabSelectionChanged([],task.TabGroup.SelectedTab);
                task.NewPlatformAlert = ~tabExist;
            end
        end
        function summary = get.Summary(task)
            % Return if template script
            if task.CurrentTaskInTemplate
                summary = getString(message('MATLAB:CPPUI:TaskSummaryDefault',''));
                return;
            end
            % Prompt and confirm new platform
            task.alertNewPlatform;
            % Create current platform if empty selected platform
            if isempty(task.SelectedPlatform)
                task.platformAdd(computer("arch"));
                task.SelectedPlatform = 1;
            end
            summary = task.Platform(task.SelectedPlatform).Summary;
        end
        function [code, outputs] = generateCode(task)
            [code, outputs] = task.Platform(task.SelectedPlatform).generateCode(task.Platform);
        end
        function reset(task)
            task.Platform(task.SelectedPlatform).reset;
        end
    end
    methods (Access = private, Hidden)
        % Get the translatable tab title from the computer("arch")
        function name = getPlatformName(~,arch)
             name = getString(message(['MATLAB:CPPUI:' arch]));
        end
        % Listener handler for any platform change
        function notifyPlatformChange(task,~, ~)
            % Notify live task to generate code
            notify(task, "StateChanged");
        end
        % Instantiates new PlatformView
        function platformAdd(task,platformName,fileChooser)
            % Create new arch platform tab
            newPlatformTab = uitab(task.TabGroup,'Title',task.getPlatformName(platformName), ...
                'Tooltip', getString(message('MATLAB:CPPUI:ExistingPlatformTabTooltip',task.getPlatformName(platformName))),...
                'Tag',platformName);
            if nargin == 2
                fileChooser = clibgen.task.internal.DefaultFileChooser;
            end
            if numel(task.Platform) == 0
                task.Platform = clibgen.task.internal.PlatformView(newPlatformTab,fileChooser);
            else
               task.Platform(end+1) = clibgen.task.internal.PlatformView(newPlatformTab,fileChooser);
            end
            % Add platform change listener for PlatformView
            task.TaskStateChangedListener = event.listener(task.Platform(end), ...
                'PlatformChanged',@(e,d) task.notifyPlatformChange(e,d));
        end
        % Tab selection is changed
        function tabSelectionChanged(task, ~, selectedTab)
            % Set the selected platform
            for idx=1:length(task.TabGroup.Children)
                if isequal(selectedTab,task.TabGroup.Children(idx))
                    task.SelectedPlatform = idx;
                    if ~strcmp(selectedTab.Tag,computer("arch"))
                        platform = task.Platform(idx);
                        platform.disablePlatformWidgets;
                    end
                    return;
                end
            end
        end
        % Sets defaults for widgets in new platform
        function initializePortableData(task)
            % Two or more platforms required
            if length(task.Platform) == 1
                return
            end
            % Obtain data from task.Platform(1) to initialize task.Platform(end)
            % Only platform agnostic data is copied from the first
            % platform
            sourcePlatform = task.Platform(1);
            sourceDataToPort = sourcePlatform.getPortableData;
            targetPlatform = task.Platform(end);
            targetPlatform.setPortableData(sourceDataToPort);
        end
        % Confirmation dialog to create new platform
        function alertNewPlatform(task)
            % Alert user live task created on another platform
            if task.NewPlatformAlert
                taskFigure = uifigure(WindowStyle="alwaysontop",Visible="off",Units="normalized");
                width = .25;
                height = .2;
                xLeft = 0.5 - width/2;
                yBottom = 0.5 - height/2;
                taskFigure.Position = [xLeft,yBottom,width,height];
                taskFigure.Visible = "on";
                selection = uiconfirm(taskFigure, ...
                    getString(message('MATLAB:CPPUI:PlatformAlreadyExistsActionMsg')),...
                    getString(message('MATLAB:CPPUI:PlatformAlreadyExistsWarnTitle')),...
                    'Options',{getString(message('MATLAB:CPPUI:PlatformConfirmBtnNewPlatform')),getString(message('MATLAB:CPPUI:ConfirmBtnCancel'))},...
                    'DefaultOption',2,'CancelOption',2,...
                    'Icon','warning','CloseFcn', @(h,e) close(taskFigure));
                if strcmp(selection,getString(message('MATLAB:CPPUI:ConfirmBtnCancel')))
                    return;
                end
                initializePlatformTab(task);
            end
        end
        % Add new platform and intialize portable data
        function initializePlatformTab(task, varargin)
            % Add new platform
            task.NewPlatformAlert = false;
            task.platformAdd(computer("arch"), varargin{:});
            task.initializePortableData;
            task.TabGroup.SelectedTab = task.TabGroup.Children(end);
            task.SelectedPlatform = length(task.TabGroup.Children);
        end
        % Returns true if tab exists along with tab index
        function [tabExists,tabIndex] = isTabExist(task, tabTag)
            tabExists = false;
            tabIndex = [];
            for tabIdx = 1:numel(task.TabGroup.Children)
                if strcmp(task.TabGroup.Children(tabIdx).Tag,tabTag)
                    tabExists = true;
                    tabIndex = tabIdx;
                    return
                end
            end
            return
        end
    end
    methods (Access = public, Hidden)
        % For test cases
        function setupWithMockers(task, mockers)
            task.initializePlatformTab(mockers);
        end
    end
end

% LocalWords:  mlx
