classdef (ConstructOnLoad) PhaseResponseContainer < controllib.widget.internal.cstprefs.AbstractContainer
    % "PhaseResponseContainer":
    % Widget that is used to specify phase wrapping branch and phase
    % offsets for phase response plots.
    %
    % To use container in a dialog/panel:
    %
    %   c = controllib.widget.internal.cstprefs.PhaseResponseContainer();
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties
    %   UnwrapPhase:
    %       Enable or disable phase wrapping. Accepted values are 'on' or
    %       'off'.
    %   PhaseWrappingBrance:
    %       Set or get the numeric value at which phase is wrapped.
    %   ComparePhase:
    %       Settings for adjusting the phase offsets.
    %           ComparePhase.Enable is 'on' or 'off'
    %           ComparePhase.Freq is the frequency at which the phase is
    %           kept close to ComparePhase.Phase
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Dependent,SetObservable,AbortSet)
        UnwrapPhase
        PhaseWrappingBranch
        ComparePhase
        PhaseUnits
        FrequencyUnits
    end
    
    properties (Access = private)
        ShowWrapPhase = true
        ShowComparePhase = true
        WrapPhaseCheckBox
        WrapPhaseEditField
        WrapPhaseLabel
        ComparePhaseCheckBox
        ComparePhaseEditField
        ComparePhaseLabel
        ComparePhaseFrequencyEditField
        ComparePhaseFrequencyLabel
        UnwrapPhaseInternal
        PhaseWrappingBranchInternal
        ComparePhaseInternal
        PhaseUnitsInternal
        FrequencyUnitsInternal
        UpdateWidget = true
        WidgetTags = struct(...
            'WrapPhaseCheckBox','WrapPhaseCheckBox',...
            'WrapPhaseEditField','WrapPhaseEditField',...
            'WrapPhaseLabel','WrapPhaseLabel',...
            'ComparePhaseCheckBox','ComparePhaseCheckBox',...
            'ComparePhaseEditField','ComparePhaseEditField',...
            'ComparePhaseLabel','ComparePhaseLabel',...
            'ComparePhaseFrequencyEditField','ComparePhaseFrequencyEditField',...
            'ComparePhaseFrequencyLabel','ComparePhaseFrequencyLabel');
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = PhaseResponseContainer(varargin)
            if nargin > 0
                this.ShowWrapPhase = any(contains(varargin,'WrapPhase'));
                this.ShowComparePhase = any(contains(varargin,'ComparePhase'));
            end
            toolboxPreferences = cstprefs.tbxprefs;
            this.UnwrapPhase = toolboxPreferences.UnwrapPhase;
            this.PhaseWrappingBranch = toolboxPreferences.PhaseWrappingBranch;
            this.ComparePhase = toolboxPreferences.ComparePhase;
            this.PhaseUnitsInternal = toolboxPreferences.PhaseUnits;
            this.FrequencyUnitsInternal = toolboxPreferences.FrequencyUnits;
            this.ContainerTitle = m('Controllib:gui:strPhaseResponse');
        end
    end
    
    methods %set/get
        % UnwrapPhase
        function UnwrapPhase = get.UnwrapPhase(this)
            UnwrapPhase = this.UnwrapPhaseInternal;
        end
        
        function set.UnwrapPhase(this,UnwrapPhase)
            if ~isempty(this.WrapPhaseCheckBox) && isvalid(this.WrapPhaseCheckBox) && ...
                    this.UpdateWidget
                this.WrapPhaseCheckBox.Value = strcmp(UnwrapPhase,'off');
                if strcmp(UnwrapPhase,'off')
                    this.WrapPhaseEditField.Enable = 'on';
%                     this.WrapPhaseLabel.Enable = 'on';
                else
                    this.WrapPhaseEditField.Enable = 'off';
