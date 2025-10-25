classdef (Sealed) VectorSelector < matlab.ui.componentcontainer.ComponentContainer
    % VectorSelector: Select a numeric vector from a WorkspaceDropDown or
    % type in a vector in an EditField. EditField is validated using
    % STR2NUM with restricted valuation.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access = public)
        % UI Components
        Grid        matlab.ui.container.GridLayout
        DropDown    matlab.ui.control.DropDown
        EditField   matlab.ui.control.EditField
        WSDD        matlab.ui.control.internal.model.WorkspaceDropDown

        % Some vector inputs must match the length of another input.
        % In this case, set TargetSize to appropriate length and
        % RestrictSize to true
        RestrictSize logical = false;

        % Set IsVectorOfIndices to true if vector inputs must be a subset
        % of the vector 1:TargetSize. When IsVectorOfIndices is set to
        % true, the dropdowns are hidden and the only option is typing in
        % the editfield
        IsVectorOfIndices logical = false;

        % Note, setting both RestrictSize and IsVectorOfIndices to true is
        % not supported

        % If RestrictSize, input vector validation restricts input vector
        % length to TargetSize.
        % If IsVectorOfIndices, all elements of the input vector must be
        % members of 1:TargetSize.
        TargetSize double = [];

        % The numeric vector that the Value represents can be accessed
        % using NumValue. This property is updated when the Value is set
        % programmatically or when the object is interactively updated.
        NumValue double = [];
    end

    properties (Dependent)
        % Allow setting Enable and Tooltip on the uicomponents
        % (Visible comes free with ComponentContainer)
        Enable
        Tooltip
        % The char row vector used for script generation
        Value
        % For serialization
        State
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(obj)
            % Required by ComponentContainer
            % Called at construction

            % Usually this will be put in a GridLayout. For testing, set a
            % reasonable initial position within a UIFigure.
            obj.Position = [100 100 500 24];

            obj.Grid = uigridlayout(obj,...
                RowHeight = 22, ...
                ColumnWidth = ["fit" "1x"],...
                Padding = 0);
            obj.DropDown = uidropdown(obj.Grid,...
                Items = [string(message("MATLAB:dataui:VectorEditField")) ...
                string(message("MATLAB:dataui:VectorWorkspace"))],...
                ItemsData = ["ef" "wsdd"],...
                ValueChangedFcn = @obj.DDChanged);
            obj.EditField = uieditfield(obj.Grid,...
                ValueChangedFcn = @obj.editFieldChanged,...
                HorizontalAlignment = "right"); % Right align matches numeric editfield design
            obj.WSDD = matlab.ui.control.internal.model.WorkspaceDropDown(...
                Parent = obj.Grid,...
                ValueChangedFcn = @obj.WSDDChanged);
            obj.WSDD.FilterVariablesFcn = @obj.isValidVector;
            obj.WSDD.Layout.Row = 1;
            obj.WSDD.Layout.Column = 2;
        end

        function update(obj)
            % Required by ComponentContainer
            % Called when any property is changed

            if obj.IsVectorOfIndices
                % Hide the dropdowns, only show the ef
                obj.EditField.Visible = true;
                obj.WSDD.Visible = false;
                obj.DropDown.Visible = false;
                obj.DropDown.Value = "ef";
                obj.Grid.ColumnWidth{1} = 0;
            else
                % Toggle whether the EF or the WSDD is showing
                showEF = isequal(obj.DropDown.Value,"ef");
                obj.EditField.Visible = showEF;
                obj.WSDD.Visible = ~showEF;
            end
        end
    end

    methods (Access = private)
        function updateAndThrowValueChanged(obj,~,~)
            update(obj);
            notify(obj,"ValueChanged");
        end

        function DDChanged(obj,src,~)
            if isequal(src.Value,"ef")
                obj.NumValue = str2num(obj.EditField.Value); %#ok<ST2NM>
            elseif isempty(obj.WSDD.WorkspaceValue)
                % WSDD is 'select' or WS variable no longer exists
                obj.NumValue = [];
                obj.WSDD.Value = "select variable";
            else
                obj.NumValue = obj.WSDD.WorkspaceValue;
            end
            updateAndThrowValueChanged(obj);
        end

        function WSDDChanged(obj,src,~)
            obj.NumValue = src.WorkspaceValue;
            updateAndThrowValueChanged(obj);
        end

        function editFieldChanged(obj,src,ev)
            % Callback for EditField: Validate new EditField values. Revert
            % to previous value if it is not valid.
            val = src.Value;
            if isempty(val)
                % User clearing out the editfield is allowed, but no
                % further validation needed
                src.Value = '';
                obj.NumValue = [];
                updateAndThrowValueChanged(obj);
                return
            end
            % Verify the user typed in a vector
            val = str2num(src.Value,Evaluation = "restricted"); %#ok<ST2NM>
            if isempty(val) || ~isValidVector(obj,val)
                % str2num was unsuccessful or val is not a valid vector.
                % Revert to previous value. No need to throw ValueChanged.
                src.Value = ev.PreviousValue;
                return
            end
            try
                % str2num has already verified that the string only
                % consists of basic math expressions, so this is safe. We
                % just need to check it will be a valid expression to use
                % in the generated code. Eval scope is restricted to this
                % method.
                v = eval(src.Value); %#ok<NASGU>
                % If this works, leave the editfield alone. We don't want
                % to change something like "1:10" since it is already a
                % compact way to write the vector
            catch
                % The expression only works because str2num fixed
                % something, like adding brackets to make a list of numbers
                % into a vector. Update EditField to show something
                % evaluate-able
                src.Value = mat2str(val);
            end
            obj.NumValue = val;
            updateAndThrowValueChanged(obj);
        end

        function tf = isValidVector(obj,val)
            % Whether coming from WSDD or EditField, input must be a
            % numeric vector with no missing values
            tf = isnumeric(val) && isvector(val) && ~anymissing(val) && allfinite(val);
            if tf && obj.IsVectorOfIndices
                maxval = obj.TargetSize;
                % All elements of vector must be in 1:N with no repeats
                tf = max(val) <= maxval && min(val) >= 1 && all(fix(val) == val) && ...
                    allunique(val);
            elseif tf && obj.RestrictSize
                % Vector must be specified length
                tf = numel(val) == obj.TargetSize;
            end
        end
    end

    methods
        function val = get.Value(obj)
            % Value is the char to be used in script generation, not to be
            % confused with the numeric value of the selected vector
            if isequal(obj.DropDown.Value,"ef")
                val = obj.EditField.Value;
            elseif isequal(obj.WSDD.Value,"select variable")
                val = '';
            else
                val = obj.WSDD.Value;
            end
        end

        function set.Value(obj,val)
            % Set the Value of the component by setting the EditField
            % Value. This vector is not validated.
            obj.EditField.Value = val;
            % Also need to update the stored numeric value of the vector
            obj.NumValue = str2num(val,Evaluation = "restricted"); %#ok<ST2NM>
            % To make sure the Value comes from the editfield, set the
            % DropDown value appropriately
            obj.DropDown.Value = "ef";
            % In usage, it also makes sense to reset the WSDD to default
            obj.WSDD.Value = "select variable";
        end

        function val = get.Enable(obj)
            val = obj.EditField.Enable;
        end

        function set.Enable(obj,val)
            obj.EditField.Enable = val;
            obj.DropDown.Enable = val;
            obj.WSDD.Enable = val;
        end

        function val = get.Tooltip(obj)
            val = obj.EditField.Parent.Tooltip;
        end

        function set.Tooltip(obj,val)
            obj.EditField.Parent.Tooltip = val;
        end

        function s = get.State(obj)
            % Store only as much info as we need to restore the component
            % in the save/load workflow. Non-default values do not need to
            % be stored.
            s = struct();
            if ~isequal(obj.DropDown.Value,"ef")
                s.DropDownValue = obj.DropDown.Value;
            end
            if ~isempty(obj.EditField.Value)
                s.EditFieldValue = obj.EditField.Value;
            end
            if ~isequal(obj.WSDD.Value,"select variable")
                s.WSDDValue = obj.WSDD.Value;
            end
            if ~isempty(obj.TargetSize)
                s.TargetSize = obj.TargetSize;
            end
            if ~isempty(obj.NumValue)
                s.NumValue = obj.NumValue;
            end
        end

        function set.State(obj,s)
            % If not stored in State struct, restore default values
            if isfield(s,"DropDownValue")
                obj.DropDown.Value = s.DropDownValue;
            else
                obj.DropDown.Value = "ef";
            end
            if isfield(s,"EditFieldValue")
                obj.EditField.Value = s.EditFieldValue;
            else
                obj.EditField.Value = '';
            end
            if isfield(s,"WSDDValue")
                obj.WSDD.populateVariables();
                val = s.WSDDValue;
                if ~ismember(val,obj.WSDD.ItemsData)
                    % Saved variable is not in the workspace, but by live
                    % task guideline we need to reset this value anyway.
                    % To avoid error on setting the Value, add it to the
                    % items list.
                    obj.WSDD.ItemsData = [obj.WSDD.ItemsData {val}];
                    obj.WSDD.Items = [obj.WSDD.Items {val}];
                end
                obj.WSDD.Value = val;
            else
                obj.WSDD.Value = "select variable";
            end
            if isfield(s,"TargetSize")
                obj.TargetSize = s.TargetSize;
            else
                obj.TargetSize = [];
            end
            if isfield(s,"NumValue")
                obj.NumValue = s.NumValue;
            else
                obj.NumValue = [];
            end
        end
    end
end