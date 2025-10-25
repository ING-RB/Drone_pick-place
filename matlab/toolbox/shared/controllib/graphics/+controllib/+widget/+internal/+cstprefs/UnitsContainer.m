classdef (ConstructOnLoad) UnitsContainer < controllib.widget.internal.cstprefs.AbstractContainer & ...
        matlab.mixin.SetGet
    % "UnitsContainer":
    % Widget that is used to specify units and scale for Frequency,
    % Magnitude, Phase and Time.
    %
    % To use container in a dialog/panel:
    %   
    %   c = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits','FrequencyScale',...
    %                                                          'MagnitudeUnits','MagnitudeScale',...
    %                                                          'PhaseUnits','TimeUnits');
    %   w = getWidget(c);
    %   f = uifigure;
    %   w.Parent = f;
    %
    % Properties (set or get the preferences for the following)
    %   FrequencyUnits
    %   FrequencyScale
    %   MagnitudeUnits
    %   MagnitudeScale
    %   PhaseUnits
    %   TimeUnits
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Dependent,SetObservable,AbortSet)
        FrequencyUnits
        FrequencyScale
        MagnitudeUnits
        MagnitudeScale
        PhaseUnits
        TimeUnits
        FrequencyRowVisible
        TimeRowVisible
        MagnitudeRowVisible
        PhaseRowVisible
    end
    
    properties (Dependent,AbortSet)
        ValidFrequencyUnits
        ValidMagnitudeUnits
        ValidPhaseUnits
        ValidTimeUnits
    end
    
    properties (Access = private)
        UnitsContainerWidget

        FrequencyRow = []
        TimeRow = []
        MagnitudeRow = []
        PhaseRow = []
        ShowFrequencyScale = false
        ShowMagnitudeScale = false
        UpdateWidget = true
        
        FrequencyUnitsInternal
        FrequencyScaleInternal
        MagnitudeScaleInternal
        MagnitudeUnitsInternal
        PhaseUnitsInternal
        TimeUnitsInternal
        
        FrequencyLabel
        FrequencyDropDown
        FrequencyScaleLabel
        FrequencyScaleDropDown
        MagnitudeLabel
        MagnitudeDropDown
        MagnitudeScaleLabel
        MagnitudeScaleDropDown
        PhaseLabel
        PhaseDropDown
        TimeLabel
        TimeDropDown
        
        ValidFrequencyUnits_I =     [{'auto','Controllib:gui:strAuto'}; ...
                                    controllibutils.utGetValidFrequencyUnits];
        ValidScales =               {'log',      'Controllib:gui:strLogScale'; ...
                                    'linear',   'Controllib:gui:strLinearScale'};
        ValidMagnitudeUnits_I =     {'dB',        'Controllib:gui:strDB';...
                                    'abs',  'Controllib:gui:strAbsoluteValue'};
        ValidPhaseUnits_I =         {'deg',   'Controllib:gui:strDegrees';...
                                    'rad',   'Controllib:gui:strRadians'};
        ValidTimeUnits_I =          [{'auto','Controllib:gui:strAuto'}; ...
                                    controllibutils.utGetValidTimeUnits];
        WidgetTags = struct(...
                      'TitleLabel','UnitsTitleLabel',...
                      'FrequencyLabel','FrequencyUnitsLabel',...
                      'FrequencyDropDown','FrequencyUnitsDropDown',...
                      'FrequencyScaleLabel','FrequencyScaleLabel',...
                      'FrequencyScaleDropDown','FrequencyScaleDropDown',...
                      'MagnitudeLabel','MagnitudeUnitsLabel',...
                      'MagnitudeDropDown','MagnitudeUnitsDropDown',...
                      'MagnitudeScaleLabel','MagnitudeScaleLabel',...
                      'MagnitudeScaleDropDown','MagnitudeScaleDropDown',...
                      'PhaseLabel','PhaseUnitsLabel',...
                      'PhaseDropDown','PhaseUnitsDropDown',...
                      'TimeLabel','TimeUnitsLabel',...
                      'TimeDropDown','TimeUnitsDropDown');                             
    end
    
    properties(Hidden)
        AddTagsToWidgets = true
    end
    
    methods
        function this = UnitsContainer(varargin)
            inputs = varargin;
            idx = find(contains(inputs,'FrequencyScale'));
            if ~isempty(idx)
                this.ShowFrequencyScale = true;
                inputs(idx) = [];
            end
            idx = find(contains(inputs,'MagnitudeScale'));
            if ~isempty(idx)
                this.ShowMagnitudeScale = true;
                inputs(idx) = [];
            end            
            this.FrequencyRow = find(contains(inputs,'FrequencyUnits'));
            this.TimeRow = find(contains(inputs,'TimeUnits'));
            this.MagnitudeRow = find(contains(inputs,'MagnitudeUnits'));
            this.PhaseRow = find(contains(inputs,'PhaseUnits'));
            this.ContainerTitle = m('Controllib:gui:strUnits');
            initialize(this);
        end
    end
    
    methods %set/get
        % FrequencyUnits
        function FrequencyUnits = get.FrequencyUnits(this)
            FrequencyUnits = this.FrequencyUnitsInternal;
        end
        
        function set.FrequencyUnits(this,FrequencyUnits)
            if ~isempty(this.FrequencyDropDown) && isvalid(this.FrequencyDropDown)
                this.FrequencyDropDown.Value = FrequencyUnits;
            end
            this.FrequencyUnitsInternal = FrequencyUnits;
        end
        
        % ValidFrequencyUnits
        function ValidFrequencyUnits = get.ValidFrequencyUnits(this)
            ValidFrequencyUnits = this.ValidFrequencyUnits_I;
        end
        
        function set.ValidFrequencyUnits(this,ValidFrequencyUnits)
            this.ValidFrequencyUnits_I = ValidFrequencyUnits;
            if this.IsWidgetValid
                this.FrequencyDropDown.Items = ValidFrequencyUnits(:,1);
                this.FrequencyDropDown.ItemsData = ValidFrequencyUnits(:,2);
            end
        end
        
        % FrequencyScale
        function FrequencyScale = get.FrequencyScale(this)
            FrequencyScale = this.FrequencyScaleInternal;
        end
        
        function set.FrequencyScale(this,FrequencyScale)
            if ~isempty(this.FrequencyScaleDropDown) && isvalid(this.FrequencyScaleDropDown)
                this.FrequencyScaleDropDown.Value = FrequencyScale;
            end
            this.FrequencyScaleInternal = FrequencyScale;
        end
        
        % MagnitudeUnits
        function MagnitudeUnits = get.MagnitudeUnits(this)
            MagnitudeUnits = this.MagnitudeUnitsInternal;
        end
        
        function set.MagnitudeUnits(this,MagnitudeUnits)
            if ~isempty(this.MagnitudeDropDown) && isvalid(this.MagnitudeDropDown)
                this.MagnitudeDropDown.Value = MagnitudeUnits;
                if strcmp(MagnitudeUnits,'dB')
                    this.MagnitudeScaleLabel.Enable = false;
                    this.MagnitudeScaleDropDown.Enable = false;
                    this.MagnitudeScale = 'linear';
                else
                    this.MagnitudeScaleLabel.Enable = true;
                    this.MagnitudeScaleDropDown.Enable = true;
                end
            end
            this.MagnitudeUnitsInternal = MagnitudeUnits;
        end

        % ValidMagnitudeUnits
        function ValidMagnitudeUnits = get.ValidMagnitudeUnits(this)
            ValidMagnitudeUnits = this.ValidMagnitudeUnits_I;
        end
        
        function set.ValidMagnitudeUnits(this,ValidMagnitudeUnits)
            this.ValidMagnitudeUnits_I = ValidMagnitudeUnits;
            if this.IsWidgetValid
                this.MagnitudeDropDown.Items = ValidMagnitudeUnits(:,1);
                this.MagnitudeDropDown.ItemsData = ValidMagnitudeUnits(:,2);
            end
        end
        
        % MagnitudeScale
        function MagnitudeScale = get.MagnitudeScale(this)
            MagnitudeScale = this.MagnitudeScaleInternal;
        end
        
        function set.MagnitudeScale(this,MagnitudeScale)
            if ~isempty(this.MagnitudeScaleDropDown) && isvalid(this.MagnitudeScaleDropDown)
                this.MagnitudeScaleDropDown.Value = MagnitudeScale;
            end
            this.MagnitudeScaleInternal = MagnitudeScale;
        end
        
        % PhaseUnits
        function PhaseUnits = get.PhaseUnits(this)
            PhaseUnits = this.PhaseUnitsInternal;
        end
        
        function set.PhaseUnits(this,PhaseUnits)
            if ~isempty(this.PhaseDropDown) && isvalid(this.PhaseDropDown)
                this.PhaseDropDown.Value = PhaseUnits;
            end
            this.PhaseUnitsInternal = PhaseUnits;
        end
        
        % ValidPhaseUnits
        function ValidPhaseUnits = get.ValidPhaseUnits(this)
            ValidPhaseUnits = this.ValidPhaseUnits_I;
        end
        
        function set.ValidPhaseUnits(this,ValidPhaseUnits)
            this.ValidPhaseUnits_I = ValidPhaseUnits;
            if this.IsWidgetValid
                this.PhaseDropDown.Items = ValidPhaseUnits(:,1);
                this.PhaseDropDown.ItemsData = ValidPhaseUnits(:,2);
            end
        end
        
        % TimeUnits
        function TimeUnits = get.TimeUnits(this)
            TimeUnits = this.TimeUnitsInternal;
        end
        
        function set.TimeUnits(this,TimeUnits)
            if ~isempty(this.TimeDropDown) && isvalid(this.TimeDropDown)
                this.TimeDropDown.Value = TimeUnits;
            end
            this.TimeUnitsInternal = TimeUnits;
        end
        
        % ValidTimeUnits
        function ValidTimeUnits = get.ValidTimeUnits(this)
            ValidTimeUnits = this.ValidTimeUnits_I;
        end
        
        function set.ValidTimeUnits(this,ValidTimeUnits)
            this.ValidTimeUnits_I = ValidTimeUnits;
            if this.IsWidgetValid
                this.TimeDropDown.Items = ValidTimeUnits(:,1);
                this.TimeDropDown.ItemsData = ValidTimeUnits(:,2);
            end
        end

        % FrequencyRowVisible
        function FrequencyRowVisible = get.FrequencyRowVisible(this)
            if isempty(this.FrequencyLabel) || ~isvalid(this.FrequencyLabel)
                FrequencyRowVisible = false;
            else
                FrequencyRowVisible = this.FrequencyLabel.Visible;
            end
        end

        function set.FrequencyRowVisible(this,FrequencyRowVisible)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.UnitsContainer
                FrequencyRowVisible (1,1) matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.FrequencyLabel) && isvalid(this.FrequencyLabel)
                this.FrequencyLabel.Visible = FrequencyRowVisible;
                this.FrequencyDropDown.Visible = FrequencyRowVisible;
                if this.ShowFrequencyScale
                    this.FrequencyScaleLabel.Visible = FrequencyRowVisible;
                    this.FrequencyScaleDropDown.Visible = FrequencyRowVisible;
                end
                if FrequencyRowVisible
                    this.UnitsContainerWidget.RowHeight{this.FrequencyRow} = 'fit';
                else
                    this.UnitsContainerWidget.RowHeight{this.FrequencyRow} = 0;
                end
            end
        end

        % TimeRowVisible
        function TimeRowVisible = get.TimeRowVisible(this)
            if isempty(this.TimeLabel) || ~isvalid(this.TimeLabel)
                TimeRowVisible = false;
            else
                TimeRowVisible = this.TimeLabel.Visible;
            end            
        end

        function set.TimeRowVisible(this,TimeRowVisible)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.UnitsContainer
                TimeRowVisible (1,1) matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.TimeLabel) && isvalid(this.TimeLabel)
                this.TimeLabel.Visible = TimeRowVisible;
                this.TimeDropDown.Visible = TimeRowVisible;
                if TimeRowVisible
                    this.UnitsContainerWidget.RowHeight{this.TimeRow} = 'fit';
                else
                    this.UnitsContainerWidget.RowHeight{this.TimeRow} = 0;
                end
            end
        end

        % MagnitudeRowVisible
        function MagnitudeRowVisible = get.MagnitudeRowVisible(this)
            if isempty(this.MagnitudeLabel) || ~isvalid(this.MagnitudeLabel)
                MagnitudeRowVisible = false;
            else
                MagnitudeRowVisible = this.MagnitudeLabel.Visible;
            end
        end

        function set.MagnitudeRowVisible(this,MagnitudeRowVisible)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.UnitsContainer
                MagnitudeRowVisible (1,1) matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.MagnitudeLabel) && isvalid(this.MagnitudeLabel)
                this.MagnitudeLabel.Visible = MagnitudeRowVisible;
                this.MagnitudeDropDown.Visible = MagnitudeRowVisible;
                if this.ShowMagnitudeScale
                    this.MagnitudeScaleLabel.Visible = MagnitudeRowVisible;
                    this.MagnitudeScaleDropDown.Visible = MagnitudeRowVisible;
                end
                if MagnitudeRowVisible
                    this.UnitsContainerWidget.RowHeight{this.MagnitudeRow} = 'fit';
                else
                    this.UnitsContainerWidget.RowHeight{this.MagnitudeRow} = 0;
                end
            end
        end

        % PhaseRowVisible
        function PhaseRowVisible = get.PhaseRowVisible(this)
            if isempty(this.PhaseLabel) || ~isvalid(this.PhaseLabel)
                PhaseRowVisible = false;
            elseif ~isempty(this.PhaseLabel) && isvalid(this.PhaseLabel)
                PhaseRowVisible = this.PhaseLabel.Visible;
            end
        end

        function set.PhaseRowVisible(this,PhaseRowVisible)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.UnitsContainer
                PhaseRowVisible (1,1) matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.PhaseLabel) && isvalid(this.PhaseLabel)
                this.PhaseLabel.Visible = PhaseRowVisible;
                this.PhaseDropDown.Visible = PhaseRowVisible;
                if PhaseRowVisible
                    this.UnitsContainerWidget.RowHeight{this.PhaseRow} = 'fit';
                else
                    this.UnitsContainerWidget.RowHeight{this.PhaseRow} = 0;
                end
            end
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createWidget(this)
            this.UnitsContainerWidget = uigridlayout('Parent',[],'RowHeight',{'fit'},'ColumnWidth',{'fit','1x'},...
                'Scrollable',"off");
            this.UnitsContainerWidget.Padding = 0;
            nRows = max([this.FrequencyRow,this.TimeRow,this.MagnitudeRow,this.PhaseRow]);
            if ~isempty(nRows)
                % Set RowHeight and ColumnWidth
                this.UnitsContainerWidget.RowHeight = repmat({'fit'},1,nRows);
                if this.ShowFrequencyScale || this.ShowMagnitudeScale
                    this.UnitsContainerWidget.ColumnWidth = {'fit','1x','fit','1x'};
                end
                % Frequency Units
                if this.FrequencyRow
                    [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                        m('Controllib:gui:strFrequencyLabel'),this.ValidFrequencyUnits_I,...
                        this.FrequencyUnitsInternal,this.FrequencyRow,1);
                    this.FrequencyLabel = label;
                    this.FrequencyDropDown = dropdown;
                    this.FrequencyDropDown.ValueChangedFcn = ...
                        @(es,ed) callbackFrequencyUnitsChanged(this,es,ed);
                    % Frequency Scale
                    if this.ShowFrequencyScale
                        [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                            m('Controllib:gui:strScaleLabel'),this.ValidScales,...
                            this.FrequencyScaleInternal,this.FrequencyRow,2);
                        this.FrequencyScaleLabel = label;
                        this.FrequencyScaleDropDown = dropdown;
                        this.FrequencyScaleDropDown.ValueChangedFcn = ...
                            @(es,ed) callbackFrequencyScaleChanged(this,es,ed);
                    end
                end
                % Magnitude Units
                if this.MagnitudeRow
                    [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                        m('Controllib:gui:strMagnitudeLabel'),this.ValidMagnitudeUnits_I,...
                        this.MagnitudeUnitsInternal,this.MagnitudeRow,1);
                    this.MagnitudeLabel = label;
                    this.MagnitudeDropDown = dropdown;
                    this.MagnitudeDropDown.ValueChangedFcn = ...
                        @(es,ed) callbackMagnitudeUnitsChanged(this,es,ed);
                    % Magnitude Scale
                    if this.ShowMagnitudeScale
                        [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                            m('Controllib:gui:strScaleLabel'),this.ValidScales,...
                            this.MagnitudeScaleInternal,this.MagnitudeRow,2);
                        this.MagnitudeScaleLabel = label;
                        this.MagnitudeScaleDropDown = dropdown;
                        if strcmp(this.MagnitudeUnitsInternal,'dB')
                            this.MagnitudeScaleDropDown.Enable = false;
                        end
                        this.MagnitudeScaleDropDown.ValueChangedFcn = ...
                            @(es,ed) callbackMagnitudeScaleChanged(this,es,ed);
                    end
                end
                % Phase Units
                if this.PhaseRow
                    [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                        m('Controllib:gui:strPhaseLabel'),this.ValidPhaseUnits_I,...
                        this.PhaseUnitsInternal,this.PhaseRow,1);
                    this.PhaseLabel = label;
                    this.PhaseDropDown = dropdown;
                    this.PhaseDropDown.ValueChangedFcn = ...
                        @(es,ed) callbackPhaseUnitsChanged(this,es,ed);
                end
                % Time Units
                if this.TimeRow
                    [label,dropdown] = localBuildDropDown(this.UnitsContainerWidget,...
                        m('Controllib:gui:strTimeLabel'),this.ValidTimeUnits_I,...
                        this.TimeUnitsInternal,this.TimeRow,1);
                    this.TimeLabel = label;
                    this.TimeDropDown = dropdown;
                    this.TimeDropDown.ValueChangedFcn = ...
                        @(es,ed) callbackTimeUnitsChanged(this,es,ed);
                end
            end
            % Add Tags
            if this.AddTagsToWidgets
                addTags(this);
            end
            widget = this.UnitsContainerWidget;
        end
    end
    
    methods(Access = private)
        function initialize(this)
            tbPrefs = cstprefs.tbxprefs;
            this.FrequencyUnitsInternal = tbPrefs.FrequencyUnits;
            this.FrequencyScaleInternal = tbPrefs.FrequencyScale;
            this.MagnitudeUnitsInternal = tbPrefs.MagnitudeUnits;
            this.MagnitudeScaleInternal = tbPrefs.MagnitudeScale;
            this.PhaseUnitsInternal = tbPrefs.PhaseUnits;
            this.TimeUnitsInternal = tbPrefs.TimeUnits;
        end
        
        function addTags(this)
            widgetNames = fieldnames(this.WidgetTags);
            for wn = widgetNames'
                if ~isempty(this.(wn{1})) && isvalid(this.(wn{1}))
                    this.(wn{1}).Tag = this.WidgetTags.(wn{1});
                end
            end
        end
        
        function callbackFrequencyUnitsChanged(this,es,ed)
            this.FrequencyUnits = ed.Value;
        end
        
        function callbackFrequencyScaleChanged(this,es,ed)
            this.FrequencyScale = ed.Value;
        end
        
        function callbackMagnitudeUnitsChanged(this,es,ed)
            this.MagnitudeUnits = ed.Value;
        end
        
        function callbackMagnitudeScaleChanged(this,es,ed)
            this.MagnitudeScale = ed.Value;
        end
        
        function callbackPhaseUnitsChanged(this,es,ed)
            this.PhaseUnits = ed.Value;
        end
        
        function callbackTimeUnitsChanged(this,es,ed)
            this.TimeUnits = ed.Value;
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.TitleLabel = this.TitleLabel;
            widgets.FrequencyLabel = this.FrequencyLabel;
            widgets.FrequencyDropDown = this.FrequencyDropDown;
            widgets.FrequencyScaleLabel = this.FrequencyScaleLabel;
            widgets.FrequencyScaleDropDown = this.FrequencyScaleDropDown;
            widgets.MagnitudeLabel = this.MagnitudeLabel;
            widgets.MagnitudeDropDown = this.MagnitudeDropDown;
            widgets.MagnitudeScaleLabel = this.MagnitudeScaleLabel;
            widgets.MagnitudeScaleDropDown = this.MagnitudeScaleDropDown;
            widgets.PhaseLabel = this.PhaseLabel;
            widgets.PhaseDropDown = this.PhaseDropDown;
            widgets.TimeLabel = this.TimeLabel;
            widgets.TimeDropDown = this.TimeDropDown;
        end
    end
end

function [label,dropdown] = localBuildDropDown(container,labelText,...
    validValues,value,rowIdx,columnIdx)
label = uilabel(container);
label.Layout.Row = rowIdx;
label.Layout.Column = 2*columnIdx-1;
label.Text = labelText;
dropdown = uidropdown(container);
dropdown.Layout.Row = rowIdx;
dropdown.Layout.Column = 2*columnIdx;
dropdown.ItemsData = validValues(:,1);
dropdown.Items = cellfun(@(x) m(x),validValues(:,2),...
    'UniformOutput',false);
dropdown.Value = value;
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