%                     this.WrapPhaseLabel.Enable = 'off';
                end
            end
            this.UnwrapPhaseInternal = UnwrapPhase;
        end
        
        % PhaseWrappingBranch
        function PhaseWrappingBranch = get.PhaseWrappingBranch(this)
            PhaseWrappingBranch = this.PhaseWrappingBranchInternal;
        end
        
        function set.PhaseWrappingBranch(this,PhaseWrappingBranch)
            if ~isempty(this.WrapPhaseEditField) && isvalid(this.WrapPhaseEditField) && ...
                    this.UpdateWidget
                this.WrapPhaseEditField.Value = PhaseWrappingBranch;
            end
            this.PhaseWrappingBranchInternal = PhaseWrappingBranch;
        end
        
        % ComparePhase
        function ComparePhase = get.ComparePhase(this)
            ComparePhase = this.ComparePhaseInternal;
        end
        
        function set.ComparePhase(this,ComparePhase)
            if ~isempty(this.ComparePhaseCheckBox) && isvalid(this.ComparePhaseCheckBox) && ...
                    this.UpdateWidget
                this.ComparePhaseCheckBox.Value = strcmp(ComparePhase.Enable,'on');
                this.ComparePhaseEditField.Value = ComparePhase.Phase;
                this.ComparePhaseEditField.Enable = ComparePhase.Enable;
                this.ComparePhaseLabel.Enable = ComparePhase.Enable;
                this.ComparePhaseFrequencyEditField.Value = ComparePhase.Freq;
                this.ComparePhaseFrequencyEditField.Enable = ComparePhase.Enable;
                this.ComparePhaseFrequencyLabel.Enable = ComparePhase.Enable;
            end
            this.ComparePhaseInternal = ComparePhase;
        end
        
        % PhaseUnits
        function PhaseUnits = get.PhaseUnits(this)
            PhaseUnits = this.PhaseUnitsInternal;
        end
        
        function set.PhaseUnits(this,PhaseUnits)
            validatestring(PhaseUnits,{'deg','rad'});
            this.PhaseUnitsInternal = PhaseUnits;
            switch PhaseUnits
                case 'deg'
                    this.PhaseWrappingBranch = rad2deg(this.PhaseWrappingBranch);
                    this.ComparePhase.Phase = rad2deg(this.ComparePhase.Phase);
                case 'rad'
                    this.PhaseWrappingBranch = deg2rad(this.PhaseWrappingBranch);
                    this.ComparePhase.Phase = deg2rad(this.ComparePhase.Phase);
            end
        end
        
        % FrequencyUnits
        function FrequencyUnits = get.FrequencyUnits(this)
            FrequencyUnits = this.FrequencyUnitsInternal;
        end
        
        function set.FrequencyUnits(this,FrequencyUnits)
            if ~isempty(this.FrequencyUnitsInternal)
                freq = this.ComparePhase.Freq;
                if strcmp(this.FrequencyUnitsInternal,'auto')
                    fOld = 'Hz';
                else
                    fOld = this.FrequencyUnitsInternal;
                end
                newFreq = freq*funitconv(char(fOld),char(FrequencyUnits));
                this.ComparePhase.Freq = newFreq;
            end
            this.FrequencyUnitsInternal = FrequencyUnits;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            widget = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit','fit','fit'},...
                'ColumnWidth',{30,'fit','1x'},...
                'Scrollable',"off");
            widget.Padding = 0;
            % Wrap Phase
            if this.ShowWrapPhase
                this.WrapPhaseCheckBox = uicheckbox(widget);
                this.WrapPhaseCheckBox.Layout.Row = 1;
                this.WrapPhaseCheckBox.Layout.Column = [1 2];
                this.WrapPhaseCheckBox.Text = m('Controllib:gui:strWrapPhase');
                this.WrapPhaseCheckBox.Value = strcmp(this.UnwrapPhase,'off');
                this.WrapPhaseCheckBox.ValueChangedFcn = ...
                    @(es,ed) callbackWrapPhaseCheckBoxValueChangedFcn(this,es,ed);
