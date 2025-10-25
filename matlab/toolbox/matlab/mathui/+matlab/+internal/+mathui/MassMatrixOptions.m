classdef (Sealed) MassMatrixOptions < matlab.ui.componentcontainer.ComponentContainer
    % MassMatrixOptions: A set controls for selecting  most of the options
    % of the odeMassMatrix class. If statedependent, then Sparsity is not
    % included here (as it is displayed elsewhere in the task).
    % For use in SolveODETask.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access=public,Dependent)
        State
    end

    properties (Access=public)
        % MType corresponds to the buttons at the top of SolveODETask
        % 0 (no M), 1 (constant M), 2 (timedependent), 3 (statedependent)
        MType double = 0;
    end

    properties (Hidden,Transient)
        % Main controls in this component
        Grid                     matlab.ui.container.GridLayout
        FcnSelector              matlab.internal.dataui.FunctionSelector
        MatrixWSDD               matlab.ui.control.internal.model.WorkspaceDropDown
        Icon                     matlab.ui.control.Image
        Popout                   matlab.ui.container.internal.Popout
        % Controls inside the popout
        PopoutGrid               matlab.ui.container.GridLayout
        PopoutHeaderIcon         matlab.ui.control.Image
        SingularDropdown         matlab.ui.control.DropDown
        StateDependenceLabel     matlab.ui.control.Label
        StateDependenceDropdown  matlab.ui.control.DropDown
        % Helper
        IsSingular = false;
    end

    properties (Access=private,Constant)
        WSDDselect = "select variable";
        TextRowHeight = 22;
        PopoutWidth = 250;
        IconWidth = 16;
        DefaultFcnSelectorState = struct("FcnType",'local',...
            "LocalValue",'select variable',...
            "HandleValue",'@(t,y) [1 0; 0 1]',...
            "BrowseValue",'');
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Method needed by the ComponentContainer constructor
            % Lay out the contents of the control

            % Usually this will be put in a GridLayout. For testing, set a
            % reasonable initial position within a UIFigure.
            obj.Position = [50 50 500 obj.TextRowHeight];

            % Create Icon as the target and its corresponding popout
            % Popout target icon must be in a gridlayout
            obj.Grid = uigridlayout(obj,...
                RowHeight = obj.TextRowHeight,...
                ColumnWidth = {160 130 "fit" obj.TextRowHeight},...
                Padding = 0);
            obj.FcnSelector = matlab.internal.dataui.FunctionSelector(...
                Parent = obj.Grid,...
                AllowEmpty = true,...
                IncludeBrowse = true,...
                ValueChangedFcn = @obj.updateAndThrowValueChanged,...
                Tooltip = getMsgText("FcnTooltip"),...
                AutoArrangeGrid = false);
            obj.FcnSelector.Layout.Column = [1 3];
            obj.FcnSelector.GridLayout.ColumnWidth{1} = 160;
            obj.FcnSelector.GridLayout.ColumnWidth{2} = 130;
            obj.MatrixWSDD = matlab.ui.control.internal.model.WorkspaceDropDown(...
                Parent = obj.Grid, ...
                ValueChangedFcn = @obj.getSingularityAndUpdate,...
                Tooltip = getMsgText("WSDDTooltip"),...
                ShowNonExistentVariable = true);
            obj.MatrixWSDD.FilterVariablesFcn = @(m) isnumeric(m) && ismatrix(m) && size(m,1) == size(m,2);
            obj.MatrixWSDD.Layout.Column = 1;

            obj.Icon = uiimage(obj.Grid,...
                ScaleMethod = "none",...
                ImageClickedFcn = @donothing,...
                Tooltip = getMsgText("IconTooltip"));
            matlab.ui.control.internal.specifyIconID(obj.Icon,...
                "meatballMenuUI",obj.IconWidth,obj.IconWidth);
            obj.Popout = matlab.ui.container.internal.Popout(Trigger = "click");
            % Don't set the Target as the icon until after the icon is
            % visible in the figure

            % Layout controls within the popout
            obj.PopoutGrid = uigridlayout(Parent = [],...
                RowHeight = [obj.TextRowHeight obj.TextRowHeight obj.TextRowHeight],...
                ColumnWidth = {obj.IconWidth 100-obj.IconWidth obj.PopoutWidth-110},...
                Padding = 5,...
                ColumnSpacing = 5,...
                RowSpacing = 5);
            % Help button to link to odeMassMatrix doc page
            obj.PopoutHeaderIcon = uiimage(obj.PopoutGrid,...
                ImageClickedFcn = @(~,~)helpview("matlab","ODELET_MassMatrix"),...
                ScaleMethod = "fill", ...
                Tooltip = getMsgText("HelpTooltip"));
            matlab.ui.control.internal.specifyIconID(obj.PopoutHeaderIcon,...
                'helpMonoUI',obj.IconWidth,obj.IconWidth);
            % Title of the popout
            headerLabel = uilabel(obj.PopoutGrid,...
                Text = getMsgText("Title"),...
                FontWeight = "bold");
            headerLabel.Layout.Column = [2 3];
            % Singular dropdown with label
            singularLabel = uilabel(obj.PopoutGrid,...
                Text = getMsgText("Singular"));
            singularLabel.Layout.Column = [1 2];
            obj.SingularDropdown = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn = @obj.updateAndThrowValueChanged,...
                Items = [getMsgText("Yes") getMsgText("No") getMsgText("Maybe")],...
                ItemsData = ["yes" "no" "maybe"],...
                Tooltip = getMsgText("SingularTooltip"), ...
                Value = "maybe");
            % State dependence dropdown with label
            obj.StateDependenceLabel = uilabel(obj.PopoutGrid,...
                Text = getMsgText("StateDependence"));
            obj.StateDependenceLabel.Layout.Column = [1 2];
            obj.StateDependenceDropdown = uidropdown(obj.PopoutGrid,...
                ValueChangedFcn=@obj.updateAndThrowValueChanged,...
                Items = [getMsgText("Weak") getMsgText("Strong")],...
                ItemsData = ["weak" "strong"],...
                Tooltip = getMsgText("StateDependenceTooltip"),...
                Value = "weak");
            % Note that the "none" option from the odeMassMatrix object is
            % taken care of automatically with this design when MType = 2

            obj.PopoutGrid.Parent = obj.Popout;
        end

        function update(obj)
            % Method required by ComponentContainer
            % Called when properties of the component are updated

            % Prevent the popout from being parented to the uifigure at
            % initial construction (live task constructor complains)
            if ~obj.Visible
                obj.Popout.Target = [];
            else
                obj.Popout.Target = obj.Icon;
            end

            obj.FcnSelector.Visible = obj.MType > 1;
            obj.Icon.Visible = obj.MType > 1;
            obj.MatrixWSDD.Visible = obj.MType == 1;
            % State dependent dropdown is only visible when we know the
            % MassMatrix is StateDependent ('None' option is not available
            % in this control)
            isType3 = obj.MType == 3;
            obj.StateDependenceLabel.Visible = isType3;
            obj.StateDependenceDropdown.Visible = isType3;
            obj.PopoutGrid.RowHeight{3} = isType3*obj.TextRowHeight;
            % Adjust height of the popout accordingly
            numRows = 2 + isType3;
            obj.Popout.Position = [0 0 obj.PopoutWidth+10 ((numRows)*obj.TextRowHeight + (numRows-1)*10)];
        end
    end

    methods (Access=private)
        function updateAndThrowValueChanged(obj,~,~)
            % callback for components within the popout
            update(obj);
            notify(obj,'ValueChanged');
        end

        function getSingularityAndUpdate(obj,src,~)
            % WSDD callback. Only available when MType == 1
            if ~isequal(src.Value,obj.WSDDselect)
                % Store singularity so we can provide appropriate dummy
                % variable with matching singularity
                MM = odeMassMatrix(MassMatrix = src.WorkspaceValue);
                obj.IsSingular = strcmp(MM.Singular,"yes");
            else
                obj.IsSingular = false;
            end
            updateAndThrowValueChanged(obj);
        end
    end

    methods % public gets and sets
        function s = get.State(obj)
            % Store only as much info as we need to restore the component
            % in the save/load workflow. Non-default values do not need to
            % be stored.
            s = struct();
            if ~isequal(obj.FcnSelector.State,obj.DefaultFcnSelectorState)
                s.FcnSelectorState = obj.FcnSelector.State;
            end
            if ~isequal(obj.MatrixWSDD.Value,obj.WSDDselect)
                s.MatrixWSDDValue = obj.MatrixWSDD.Value;
            end
            if ~isequal(obj.SingularDropdown.Value,"maybe")
                s.SingularDropdownValue = obj.SingularDropdown.Value;
            end
            if ~isequal(obj.StateDependenceDropdown.Value,"weak")
                s.StateDependenceDropdownValue = obj.StateDependenceDropdown.Value;
            end
            if ~isequal(obj.MType,0)
                s.MType = obj.MType;
            end
            if obj.IsSingular
                s.IsSingular = true;
            end
        end

        function set.State(obj,s)
            if isfield(s,"FcnSelectorState")
                obj.FcnSelector.State = s.FcnSelectorState;
            else
                obj.FcnSelector.State = obj.DefaultFcnSelectorState;
            end
            if isfield(s,"MatrixWSDDValue")
                obj.MatrixWSDD.Value = s.MatrixWSDDValue;
            else
                obj.MatrixWSDD.Value = obj.WSDDselect;
            end
            if isfield(s,"SingularDropdownValue")
                obj.SingularDropdown.Value = s.SingularDropdownValue;
            else
                obj.SingularDropdown.Value = "maybe";
            end
            if isfield(s,"StateDependenceDropdownValue")
                obj.StateDependenceDropdown.Value = s.StateDependenceDropdownValue;
            else
                obj.StateDependenceDropdown.Value = "weak";
            end
            if isfield(s,"MType")
                obj.MType = s.MType;
            else
                obj.MType = 0;
            end
            obj.IsSingular = isfield(s,"IsSingular");
        end

        function val = getNVValue(obj)
            % Return string for the NV pairs of the odeMassMatrix call
            % (except for Sparsity)
            val = '';
            if obj.MType < 2
                return
            end
            if ~isequal(obj.SingularDropdown.Value,'maybe')
                val = ", Singular = """ + obj.SingularDropdown.Value + """";
            end
            if obj.MType == 3 && isequal(obj.StateDependenceDropdown.Value,'strong')
                val = val + ", StateDependence = ""strong""";
            elseif obj.MType == 2
                val = val + ", StateDependence = ""none""";
            end
        end

        function M = getMassValue(obj,isInternal,heightM)
            % Return string for the mass matrix, either the workspace
            % variable name, or the function handle.
            % This method is only called when isWaiting(obj) is false and
            % obj.MType > 0

            % isInternal = true indicates code is to be used internally by
            % the live task to determine auto-selected solver. In this case
            % we do not have access to local functions in the script where
            % the live task is embedded. So for any function inputs, we use
            % a dummy function with the expected syntax. Additionally, we
            % cannot rely on workspace variables remaining in the workspace

            if obj.MType == 1
                if isInternal
                    % Cannot rely on workspace values, but need dummy
                    % matrix to have appropriate Singular value.
                    if obj.IsSingular
                        M = "zeros(" + heightM + ")";
                    else
                        M = "speye(" + heightM + ")";
                    end
                else
                    M = obj.MatrixWSDD.Value;
                end
            else % MType > 1
                if isInternal
                    % Cannot rely on local functions
                    if obj.MType == 2
                        % time dependent
                        M = "@(t) speye(" + heightM + ")";
                    else
                        % state dependent
                        M = "@(t,y) speye(" + heightM + ")";
                    end
                else
                    M = obj.FcnSelector.Value;
                end
            end
        end

        function tf = isWaiting(obj)
            % Determine whether we need a MassMatrix based on type, and
            % whether we are waiting for user to seelect
            tf = (obj.MType == 1 && isequal(obj.MatrixWSDD.Value,obj.WSDDselect)) || ...
                (obj.MType > 1 && isempty(obj.FcnSelector.Value));
        end
    end
end

function str = getMsgText(id)
str = string(message("MATLAB:mathui:MassMatrixOptions" + id));
end

function donothing(~,~)
% Need this callback to make the pointer change on hovering over icon
end