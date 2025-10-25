classdef ROSToolboxPreferences < handle & ros.internal.mixin.InternalAccess
    %  MATLAB UI for ROS Toolbox preference panel

    %  Copyright 2022-2023 The MathWorks, Inc.
    properties
        % Panel Components
        UIFigure
        ROSEnvironment
        RMWEnvironment
    end

    properties (Access = ?ros.internal.mixin.InternalAccess)
        ParentGrid
        PythonLocationTitle
        ROSPythonDescription
        PythonInstallationDescription
        ROSPythonExecutableEdit
        ROSPythonExecutableBrowser
        ROSRecreateEnvironment
        DocHyperlink
        IsEditValueChanging
        RMWImplementationTitle
        RMWImplementationDropDown
        IsdropDownSelectionValueChanging
        RMWConfigurationEventListener
    end

    % Properties that will be removed when switching to JAVA desktop
    properties (Access = ?ros.internal.mixin.InternalAccess)
        OKButton
        HelpButton
    end

    methods (Access = public)
        function this = ROSToolboxPreferences(helperObj)
            % Create MATLAB Online helper object if no passed in
            if nargin == 0
                helperObj = ros.internal.utilities.MATLABOnlineHelper;
            end
            % Create a handle to RMWEnvironment object
            this.RMWEnvironment = ros.internal.ros2.RMWEnvironment();

            % Create window that houses UI canvas 
            title = i_getMessage("ros:utilities:preferences:ROSToolboxPreferences");
            this.UIFigure = uifigure("Name",title,Resize="off");
            this.UIFigure.Name = getString(message("ros:utilities:preferences:ROSToolboxPreferences"));
            this.UIFigure.Visible = matlab.lang.OnOffSwitchState.off;

            if ~helperObj.isMATLABOnline
                % Create a handle to ROSEnvironment object
                this.ROSEnvironment = ros.internal.ROSEnvironment();
                % Parent grid layout
                rowHeight = {20, 38, 15, 15, 22, 22, 30, 22, 22, 60, 22};
                this.ParentGrid = uigridlayout(this.UIFigure,[11 4]);
                panelGrid = this.ParentGrid;
                panelGrid.RowHeight = rowHeight;
            else
                this.ParentGrid = uigridlayout(this.UIFigure,[2 1]);
                panelGrid = this.ParentGrid;
                panelGrid.RowHeight = {30, 22};
            end
            
            panelGrid.ColumnWidth = {'fit',80,80};
            this.IsEditValueChanging = false;

            % ROS Preferences
            if ~helperObj.isMATLABOnline
                title = i_getMessage("ros:utilities:preferences:PythonLocationTitle");
                this.PythonLocationTitle = uilabel(panelGrid,"Text", title, "FontWeight", "bold");
                this.PythonLocationTitle.Layout.Row = 1;

                str = sprintf(i_getMessage("ros:utilities:preferences:ROSPythonDescription"));
                this.ROSPythonDescription = uilabel(panelGrid,"Text",str,"WordWrap","on");
                this.ROSPythonDescription.Layout.Row = 2;
                this.ROSPythonDescription.Layout.Column = 1;

                str = sprintf(i_getMessage("ros:utilities:preferences:PythonInstallationDescription"));
                this.PythonInstallationDescription = uilabel(panelGrid,"Text",str,"WordWrap","on");
                this.PythonInstallationDescription.Layout.Row = 3;
                this.PythonInstallationDescription.Layout.Column = 1;

                fcn = @(o,e) helpview('ros','ros-system-requirements');
                str = i_getMessage("ros:utilities:preferences:ROSSystemRequirements");
                this.DocHyperlink = uihyperlink(panelGrid,Text=str,HyperlinkClickedFcn=fcn);
                this.DocHyperlink.Layout.Row = 4;
                this.DocHyperlink.Layout.Column = 1;

                % Edit box for Python executable
                this.ROSPythonExecutableEdit = uieditfield(panelGrid,...
                    'ValueChangedFcn',@(dlg,eventData)this.pythonEditValueChangedFcn(dlg,eventData));
                this.ROSPythonExecutableEdit.Layout.Row = 5;
                this.ROSPythonExecutableEdit.Layout.Column = 1;
                this.ROSPythonExecutableEdit.Enable = 'on';
                % This callback cannot be interrupted. Edit box value
                % validation must be completed before other callbacks execute
                %this.ROSPythonExecutableEdit.Interruptible = "off";

                % File browser for Python executable
                str = i_getMessage("ros:utilities:preferences:Browse");
                this.ROSPythonExecutableBrowser = uibutton(panelGrid,Text=str,...
                    ButtonPushedFcn=@(o,e) this.pythonBrowserFcn());
                this.ROSPythonExecutableBrowser.Layout.Row = 5;
                this.ROSPythonExecutableBrowser.Layout.Column = 2;
                this.ROSPythonExecutableBrowser.Enable = 'on';

                % Recreate Python environment button
                str = i_getMessage("ros:utilities:preferences:RecreatePythonEnvironment");
                this.ROSRecreateEnvironment = uibutton(panelGrid,Text=str,...
                    ButtonPushedFcn=@(dlg,eventData) this.recreateRosEnvFcn());
                this.ROSRecreateEnvironment.Layout.Row = 6;
                this.ROSRecreateEnvironment.Layout.Column = 1;
                this.ROSRecreateEnvironment.WordWrap = "on";
                this.ROSRecreateEnvironment.Enable = 'on';
            end

            % RMW Implementation Title
            rmwImplementationTitle = i_getMessage("ros:utilities:preferences:RMWImplementationTitle");
            this.RMWImplementationTitle = uilabel(panelGrid,"Text", rmwImplementationTitle, "FontWeight", "bold","WordWrap","on");
            this.RMWImplementationDropDown = uidropdown(panelGrid,...
                'DropDownOpeningFcn',@(dlg,eventData) this.refreshRMWImplementationsInDropDown(dlg,eventData), ...
                'ValueChangedFcn',@(dlg,eventData) this.configureRMWImplementation(dlg,eventData));
            
            this.initDropDownItems();
            this.initCurrentRMWImplementation();
            
            if ~helperObj.isMATLABOnline
                this.RMWImplementationTitle.Layout.Row = 7;
                this.RMWImplementationDropDown.Layout.Row = 8;
                % Add OK & Cancel buttons. This needs to be removed for
                % JavaScript desktop
                if ~helperObj.isJSD % Hide additional (OK | Help) buttons
                    addStandalonUIButtons(this, panelGrid);
                end
            else
                this.RMWImplementationTitle.Layout.Row = 1;
                this.RMWImplementationDropDown.Layout.Row = 2;
            end

            this.RMWImplementationTitle.Layout.Column = 1;
            this.RMWImplementationDropDown.Layout.Column = 1;

            % Get the settings and assign the values
            setCurrentUIValues(this, helperObj);
            this.UIFigure.Position = this.UIFigure.Position + [0 0 200 0];
            this.UIFigure.Visible = matlab.lang.OnOffSwitchState.on;
        end

        function pythonBrowserFcn(this)
            if ispc
                filterSpec = {'*.exe','Python executable'};
            else
                filterSpec = {'*.*','Python executable'};
            end
            str = i_getMessage("ros:utilities:preferences:BrowsePythonExecutable");
            [filename, pathname] = uigetfile(filterSpec,str);
            % App loses focus when user cancels out of uigetfile. Set focus back to app
            focus(this.UIFigure); 
            if ~isequal(filename,0) % When user hits cancel filename == 0
                pythonExecutable = fullfile(pathname,filename);
                try
                    % Set Python executable value from edit box
                    this.ROSEnvironment.PythonExecutable = pythonExecutable;
                    this.ROSPythonExecutableEdit.Value = pythonExecutable;
                catch EX
                    uialert(this.UIFigure,EX.message,...
                        getString(message("ros:utilities:preferences:Error")));
                end
            end
        end

        function pythonEditValueChangedFcn(this,dlg,eventData)
            if ~isvalid(this)
                % UIFigure has been deleted. This happens sporadically g2736569
                return;
            end
            this.IsEditValueChanging = true;
            try
                % Set Python executable value from edit box
                assert(~isempty(strtrim(eventData.Value)),...
                    message("ros:utilities:preferences:EmptyPythonExecutable"))
                this.ROSEnvironment.PythonExecutable = eventData.Value; 
                this.IsEditValueChanging = false;
            catch EX                
                uialert(this.UIFigure,EX.message,...
                   getString(message("ros:utilities:preferences:Error")),...
                   "CloseFcn",@(~,~)this.pythonEditValueCloseFcn(dlg,eventData));
            end  
        end

        function pythonEditValueCloseFcn(this,dlg,eventData)
            this.IsEditValueChanging = false;
            dlg.set('Value',eventData.PreviousValue);
        end

        function configureNewRMW(this,dlg,eventData)
            rmwConfigScreenObj = ros2configrmw;
            % When cancel/Finish button is clicked in RMW Configuration GUI,
            % entire workflow handle is deleted, whereas if X button is
            % clicked, window handle gets deleted.
            if isa(rmwConfigScreenObj, 'matlab.ui.Figure')
                this.RMWConfigurationEventListener = addlistener(rmwConfigScreenObj, 'ObjectBeingDestroyed', @(~,~) this.rmwConfigurationUICloseFcn(dlg, eventData));
            else
                this.RMWConfigurationEventListener = addlistener(rmwConfigScreenObj.Window, 'ObjectBeingDestroyed', @(~,~) this.rmwConfigurationUICloseFcn(dlg, eventData));
            end
        end

        function rmwConfigurationUICloseFcn(this, ~, ~)
            %RMWConfigurationUICloseFcn - window delete callback that allows the
            %Workflow to be aware of when the user has closed the Window
            %Peer so that the Workflow can be cleaned up. If ROS middleware
            %configuration GUI is closed before configuring any middleware,
            %the dropdown selection in preferences panel will fallback to
            %previously configured RMW implementation.

            this.OKButton.Enable = 'on';
            this.refreshRMWImplementationsInDropDown();
            if ~(ros.internal.utilities.MATLABOnlineHelper.isMATLABOnline || ...
                    ros.internal.utilities.MATLABOnlineHelper.isJSD)
                uiFigHandleObj = findobjinternal(0,'Type','Figure','Name',...
                    getString(message("ros:utilities:preferences:ROSToolboxPreferences")));
                if ~isempty(uiFigHandleObj)
                    focus(uiFigHandleObj);
                end
            end
        end

        function refreshRMWImplementationsInDropDown(this,dlg,eventData) %#ok<INUSD> 
            initDropDownItems(this);
            initCurrentRMWImplementation(this);
        end

        function initDropDownItems(this)
            rmwList = {'rmw_fastrtps_cpp', ...
                'rmw_fastrtps_dynamic_cpp','rmw_cyclonedds_cpp'};
            customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance();
            customRMWList = customRMWRegistry.getRMWList();
            for ii=1:numel(customRMWList)
                rmwList{end+1} = customRMWList{ii}; %#ok<AGROW>
            end
            % RTI Connext DDS Professional and Eclipse iceoryx are not
            % supported on Apple Silicon natively
            rmwList{end+1} = message('ros:utilities:preferences:ConfigureNewRMW').getString;
            this.RMWImplementationDropDown.Items = unique(rmwList,'stable');
        end

        function initCurrentRMWImplementation(this)
            % Set the current drop down default value to current RMW
            % implementation
            this.RMWImplementationDropDown.Value = ros.internal.utilities.getCurrentRMWImplementation();
        end

        function recreateRosEnvFcn(this)
            % Terminate early if edit box value containing Python
            % executable path is being changed. This means user entered a
            % value in the edit box and immediately clicked on the push
            % button. User needs to push the button again
            if this.IsEditValueChanging
                return;
            end
            try
                createPythonEnvironment(this,true);
            catch EX
                uialert(this.UIFigure,removeHyperlinks(EX.message),...
                    getString(message("ros:utilities:preferences:Error")));
            end
        end

        function setCurrentUIValues(this, helperObj)
            if ~helperObj.isMATLABOnline && helperObj.isJSD
                % Here the assumption is that ROS1PythonExacutable and
                % ROS2PythonExecutable are the same
                if ~isempty(this.ROSEnvironment.ROS1PythonExecutable)
                    pythonExecutable = this.ROSEnvironment.ROS1PythonExecutable;
                else
                    pythonExecutable = this.ROSEnvironment.ROS2PythonExecutable;
                end
                this.ROSPythonExecutableEdit.Value = pythonExecutable;
            end
            this.RMWImplementationDropDown.Value = ros.internal.utilities.getCurrentRMWImplementation();
        end

        function createPythonEnvironment(this,recreateEnvironment)
            if nargin < 2
                recreateEnvironment = false;
            end

            % Set the value of Python executable from edit box
            try
                this.ROSEnvironment.PythonExecutable = this.ROSPythonExecutableEdit.Value;
            catch
                % Invalid entry in the edit box. Return to cancel push
                % button or OK button callback
                return;
            end

            % Create a progress dialog
            progressdlg = uiprogressdlg(this.UIFigure,Indeterminate="on",...
                Message=i_getMessage("ros:utilities:preferences:CreatingVenv"));
            % Create ROS1 and ROS2 environment
            this.ROSEnvironment.checkAndCreateVenv('ros1',recreateEnvironment);
            this.ROSEnvironment.checkAndCreateVenv('ros2',recreateEnvironment);
            delete(progressdlg);
        end

        function configureRMWImplementation(this,dlg,eventData)
            % Set the value of RMW implementation from drop down
            try
                if strcmp(this.RMWImplementationDropDown.Value, message('ros:utilities:preferences:ConfigureNewRMW').getString)
                    configureNewRMW(this,dlg,eventData);
                    % Disable OK button while configuring other RMW
                    this.OKButton.Enable = 'off';
                else
                    % Enable OK button while selecting a registered RMW
                    % with MATLAB.
                    this.OKButton.Enable = 'on';
                end
            catch
                % Invalid entry in the dropdown. Return to cancel push
                % button or OK button callback
                return;
            end
        end

        function setRMWImplementation(this,~,~)
            % Set the value of RMW implementation from drop down when OK
            % button is clicked
            try
                this.RMWEnvironment.RMWImplementation = this.RMWImplementationDropDown.Value;
            catch
                % Invalid entry in the dropdown. Return to cancel push
                % button or OK button callback
                return;
            end
        end

        function result = commit(this)
            if this.IsEditValueChanging
                %g2736569: Drop commit callback when user has changed the
                %Python executable edit box and immediately clicked on OK
                result = true;
                return;
            end
            % Apply commit actions to save user settings
            try
                setRMWImplementation(this);
                if ~ros.internal.utilities.MATLABOnlineHelper.isMATLABOnline
                    this.ROSEnvironment.PythonExecutable = this.ROSPythonExecutableEdit.Value;
                    pythonExe = this.ROSEnvironment.getDefaultPythonExecutable('ros1');
                    if ~isempty(pythonExe)
                        createPythonEnvironment(this);
                    end
                    if ~ros.internal.utilities.MATLABOnlineHelper.isJSD
                        delete(this);
                    end
                end
                result = true;
            catch EX
                uialert(this.UIFigure,removeHyperlinks(EX.message),...
                    getString(message("ros:utilities:preferences:Error")));
                result = false;
            end
        end

        function delete(this)
            if ~isempty(this.RMWConfigurationEventListener)
               delete(this.RMWConfigurationEventListener);
            end
            delete(this.UIFigure);
        end
    end

    methods (Access = private)
        function addStandalonUIButtons(this, panelGrid)
            % Add UI buttons OK, Cancel and Help that are needed for
            % stand-alone operation
            this.OKButton = uibutton(panelGrid,...
                Text=getString(message("MATLAB:uistring:popupdialogs:OK")),...
                Tag="OKButton",...
                ButtonPushedFcn=@(o,e) this.commit());
            this.OKButton.Layout.Row = 11;
            this.OKButton.Layout.Column = 2;

            this.HelpButton = uibutton(panelGrid,...
                Text=getString(message("MATLAB:uistring:cameratoolbar:Help")),...
                Tag="HelpButton",...
                ButtonPushedFcn=@(o,e) ...
                helpview('ros','ros-system-requirements'));
            this.HelpButton.Layout.Row = 11;
            this.HelpButton.Layout.Column = 3;
        end
    end
end

% Utility function for deriving UI strings from message catalog
function s = i_getMessage(id, varargin)
s = getString(message(id,varargin{:}));
end

function s = removeHyperlinks(s)
% Remove hyperlinks in text. Useful for displaying error messages
% containing hyperlinks in uialert dialog
s = regexprep(strrep(s,'</a>',''),'<a href[^>]*>',''); 
end