%                 this.WrapPhaseLabel = uilabel(widget,...
%                     'Text',m('Controllib:gui:strWrapPhaseBranch'));
%                 this.WrapPhaseLabel.Layout.Row = 2;
%                 this.WrapPhaseLabel.Layout.Column = 2;
%                 this.WrapPhaseLabel.Enable = strcmp(this.UnwrapPhase,'off');
                this.WrapPhaseEditField = uieditfield(widget,'numeric');
                this.WrapPhaseEditField.Limits = [-Inf Inf];
                this.WrapPhaseEditField.LowerLimitInclusive = 'off';
                this.WrapPhaseEditField.UpperLimitInclusive = 'off';
                this.WrapPhaseEditField.Layout.Row = 1;
                this.WrapPhaseEditField.Layout.Column = 3;
                this.WrapPhaseEditField.Enable = strcmp(this.UnwrapPhase,'off');
                this.WrapPhaseEditField.Value = this.PhaseWrappingBranch;
                this.WrapPhaseEditField.ValueChangedFcn = ...
                    @(es,ed) callbackWrapPhaseEditFieldValueChangedFcn(this,es,ed);
            end
            % Compare Phase
            if this.ShowComparePhase
                this.ComparePhaseCheckBox = uicheckbox(widget);
                this.ComparePhaseCheckBox.Layout.Row = 3;
                this.ComparePhaseCheckBox.Layout.Column = [1 3];
                this.ComparePhaseCheckBox.Text = m('Controllib:gui:strAdjustPhaseOffsets');
                this.ComparePhaseCheckBox.Value = strcmp(this.ComparePhase.Enable,'on');
                this.ComparePhaseCheckBox.ValueChangedFcn = ...
                    @(es,ed) callbackComparePhaseCheckBoxValueChangedFcn(this,es,ed);
                this.ComparePhaseLabel = uilabel(widget,...
                    'Text',m('Controllib:gui:strKeepPhaseCloseToLabel'));
                this.ComparePhaseLabel.Layout.Row = 4;
                this.ComparePhaseLabel.Layout.Column = 2;
                this.ComparePhaseLabel.Enable = this.ComparePhase.Enable;
                this.ComparePhaseEditField = uieditfield(widget,'numeric');
                this.ComparePhaseEditField.Limits = [-Inf Inf];
                this.ComparePhaseEditField.LowerLimitInclusive = 'off';
                this.ComparePhaseEditField.UpperLimitInclusive = 'off';
                this.ComparePhaseEditField.Layout.Row = 4;
                this.ComparePhaseEditField.Layout.Column = 3;
                this.ComparePhaseEditField.Enable = this.ComparePhase.Enable;
                this.ComparePhaseEditField.Value = this.ComparePhase.Phase;
                this.ComparePhaseEditField.ValueChangedFcn = ...
                    @(es,ed) callbackComparePhaseEditFieldValueChangedFcn(this,es,ed);
                this.ComparePhaseFrequencyLabel = uilabel(widget,...
                    'Text',m('Controllib:gui:strAtFrequencyLabel'));
                this.ComparePhaseFrequencyLabel.Layout.Row = 5;
                this.ComparePhaseFrequencyLabel.Layout.Column = 2;
                this.ComparePhaseFrequencyLabel.Enable = this.ComparePhase.Enable;
                this.ComparePhaseFrequencyEditField = uieditfield(widget,'numeric');
                this.ComparePhaseFrequencyEditField.Layout.Row = 5;
                this.ComparePhaseFrequencyEditField.Layout.Column = 3;
                this.ComparePhaseFrequencyEditField.Enable = this.ComparePhase.Enable;
                this.ComparePhaseFrequencyEditField.Value = this.ComparePhase.Freq;
                this.ComparePhaseFrequencyEditField.ValueChangedFcn = ...
                    @(es,ed) callbackComparePhaseFrequencyEditFieldValueChangedFcn(this,es,ed);
            end
            % Add Tags
            if this.AddTagsToWidgets
                addTags(this);
            end
        end
    end
    
    methods (Access = private)
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    this.(wn{1}).Tag = this.WidgetTags.(wn{1});
                end
            end
        end
        
        function callbackWrapPhaseCheckBoxValueChangedFcn(this,es,ed)
            if ed.Value
                this.UnwrapPhase = 'off';
            else
                this.UnwrapPhase = 'on';
            end
        end
        
        function callbackWrapPhaseEditFieldValueChangedFcn(this,es,ed)
            this.PhaseWrappingBranch = ed.Value;
        end
        
        function callbackComparePhaseCheckBoxValueChangedFcn(this,es,ed)
            if ed.Value
                this.ComparePhase.Enable = 'on';
            else
                this.ComparePhase.Enable = 'off';
            end
        end
        
        function callbackComparePhaseEditFieldValueChangedFcn(this,es,ed)
            this.ComparePhase.Phase = ed.Value;
        end
        
        function callbackComparePhaseFrequencyEditFieldValueChangedFcn(this,es,ed)
            this.ComparePhase.Freq = ed.Value;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.WrapPhaseCheckBox = this.WrapPhaseCheckBox;
            widgets.WrapPhaseEditField = this.WrapPhaseEditField;
            widgets.WrapPhaseLabel = this.WrapPhaseLabel;
            widgets.ComparePhaseCheckBox = this.ComparePhaseCheckBox;
            widgets.ComparePhaseEditField = this.ComparePhaseEditField;
            widgets.ComparePhaseLabel = this.ComparePhaseLabel;
            widgets.ComparePhaseFrequencyEditField = this.ComparePhaseFrequencyEditField;
            widgets.ComparePhaseFrequencyLabel = this.ComparePhaseFrequencyLabel;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
