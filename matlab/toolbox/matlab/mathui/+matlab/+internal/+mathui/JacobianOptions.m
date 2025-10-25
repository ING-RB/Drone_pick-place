classdef (Sealed) JacobianOptions < matlab.ui.componentcontainer.ComponentContainer
    % JacobianOptions: A set controls for selecting the options in the
    % odeJacobian class. For use in SolveODETask.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access=public,Dependent)
        State
        Enable
    end

    properties (Hidden,Transient)
        % Main controls in this component
        Grid                matlab.ui.container.GridLayout
        TypeDD              matlab.ui.control.DropDown
        FcnSelector         matlab.internal.dataui.FunctionSelector
        WSDD                matlab.ui.control.internal.model.WorkspaceDropDown
        SparsityDD          matlab.ui.control.internal.model.WorkspaceDropDown
        % Number of equations associated with the ODE function
        ExpectedSize        double = [];
    end

    properties (Hidden,Constant)
        DefaultFcnSelectorState = struct("FcnType",'local',...
            "LocalValue",'select variable',...
            "HandleValue",'@(t,y) [0 1; 0 -t]',...
            "BrowseValue",'');
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Method needed by the ComponentContainer constructor

            % Usually this will be put in a GridLayout. For testing, set a
            % reasonable initial position within a UIFigure.
            obj.Position = [50 50 450 24];
            % Lay out the contents of the control
            obj.Grid = uigridlayout(obj,RowHeight = "fit",...
                ColumnWidth = {120 "fit" "1x"}, Padding = 0);
            obj.TypeDD = uidropdown(obj.Grid,...
                Items = [getMsgText("Function") getMsgText("Matrix") getMsgText("Sparsity")],...
                ItemsData = ["function" "matrix" "sparsity"],...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tooltip = getMsgText("TypeTooltip"));
            obj.FcnSelector = matlab.internal.dataui.FunctionSelector(...
                Parent = obj.Grid,...
                AllowEmpty = true,...
                IncludeBrowse = true,...
                ValueChangedFcn = @obj.notifyValueChanged,...
                AutoArrangeGrid = false,...
                Tooltip = getMsgText("FunctionTooltip"));
            obj.FcnSelector.Layout.Column = [2 3];
            obj.FcnSelector.GridLayout.ColumnWidth{2} = "1x";
            obj.WSDD = matlab.ui.control.internal.model.WorkspaceDropDown(...
                Parent = obj.Grid,...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tooltip = getMsgText("MatrixTooltip"),...
                ShowNonExistentVariable = true);
            obj.WSDD.FilterVariablesFcn = @obj.filterFcn;
            obj.WSDD.Layout.Row = 1;
            obj.WSDD.Layout.Column = 2;
            obj.SparsityDD = matlab.ui.control.internal.model.WorkspaceDropDown(...
                Parent = obj.Grid,...
                ValueChangedFcn = @obj.notifyValueChanged,...
                Tooltip = getMsgText("SparsityTooltip"),...
                ShowNonExistentVariable = true);
            obj.SparsityDD.FilterVariablesFcn = @obj.filterFcn;
            obj.SparsityDD.Layout.Row = 1;
            obj.SparsityDD.Layout.Column = 2;
        end

        function update(obj)
            % Method required by ComponentContainer
            % Called when properties of the component are updated
            type = obj.TypeDD.Value;
            obj.FcnSelector.Visible = isequal(type,"function");
            obj.WSDD.Visible = isequal(type,"matrix");
            obj.SparsityDD.Visible = isequal(type,"sparsity");
            % Parent/unparent controls based on visibility
            matlab.internal.dataui.setParentForWidgets(...
                [obj.FcnSelector obj.WSDD obj.SparsityDD],obj.Grid)
        end
    end

    methods (Access=private)
        function notifyValueChanged(obj,~,~)
            % callback for components within the popout
            notify(obj,'ValueChanged');
            update(obj);
        end

        function tf = filterFcn(obj,m)
            % FilterFcn for Jacobian matrix and Jacobian sparsity
            % Square numeric matrix compatibly sized to y0
            s = obj.ExpectedSize;
            tf = isfloat(m) && isequal(size(m),[s s]);
        end
    end

    methods % public gets and sets
        function reset(obj)
            % restores default values
            obj.TypeDD.Value = "function";
            obj.FcnSelector.resetToDefault();
            obj.WSDD.Value = "select variable";
            obj.SparsityDD.Value = "select variable";
        end

        function s = get.State(obj)
            % Store only as much info as we need to restore the component
            % in the save/load workflow. Non-default values do not need to
            % be stored.
            s = struct();
            if ~isequal(obj.FcnSelector.State,obj.DefaultFcnSelectorState)
                s.FcnSelectorState = obj.FcnSelector.State;
            end
            if ~isequal(obj.ExpectedSize,1)
                s.ExpectedSize = obj.ExpectedSize;
            end
            if ~isequal(obj.TypeDD.Value,"function")
                s.TypeDDValue = obj.TypeDD.Value;
            end
            if ~isequal(obj.WSDD.Value,"select variable")
                s.WSDDValue = obj.WSDD.Value;
            end
            if ~isequal(obj.SparsityDD.Value,"select variable")
                s.SparsityDDValue = obj.SparsityDD.Value;
            end
        end

        function set.State(obj,s)
            if isfield(s,"FcnSelectorState")
                obj.FcnSelector.State = s.FcnSelectorState;
            else
                obj.FcnSelector.State = obj.DefaultFcnSelectorState;
            end
            if isfield(s,"ExpectedSize")
                obj.ExpectedSize = s.ExpectedSize;
            else
                obj.ExpectedSize = 1;
            end
            widgets = ["TypeDD" "WSDD" "SparsityDD"];
            defaultValues = ["function" "select variable" "select variable"];
            for k = 1:numel(widgets)
                if isfield(s,widgets(k)+"Value")
                    obj.(widgets(k)).Value = s.(widgets(k)+"Value");
                else
                    obj.(widgets(k)).Value = defaultValues(k);
                end
            end
            update(obj);
        end

        function str = getValue(obj,isInternal)
            % Return string to be used for code generation

            % isInternal = true indicates code is to be used internally by
            % the live task to determine auto-selected solver. In this case
            % we do not have access to local functions in the script where
            % the live task is embedded. So for any function inputs, we use
            % a dummy function with the expected syntax. Additionally, we
            % cannot rely on workspace variables remaining in the workspace

            switch obj.TypeDD.Value
                case "function"
                    str = obj.FcnSelector.Value;
                    if ~isempty(str) && isInternal
                        % Cannot rely on local functions
                        str = "@(t,y) y";
                    end
                case "matrix"
                    str = obj.WSDD.Value;
                    if isequal(str,"select variable")
                        % No input selected
                        str = '';
                    elseif isInternal
                        % Cannot rely on workspace values
                        str = "eye(" + obj.ExpectedSize + ")";
                    end
                case "sparsity"
                    % This case requires using the odeJacobian constructor
                    str = obj.SparsityDD.Value;
                    if isequal(str,"select variable")
                        % No input selected
                        str = '';
                    elseif isInternal
                        % Cannot rely on workspace values
                        str = "odeJacobian(SparsityPattern = eye(" + obj.ExpectedSize + "))";
                    else
                        str = "odeJacobian(SparsityPattern = " + str + ")";
                    end
            end
        end

        function onoff = get.Enable(obj)
            onoff = obj.TypeDD.Enable;
        end

        function set.Enable(obj,onoff)
            obj.TypeDD.Enable = onoff;
            obj.FcnSelector.Enable = onoff;
            obj.WSDD.Enable = onoff;
            obj.SparsityDD.Enable = onoff;
        end
    end
end

function str = getMsgText(id)
str = string(message("MATLAB:mathui:Jacobian" + id));
end