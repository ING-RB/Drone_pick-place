classdef (ConstructOnLoad) LimitsContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "LimitsContainer":
    % Widget that is used to set the limits and limit sharing options.
    %
    % To use container in a dialog/panel:
    %
    %   c = controllib.widget.internal.cstprefs.LimitsContainer('NumberOfXLabels',2,'NumberOfYLabels',2);
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties
    %   Title       string or char array
    %   XLabel      string array or cell array
    %   YLabel      string array or cell array

    % Copyright 2020-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetObservable,AbortSet)
        NGroups
    end

    properties (SetAccess=immutable)
        NLimits
    end

    properties (Dependent,SetObservable,AbortSet)
        AutoScale
        Limits
        GroupLabelText
        GroupItems
        LimitsLabelText
        SelectedGroup
        SelectedGroupIdx
        Enable
    end

    properties (Access = private)
        NGroups_I
        GroupLabelText_I
        GroupItems_I
        LimitsLabelText_I
        SelectedGroup_I
        Enable_I

        AutoScaleCheckbox
        GroupLabel
        GroupDropdown
        LimitsEditField
        LimitsLabel

        UpdateWidget = true
        WidgetTags = struct(...
            'AutoScaleCheckbox','LimitsAutoScale',...
            'GroupDropdown','LimitsGroupDropdown',...
            'LimitsEditField','LimitsEditField');
    end

    properties (Hidden)
        AddTagToWidgets = false
        LimitsInternal
        AutoScaleInternal
    end

    %% Constructor
    methods
        function this = LimitsContainer(optionalInputs)
            arguments
                optionalInputs.NumberOfGroups (1,1) double {mustBeInteger,mustBePositive} = 1
                optionalInputs.NumberOfLimits (1,1) double {mustBeInteger,mustBePositive} = 1
            end
            this.NGroups_I = optionalInputs.NumberOfGroups;
            this.NLimits = optionalInputs.NumberOfLimits;

            this.GroupLabelText_I = 'Group';
            this.GroupItems_I = cellstr(string(1:this.NGroups));
            this.LimitsLabelText_I = repmat({''},1,this.NLimits);
            this.LimitsInternal = repmat({[0 1]},this.NGroups,this.NLimits);
            this.AutoScaleInternal = true(1,this.NGroups);
            this.SelectedGroup_I = this.GroupItems{1};
            this.Enable_I = true;

            this.ContainerTitle = m('Controllib:gui:strLimits');
        end
    end

    %% Get/Set
    methods
        % NGroups
        function NGroups = get.NGroups(this)
            NGroups = this.NGroups_I;
        end

        function set.NGroups(this,NGroups)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.LimitsContainer
                NGroups (1,1) double {mustBeInteger,mustBePositive}
            end
            this.GroupLabel.Visible = NGroups > 1;
            this.GroupDropdown.Visible = NGroups > 1;
            if NGroups > 1
                this.GroupLabel.Parent.RowHeight{2} = 'fit';
            else
                this.GroupLabel.Parent.RowHeight{2} = 0;
            end
            if NGroups < this.NGroups_I
                this.GroupItems = this.GroupItems(1:NGroups);
                this.LimitsInternal = this.LimitsInternal(1:NGroups,:);
                this.AutoScaleInternal = this.AutoScaleInternal(1:NGroups);
            elseif NGroups > this.NGroups_I
                if size(this.GroupItems,1) > size(this.GroupItems,2) %column
                    this.GroupItems = [this.GroupItems;cellstr(string(this.NGroups_I+1:NGroups))'];
                else %row
                    this.GroupItems = [this.GroupItems cellstr(string(this.NGroups_I+1:NGroups))];
                end
                this.LimitsInternal = [this.LimitsInternal;repmat({[0 1]},NGroups-this.NGroups_I,this.NLimits)];
                this.AutoScaleInternal = [this.AutoScaleInternal,true(1,NGroups-this.NGroups_I)];
            end
            this.SelectedGroup = this.GroupDropdown.Value;
            updateLimitEditFields(this,this.Limits);
            this.NGroups_I = NGroups;
        end

        % AutoScale
        function AutoScale = get.AutoScale(this)
            AutoScale = this.AutoScaleInternal(this.SelectedGroupIdx);
        end

        function set.AutoScale(this,AutoScale)
            if ~isempty(this.AutoScaleCheckbox) && isvalid(this.AutoScaleCheckbox) && this.UpdateWidget
                this.AutoScaleCheckbox.Value = AutoScale;
            end
            this.AutoScaleInternal(this.SelectedGroupIdx) = AutoScale;
        end

        % Limits
        function Limits = get.Limits(this)
            Limits = this.LimitsInternal(this.SelectedGroupIdx,:);
        end

        function set.Limits(this,Limits)
            for k = 1:length(Limits)
                if ~any(isnan(Limits{k}))
                    validateattributes(Limits{k},{'numeric'},{'increasing'});
                end
            end
            if this.IsWidgetValid
                updateLimitEditFields(this,Limits);
            end
            this.LimitsInternal(this.SelectedGroupIdx,:) = Limits;
        end

        % GroupLabelText
        function GroupLabelText = get.GroupLabelText(this)
            GroupLabelText = this.GroupLabelText_I;
        end

        function set.GroupLabelText(this,GroupLabelText)
            if this.IsWidgetValid && this.UpdateWidget
                this.GroupLabel.Text = GroupLabelText;
            end
            this.GroupLabelText_I = GroupLabelText;
        end

        % LimitsLabelText
        function LimitsLabelText = get.LimitsLabelText(this)
            LimitsLabelText = this.LimitsLabelText_I;
        end

        function set.LimitsLabelText(this,LimitsLabelText)
            if this.IsWidgetValid && this.UpdateWidget
                for k = 1:this.NLimits
                    this.LimitsLabel(k).Text = LimitsLabelText{k};
                end
            end
            this.LimitsLabelText_I = LimitsLabelText;
        end

        % GroupItems
        function GroupItems = get.GroupItems(this)
            GroupItems = this.GroupItems_I;
        end

        function set.GroupItems(this,GroupItems)
            idx = this.SelectedGroupIdx;
            selectedGroup = this.GroupItems_I(idx);
            if this.IsWidgetValid && this.UpdateWidget
                this.GroupDropdown.Items = GroupItems;
            end
            newIdx = find(strcmp(GroupItems,selectedGroup));
            if isempty(newIdx)
                newIdx = 1;
            end
            this.GroupItems_I = GroupItems;
            this.SelectedGroup_I = GroupItems{newIdx};
        end

        % SelectedGroup
        function SelectedGroup = get.SelectedGroup(this)
            SelectedGroup = this.SelectedGroup_I;
        end

        function set.SelectedGroup(this,SelectedGroup)
            if this.IsWidgetValid && this.UpdateWidget
                this.GroupDropdown.Value = SelectedGroup;
            end
            this.SelectedGroup_I = SelectedGroup;
            updateLimitEditFields(this,this.LimitsInternal(this.SelectedGroupIdx,:));
        end

        % SelectedGroupIdx
        function SelectedGroupIdx = get.SelectedGroupIdx(this)
            SelectedGroupIdx = find(strcmp(this.GroupItems,this.SelectedGroup));
        end

        function setLimits(this,limits,groupIdx,limitIdx)
            arguments
                this
                limits
                groupIdx = 1
                limitIdx = 1
            end
            % Extract cell element if limits is a cell array of 1 element
            if iscell(limits) && isscalar(limits)
                limits = limits{1};
            end
            % Set internal limits
            this.LimitsInternal{groupIdx,limitIdx} = limits;
            % Update widget
            if groupIdx == this.SelectedGroupIdx
                updateLimitEditFields(this,this.LimitsInternal(groupIdx,:));
            end
        end

        function setAutoScale(this,value,groupIdx)
            arguments
                this
                value
                groupIdx = 1
            end
            this.AutoScaleInternal(groupIdx) = value;
            if this.SelectedGroupIdx == groupIdx && this.IsWidgetValid
                this.AutoScaleCheckbox.Value = value;
            end
        end
        
        % Enable
        function Enable = get.Enable(this)
            Enable = this.Enable_I;
        end

        function set.Enable(this,Enable)
            arguments
                this
                Enable logical
            end

            this.AutoScaleCheckbox.Enable = Enable;
            this.GroupDropdown.Enable = Enable;
            for k = 1:length(this.LimitsEditField)
                this.LimitsEditField(k).Enable = Enable;
            end

            this.Enable_I = Enable;
        end
    end

    %% Protected sealed methods
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],...
                'RowHeight',repmat({'fit'},1,2+this.NLimits),...
                'ColumnWidth',{'fit','1x',70},...
                'Scrollable',"off");
            widget.Padding = 0;
            % AutoScale
            label = uilabel(widget,'Text',m('Controllib:gui:strAutoScaleLabel'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label.HorizontalAlignment = 'right';
            this.AutoScaleCheckbox = uicheckbox(widget,'Text','');
            this.AutoScaleCheckbox.Layout.Row = 1;
            this.AutoScaleCheckbox.Layout.Column = 2;
            this.AutoScaleCheckbox.Value = this.AutoScale;
            this.AutoScaleCheckbox.ValueChangedFcn = ...
                @(es,ed) cbAutoScaleCheckboxValueChanged(this,es,ed);
            % Group
            label = uilabel(widget,'Text',this.GroupLabelText);
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            label.HorizontalAlignment = 'right';
            this.GroupLabel = label;
            this.GroupDropdown = uidropdown(widget,'Items',this.GroupItems);
            this.GroupDropdown.Layout.Row = 2;
            this.GroupDropdown.Layout.Column = 2;
            this.GroupDropdown.Value = this.SelectedGroup;
            this.GroupDropdown.ValueChangedFcn = ...
                @(es,ed) cbGroupDropdownValueChanged(this,es,ed);
            this.GroupLabel.Visible = this.NGroups > 1;
            this.GroupDropdown.Visible = this.NGroups > 1;
            if this.NGroups == 1
                widget.RowHeight{2} = 0;
            end
            % Limits
            label = uilabel(widget,'Text',m('Controllib:gui:strLimitsLabel'));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label.HorizontalAlignment = 'right';
            this.LimitsEditField = matlab.ui.control.EditField.empty;
            for k = 1:this.NLimits
                % Create gridlayout for limit editfield row
                limitsLayout = uigridlayout(widget,[1 3]);
                limitsLayout.RowHeight = {'fit'};
                limitsLayout.ColumnWidth = {'1x','fit','1x'};
                limitsLayout.Padding = 0;
                limitsLayout.Layout.Row = 2 + k;
                limitsLayout.Layout.Column = 2;
                % Lower limit editfield
                lowerLimitEditField = uieditfield(limitsLayout);
                lowerLimitEditField.Layout.Column = 1;
                lowerLimitEditField.Value = localConvertNumericValueToChar(this.Limits{k}(1));
                lowerLimitEditField.ValueChangedFcn = ...
                    @(es,ed) cbLimitEditFieldValueChanged(this,es,ed,k,1);
                % Label 'to'
                label = uilabel(limitsLayout,'Text',m('Controllib:gui:strTo'));
                label.Layout.Column = 2;
                % Upper limit editfield
                upperLimitEditField = uieditfield(limitsLayout);
                upperLimitEditField.Layout.Column = 3;
                upperLimitEditField.Value = localConvertNumericValueToChar(this.Limits{k}(2));
                upperLimitEditField.ValueChangedFcn = ...
                    @(es,ed) cbLimitEditFieldValueChanged(this,es,ed,k,2);
                this.LimitsEditField = [this.LimitsEditField; ...
                    [lowerLimitEditField, upperLimitEditField]];
                % Limit Row Label
                label = uilabel(widget,'Text',this.LimitsLabelText{k});
                label.Layout.Row = 2 + k;
                label.Layout.Column = 3;
                this.LimitsLabel = [this.LimitsLabel, label];
            end
            % Add Tags
            if this.AddTagToWidgets
                addTags(this);
            end
        end
    end

    %% Private methods
    methods (Access = private)
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    for k = 1:length(this.(wn{1}))
                        w = this.(wn{1});
                        w(k).Tag = this.WidgetTags.(wn{1});
                    end
                end
            end
        end

        function cbAutoScaleCheckboxValueChanged(this,~,ed)
            this.UpdateWidget = false;
            this.AutoScale = ed.Value;
            this.UpdateWidget = true;
        end

        function cbGroupDropdownValueChanged(this,~,ed)
            this.UpdateWidget = false;
            this.SelectedGroup = ed.Value;
            this.AutoScaleCheckbox.Value = this.AutoScale;
            this.UpdateWidget = true;
        end

        function cbLimitEditFieldValueChanged(this,es,ed,limitIdx,typeIdx)
            if isempty(ed.Value)
                % If value is empty, set LimitsInternal to NaN
                groupIdx = this.SelectedGroupIdx;
                this.LimitsInternal{groupIdx,limitIdx}(typeIdx) = NaN;
            else
                setAutoScaleFalse = true;
                try
                    % Value should be valid in workspace and limits should
                    % be increasing
                    value = evalin('base',ed.Value);
                    this.Limits{limitIdx}(typeIdx) = value;
                catch
                    % Reset to previous value, do not throw error
                    if strcmp(ed.PreviousValue,'')
                        value = NaN;
                    else
                        value = evalin('base',ed.PreviousValue);
                    end
                    setAutoScaleFalse = false;
                end
                if isnan(value)
                    es.Value = '';
                else
                    es.Value = num2str(value,3);
                end
                if setAutoScaleFalse
                    % Set autoscale to false if limits are changed
                    this.AutoScale = false;
                end
            end
        end

        function updateLimitEditFields(this,Limits)
            if this.IsWidgetValid
                for k = 1:this.NLimits
                    this.LimitsEditField(k,1).Value = localConvertNumericValueToChar(Limits{k}(1));
                    this.LimitsEditField(k,2).Value = localConvertNumericValueToChar(Limits{k}(2));
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.AutoScaleCheckbox = this.AutoScaleCheckbox;
            widgets.GroupLabel = this.GroupLabel;
            widgets.GroupDropdown = this.GroupDropdown;
            widgets.LimitsEditField = this.LimitsEditField;
        end
    end
end

function editfieldValue = localConvertNumericValueToChar(limitValue)
if isnan(limitValue)
    editfieldValue = '';
else
    editfieldValue = num2str(limitValue,3);
end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
