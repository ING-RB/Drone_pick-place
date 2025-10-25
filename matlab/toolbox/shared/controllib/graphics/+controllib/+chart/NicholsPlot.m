classdef NicholsPlot < controllib.chart.internal.foundation.RowColumnPlot & ...
                    controllib.chart.internal.foundation.MixInInputOutputPlot
    % NicholsPlot

    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        FrequencyUnit
        MagnitudeUnit
        PhaseUnit
        MagnitudeScale

        PhaseWrappingEnabled
        PhaseWrappingBranch

        PhaseMatchingEnabled
        PhaseMatchingFrequency
        PhaseMatchingValue

        MinimumGainEnabled
        MinimumGainValue
    end

    properties (GetAccess=protected,SetAccess=private)
        FrequencyUnit_I = "rad/s"
        MagnitudeUnit_I = "dB"
        PhaseUnit_I = "deg"
        MagnitudeScale_I = "linear"

        PhaseWrappingEnabled_I = matlab.lang.OnOffSwitchState(false)
        PhaseWrappingBranch_I = controllib.chart.NicholsPlot.createDefaultOptions().PhaseWrappingBranch

        PhaseMatchingEnabled_I = matlab.lang.OnOffSwitchState(false)
        PhaseMatchingFrequency_I = controllib.chart.NicholsPlot.createDefaultOptions().PhaseWrappingBranch
        PhaseMatchingValue_I = controllib.chart.NicholsPlot.createDefaultOptions().PhaseMatchingValue

        MinimumGainEnabled_I = matlab.lang.OnOffSwitchState(false)
        MinimumGainValue_I = controllib.chart.NicholsPlot.createDefaultOptions().MagLowerLim
    end

    properties (Access = protected,Transient,NonCopyable)
        MagnitudeResponseWidget
        PhaseResponseWidget

        ShowMenu
        ShowSubMenu
        NormalizeMenu

        SpecifyFrequencyDialog
        SpecifyFrequencyMenu
    end

    %% Events
    events
        FrequencyChanged
    end

    %% Constructor/destructor
    methods
        function this = NicholsPlot(nicholsPlotInputs,rowColumnPlotArguments)
            arguments
                nicholsPlotInputs.Options (1,1) plotopts.NicholsOptions = controllib.chart.NicholsPlot.createDefaultOptions()
                rowColumnPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            rowColumnPlotArguments = namedargs2cell(rowColumnPlotArguments);
            this@controllib.chart.internal.foundation.RowColumnPlot(rowColumnPlotArguments{:},...
                Options=nicholsPlotInputs.Options);
        end

        function delete(this)
            delete(this.SpecifyFrequencyDialog);
            delete@controllib.chart.internal.foundation.RowColumnPlot(this);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,frequency,optionalInputs,optionalStyleInputs)
            % addResponse adds the nichols response to the chart
            %
            %   addResponse(h,sys)
            %       adds the nichols responses of "sys" to the chart "h"
            %
            %   addResponse(h,sys,w)
            %       w               [] (default) | vector | cell array
            %
            %   addResponse(h,____,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.NicholsPlot
                model DynamicSystem
                frequency = []
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create NicholsResponse
            % Get next name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create NicholsResponse
            newResponse = createResponse_(this,model,name,frequency);
            if ~isempty(newResponse.DataException) && ~strcmp(this.ResponseDataExceptionMessage,"none")
               if strcmp(this.ResponseDataExceptionMessage,"error")
                   throw(newResponse.DataException);
               else % warning
                   warning(newResponse.DataException.identifier,newResponse.DataException.message);
               end
            end

            % Apply user specified style values to style object
            controllib.chart.internal.options.AddResponseStyleOptionalInputs.applyToStyle(...
                newResponse.Style,optionalStyleInputs);

            % Add response to chart
            registerResponse(this,newResponse);
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.MagUnits = char(this.MagnitudeUnit);
                options.PhaseUnits = char(this.PhaseUnit);

                options.PhaseWrappingBranch = this.PhaseWrappingBranch;
                options.PhaseWrapping = char(this.PhaseWrappingEnabled);
                options.PhaseMatchingFreq = this.PhaseMatchingFrequency;
                options.PhaseMatchingValue = this.PhaseMatchingValue;
                options.PhaseMatching = char(this.PhaseWrappingEnabled);
                if this.MinimumGainEnabled
                    options.MagLowerLimMode = 'manual';
                else
                    options.MagLowerLimMode = 'auto';
                end
                options.MagLowerLim = this.MinimumGainValue;
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'MagUnits'
                        options = char(this.MagnitudeUnit);
                    case 'PhaseUnits'
                        options = char(this.PhaseUnit);
                    case 'PhaseWrappingBranch'
                        options = this.PhaseWrappingBranch;
                    case 'PhaseWrapping'
                        options = char(this.PhaseWrappingEnabled);
                    case 'PhaseMatchingFreq'
                        options = this.PhaseMatchingFrequency;
                    case 'PhaseMatchingValue'
                        options = this.PhaseMatchingValue;
                    case 'PhaseMatching'
                        options = char(this.PhaseWrappingEnabled);
                    case 'MagLowerLimMode'
                        if this.MinimumGainEnabled
                            options = 'manual';
                        else
                            options = 'auto';
                        end
                    case 'MagLowerLim'
                        options = this.MinimumGainValue;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                options (1,1) plotopts.NicholsOptions = getoptions(this)
                nameValueInputs.?plotopts.NicholsOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Frequency Unit
            if strcmp(options.FreqUnits,'auto')
                if isempty(this.Responses)
                    this.FrequencyUnit = "rad/s";
                else
                    this.FrequencyUnit = this.Responses(1).FrequencyUnit;
                end
            else
                this.FrequencyUnit = options.FreqUnits;
            end

            % Magnitude Unit
            this.MagnitudeUnit = options.MagUnits;

            % Phase Unit
            this.PhaseUnit = options.PhaseUnits;

            % Phase wrapping
            this.PhaseWrappingBranch = options.PhaseWrappingBranch;
            this.PhaseWrappingEnabled = options.PhaseWrapping;

            % Phase Matching
            this.PhaseMatchingFrequency = options.PhaseMatchingFreq;
            this.PhaseMatchingValue = options.PhaseMatchingValue;
            this.PhaseMatchingEnabled = options.PhaseMatching;

            % Min Gain
            this.MinimumGainEnabled = strcmp(options.MagLowerLimMode,'manual');
            this.MinimumGainValue = options.MagLowerLim;            

            % Call base class
            setoptions@controllib.chart.internal.foundation.RowColumnPlot(this,options);
        end
    end

    %% Get/Set methods
    methods
        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            frequencyConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                this.FrequencyUnit,FrequencyUnit);

            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyUnits = FrequencyUnit;
            end

            this.PhaseMatchingFrequency = frequencyConversionFcn(this.PhaseMatchingFrequency);
        end

        % MagnitudeUnit
        function MagnitudeUnit = get.MagnitudeUnit(this)
            MagnitudeUnit = this.MagnitudeUnit_I;
        end

        function set.MagnitudeUnit(this,MagnitudeUnit)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                MagnitudeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidMagnitudeUnit}
            end
            if MagnitudeUnit == "dB"
                this.MagnitudeScale = "linear";
            end
            magnitudeConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(...
                this.MagnitudeUnit,MagnitudeUnit);

            this.MagnitudeUnit_I = MagnitudeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeUnit = MagnitudeUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeUnits = MagnitudeUnit;
            end

            this.MinimumGainValue = magnitudeConversionFcn(this.MinimumGainValue);

            % Update Requirements
            for k = 1:length(this.Requirements)
                this.Requirements(k).setDisplayUnits('yunits',char(MagnitudeUnit));
                update(this.Requirements(k));
            end

            if ~isempty(this.View) && isvalid(this.View)
                disableListeners(this.View,'AxesGridXLimitsChanged');
                if this.AxesStyle.GridVisible
                    updateFocusWithRequirements(this);
                    refreshGrid(this.View);
                else
                    updateFocusWithRequirements(this);
                end
                enableListeners(this.View,'AxesGridXLimitsChanged');
            end
        end

        % PhaseUnit
        function PhaseUnit = get.PhaseUnit(this)
            PhaseUnit = this.PhaseUnit_I;
        end

        function set.PhaseUnit(this,PhaseUnit)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseUnit (1,1) string {controllib.chart.internal.utils.mustBeValidPhaseUnit}
            end
            phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                this.PhaseUnit,PhaseUnit);

            this.PhaseUnit_I = PhaseUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseUnit = PhaseUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.PhaseUnits = PhaseUnit;
            end

            this.PhaseMatchingValue = phaseConversionFcn(this.PhaseMatchingValue);
            this.PhaseWrappingBranch = phaseConversionFcn(this.PhaseWrappingBranch);

            % Update Requirements
            for k = 1:length(this.Requirements)
                this.Requirements(k).setDisplayUnits('xunits',char(PhaseUnit));
                update(this.Requirements(k));
            end

            if ~isempty(this.View) && isvalid(this.View)
                disableListeners(this.View,'AxesGridXLimitsChanged');
                if this.AxesStyle.GridVisible
                    updateFocusWithRequirements(this);
                    refreshGrid(this.View);
                else
                    updateFocusWithRequirements(this);
                end
                enableListeners(this.View,'AxesGridXLimitsChanged');
            end
        end

        % Magnitude scale
        function MagnitudeScale = get.MagnitudeScale(this)
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            if this.MagnitudeUnit == "dB" && MagnitudeScale == "log"
                error(message('Controllib:plots:magUnitScaleIncompatible'));
            end
            this.MagnitudeScale_I = MagnitudeScale;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeScale = MagnitudeScale;
                updateFocus(this.View);
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeScale = MagnitudeScale;
            end
        end

        % PhaseWrappingEnabled
        function PhaseWrappingEnabled = get.PhaseWrappingEnabled(this)
            PhaseWrappingEnabled = this.PhaseWrappingEnabled_I;
        end

        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseWrappingEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.PhaseWrappingEnabled_I = PhaseWrappingEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseWrappingEnabled = PhaseWrappingEnabled;
                updateFocus(this.View);
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseWrappingBranch
        function PhaseWrappingBranch = get.PhaseWrappingBranch(this)
            PhaseWrappingBranch = this.PhaseWrappingBranch_I;
        end

        function set.PhaseWrappingBranch(this,PhaseWrappingBranch)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseWrappingBranch (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            % Update View
            this.PhaseWrappingBranch_I = PhaseWrappingBranch;

            for ii = 1:length(this.Responses)
                phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                    this.PhaseUnit,this.Responses(ii).PhaseUnit);
                this.Responses(ii).PhaseWrappingBranch = phaseConversionFcn(PhaseWrappingBranch);
            end
            
            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingEnabled
        function PhaseMatchingEnabled = get.PhaseMatchingEnabled(this)
            PhaseMatchingEnabled = this.PhaseMatchingEnabled_I;
        end

        function set.PhaseMatchingEnabled(this,PhaseMatchingEnabled)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseMatchingEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.PhaseMatchingEnabled_I = PhaseMatchingEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseMatchingEnabled = PhaseMatchingEnabled;
                updateFocus(this.View);
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingFrequency
        function PhaseMatchingFrequency = get.PhaseMatchingFrequency(this)
            PhaseMatchingFrequency = this.PhaseMatchingFrequency_I;
        end

        function set.PhaseMatchingFrequency(this,PhaseMatchingFrequency)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseMatchingFrequency (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            this.PhaseMatchingFrequency_I = PhaseMatchingFrequency;

            for ii = 1:length(this.Responses)
                freqConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                    this.FrequencyUnit,this.Responses(ii).FrequencyUnit);
                this.Responses(ii).PhaseMatchingFrequency = freqConversionFcn(PhaseMatchingFrequency);
                notify(this.Responses(ii),'ResponseChanged');
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingValue
        function PhaseMatchingValue = get.PhaseMatchingValue(this)
            PhaseMatchingValue = this.PhaseMatchingValue_I;
        end

        function set.PhaseMatchingValue(this,PhaseMatchingValue)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                PhaseMatchingValue (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            this.PhaseMatchingValue_I = PhaseMatchingValue;

            for ii = 1:length(this.Responses)
                phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                    this.PhaseUnit,this.Responses(ii).PhaseUnit);
                this.Responses(ii).PhaseMatchingValue = phaseConversionFcn(PhaseMatchingValue);
                notify(this.Responses(ii),'ResponseChanged');
            end

            updatePhaseResponseWidget(this);
        end

        % MinimumGainEnabled
        function MinimumGainEnabled = get.MinimumGainEnabled(this)
            MinimumGainEnabled = this.MinimumGainEnabled_I;
        end

        function set.MinimumGainEnabled(this,MinimumGainEnabled)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                MinimumGainEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.MinimumGainEnabled_I = MinimumGainEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MinimumGainEnabled = MinimumGainEnabled;
                updateFocus(this.View);
            end

            updateMagnitudeResponseWidget(this);
        end

        % MinimumGainValue
        function MinimumGainValue = get.MinimumGainValue(this)
            MinimumGainValue = this.MinimumGainValue_I;
        end

        function set.MinimumGainValue(this,MinimumGainValue)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                MinimumGainValue (1,1) double {mustBeReal,mustBeNonNan}
            end
            this.MinimumGainValue_I = MinimumGainValue;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MinimumGainValue = MinimumGainValue;
                updateFocus(this.View);
            end

            updateMagnitudeResponseWidget(this);
        end

    end

    %% Protected methods
    methods (Access = protected)    
        function initialize(this)
            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.Type = 'nichols';
            this.SynchronizeResponseUpdates = true;
            this.XLimitsSharing = "column";
            this.XLimits = repmat({[1 10]},1,this.NInputs);
            this.XLimitsMode =  repmat({"auto"},1,this.NInputs);
            build(this);
        end
        
        function response = createResponse_(~,sys,name,freq)
            response = controllib.chart.response.NicholsResponse(...
                controllib.chart.internal.utils.ModelSource(sys),...
                Name=name,...
                Frequency=freq);
        end

        function view = createView_(this)
            % Create View
            view = controllib.chart.internal.view.axes.NicholsAxesView(this);
        end

        function tf = hasCustomGrid(this)
            tf = this.NInputs == 1 && this.NOutputs == 1;
        end

        function updateGridSize(this,newResponses)
            arguments
                this (1,1) controllib.chart.NicholsPlot
                newResponses (:,1) controllib.chart.internal.foundation.BaseResponse = controllib.chart.internal.foundation.BaseResponse.empty
            end
            updateGridSize@controllib.chart.internal.foundation.RowColumnPlot(this,newResponses);
            updateForCustomGrid(this.AxesStyle);
        end

        function connectView(this)
            connectView@controllib.chart.internal.foundation.RowColumnPlot(this);

            % Grid
            L = addlistener(this.View,"GridUpdated",...
                @(es,ed) cbGridUpdated(this));
            registerListeners(this,L,"GridUpdatedInAxesView");

            function cbGridUpdated(this)
                updateFocus(this.View);
            end
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.RowColumnPlot(this);
            
            this.SpecifyFrequencyMenu = uimenu(this.ContextMenu,...
                Text=[getString(message('Controllib:plots:strSpecifyFrequency')),'...'],...
                Tag="specifyfrequency",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyFrequencyDialog(this));
            addMenu(this,this.SpecifyFrequencyMenu,Above='propertyeditor',CreateNewSection=false);
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(~,charType)
            switch charType
                case "FrequencyPeakResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strPeakResponse')),...
                        Visible=false);
                case "AllStabilityMargins"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strAllStabilityMargins')),...
                        Visible=false);
                case "MinimumStabilityMargins"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strMinimumStabilityMargins')),...
                        Visible=false);
            end
        end

        function applyCharacteristicOptionsToResponse(this,response)
            freqConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                this.FrequencyUnit,response.FrequencyUnit);
            phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                this.PhaseUnit,response.PhaseUnit);
            response.PhaseWrappingBranch = phaseConversionFcn(this.PhaseWrappingBranch);
            response.PhaseMatchingFrequency = freqConversionFcn(this.PhaseMatchingFrequency);
            response.PhaseMatchingValue = phaseConversionFcn(this.PhaseMatchingValue);
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits',...
                'MagnitudeUnits','PhaseUnits','MagnitudeScale');
            % Remove 'auto' from frequency unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];

            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.PhaseUnits = this.PhaseUnit;
            this.UnitsWidget.MagnitudeUnits = this.MagnitudeUnit;
            this.UnitsWidget.MagnitudeScale = this.MagnitudeScale;

            % Add listeners for widget to data
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeScale','PostSet',...
                @(es,ed) cbMagnitudeScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'PhaseUnits','PostSet',...
                @(es,ed) cbPhaseUnitChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertEditor",...
                "MagnitudeUnitChangedInPropertyEditor","MagnitudeScaleChangedInPropertyEditor",...
                "PhaseUnitChangedInPropertyEditor"]);

            % Local callback functions
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbMagnitudeUnitChangedInPropertyEditor(this,ed)
                this.MagnitudeUnit = ed.AffectedObject.MagnitudeUnits;
            end

            function cbMagnitudeScaleChangedInPropertyEditor(this,ed)
                this.MagnitudeScale = ed.AffectedObject.MagnitudeScale;
            end

            function cbPhaseUnitChangedInPropertyEditor(this,ed)
                this.PhaseUnit = ed.AffectedObject.PhaseUnits;
            end
        end

        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit','fit'},ColumnWidth={'1x'},Padding=0);

            % Build widgets if needed
            buildMagnitudeResponseWidget(this);
            buildPhaseResponseWidget(this);

            w = getWidget(this.MagnitudeResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 1;
            w.Layout.Column = 1;

            w = getWidget(this.PhaseResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 2;
            w.Layout.Column = 1;

            % Add layout/widget to tab
            addTab(this.PropertyEditorDialog,getString(message('Controllib:gui:strOptions')),layout);
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["FrequencyUnit","PhaseUnit",...
                "PhaseWrappingEnabled","PhaseWrappingBranch","PhaseMatchingEnabled",...
                "PhaseMatchingFrequency","PhaseMatchingValue","MinimumGainEnabled",...
                "MinimumGainValue"];
        end
    end

    methods (Access = private)
        function buildMagnitudeResponseWidget(this)
            % Create MagnitudeResponseContainer
            this.MagnitudeResponseWidget = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();

            updateMagnitudeResponseWidget(this);

            % Add listeners
            registerListeners(this,...
                addlistener(this.MagnitudeResponseWidget,'MinGainLimit','PostSet',...
                @(es,ed) set(this,'MinimumGainEnabled',ed.AffectedObject.MinGainLimit.Enable,...
                'MinimumGainValue',ed.AffectedObject.MinGainLimit.MinGain)),...
                'MinGainLimitChangedInPropertyEditor');
        end

        function updateMagnitudeResponseWidget(this)
            if ~isempty(this.MagnitudeResponseWidget) && isvalid(this.MagnitudeResponseWidget)
                % Set units
                this.MagnitudeResponseWidget.MagnitudeUnits = this.MagnitudeUnit;
                % Set minimum gain values
                this.MagnitudeResponseWidget.MinGainLimit.Enable = char(this.MinimumGainEnabled);
                this.MagnitudeResponseWidget.MinGainLimit.MinGain = this.MinimumGainValue;
            end
        end

        function buildPhaseResponseWidget(this)
            % Create PhaseResponseContainer
            this.PhaseResponseWidget = controllib.widget.internal.cstprefs.PhaseResponseContainer();

            updatePhaseResponseWidget(this);

            % Add listeners
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'UnwrapPhase','PostSet',...
                @(es,ed) set(this,'PhaseWrappingEnabled',~strcmp(ed.AffectedObject.UnwrapPhase,'on'))),...
                'PhaseWrappingEnabledChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'PhaseWrappingBranch','PostSet',...
                @(es,ed) set(this,'PhaseWrappingBranch',ed.AffectedObject.PhaseWrappingBranch)),...
                'PhaseWrappingBranchChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'ComparePhase','PostSet',...
                @(es,ed) set(this,'PhaseMatchingEnabled',ed.AffectedObject.ComparePhase.Enable,...
                'PhaseMatchingFrequency',ed.AffectedObject.ComparePhase.Freq,...
                'PhaseMatchingValue',ed.AffectedObject.ComparePhase.Phase)),...
                'ComparePhaseChangedInPropertyEditor');
        end

        function updatePhaseResponseWidget(this)
            if ~isempty(this.PhaseResponseWidget) && isvalid(this.PhaseResponseWidget)
                % Set units
                this.PhaseResponseWidget.PhaseUnits = this.PhaseUnit;
                this.PhaseResponseWidget.FrequencyUnits = this.FrequencyUnit;
                % Set phase wrapping values
                this.PhaseResponseWidget.UnwrapPhase = char(~this.PhaseWrappingEnabled);
                this.PhaseResponseWidget.PhaseWrappingBranch = this.PhaseWrappingBranch;
                % Set phase matching values
                this.PhaseResponseWidget.ComparePhase.Enable = char(this.PhaseMatchingEnabled);
                this.PhaseResponseWidget.ComparePhase.Freq = this.PhaseMatchingFrequency;
                this.PhaseResponseWidget.ComparePhase.Phase = this.PhaseMatchingValue;
            end
        end

        function openSpecifyFrequencyDialog(this)
            if any(arrayfun(@(x) issparse(x.Model),this.Responses))
                enableAuto = false;
                enableFrequencyRange = false;
                enableVector = true;
            else
                enableAuto = true;
                enableFrequencyRange = true;
                enableVector = true;
            end
            if isempty(this.SpecifyFrequencyDialog) || ~isvalid(this.SpecifyFrequencyDialog)
                if isempty(this.Responses)
                    f = [];
                else
                    f = this.Responses(end).SourceData.FrequencySpec;
                end
                this.SpecifyFrequencyDialog = controllib.chart.internal.widget.FrequencyEditorDialog(...
                    EnableAuto=enableAuto,EnableRange=enableFrequencyRange,EnableVector=enableVector,...
                    Frequency=f,FrequencyUnits=this.FrequencyUnit);
                this.SpecifyFrequencyDialog.FrequencyChangedFcn = @(es,ed) cbFrequencyChanged(this,ed);
            end
            this.SpecifyFrequencyDialog.EnableAuto = enableAuto;
            this.SpecifyFrequencyDialog.EnableRange = enableFrequencyRange;            
            show(this.SpecifyFrequencyDialog);

            function cbFrequencyChanged(this,ed)
                for k = 1:length(this.Responses)
                    if ~isempty(ed.Data.Frequency)
                        cf = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                            ed.Data.FrequencyUnits,this.Responses(k).FrequencyUnit);
                        if iscell(ed.Data.Frequency)
                            this.Responses(k).SourceData.FrequencySpec = {cf(ed.Data.Frequency{1}), cf(ed.Data.Frequency{2})};
                        else
                            this.Responses(k).SourceData.FrequencySpec = cf(ed.Data.Frequency);
                        end
                    else
                        this.Responses(k).SourceData.FrequencySpec = ed.Data.Frequency;
                    end
                end
                ev = controllib.chart.internal.utils.GenericEventData(ed.Data.Frequency);
                notify(this,'FrequencyChanged',ev);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = nicholsoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function list = getRequirementList(this) %#ok<MANU>
            list.Type = 'PhaseMargin';
            list.Label = getString(message('Controllib:graphicalrequirements:lblPhaseMargin'));
            list.Class = 'editconstr.GainPhaseMargin';
            list.DataClass = 'srorequirement.gainphasemargin';

            list(2).Type = 'GainMargin';
            list(2).Label = getString(message('Controllib:graphicalrequirements:lblGainMargin'));
            list(2).Class = 'editconstr.GainPhaseMargin';
            list(2).DataClass = 'srorequirement.gainphasemargin';

            list(3).Type = 'CLPeakGain';
            list(3).Label = getString(message('Controllib:graphicalrequirements:lblClosedLoopPeakGain'));
            list(3).Class = 'editconstr.NicholsPeak';
            list(3).DataClass = 'srorequirement.nicholspeak';

            list(4).Type = 'GPRequirement';
            list(4).Label = getString(message('Controllib:graphicalrequirements:lblGainPhaseRequirement'));
            list(4).Class = 'editconstr.NicholsLocation';
            list(4).DataClass = 'srorequirement.nicholslocation';
        end

        function newConstraint = getNewConstraint(this,type,currentConstraint)
            list = getRequirementList(this);
            type = localCheckType(type,list);
            typeIdx = strcmp(type,{list.Type});
            constraintClass = list(typeIdx).Class;
            dataClass = list(typeIdx).DataClass;

            switch type
                case 'PhaseMargin'
                    constraintType = 'phase';
                case 'GainMargin'
                    constraintType = 'gain';
                case 'CLPeakGain'
                    constraintType = 'upper';
                case 'GPRequirement'
                    constraintType = 'lower';
            end

            % Create instance
            if nargin > 2 && isa(currentConstraint,constraintClass)
                % Use current constraint and update type
                newConstraint = currentConstraint;
                newConstraint.Requirement.setData('type',constraintType);
            else
                % Create new constraint
                requirementData = feval(dataClass);
                requirementData.setData('type',constraintType);
                newConstraint = feval(constraintClass,requirementData);
                newConstraint.setDisplayUnits('xunits',char(this.PhaseUnit));
                newConstraint.setDisplayUnits('yunits',char(this.MagnitudeUnit));
            end

            function kOut = localCheckType(kIn,list)
                %Helper function to check keyword is correct, mainly needed for backwards
                %compatibility with old saved constraints

                if any(strcmp(kIn,{list.Type}))
                    %Quick return is already an identifier
                    kOut = kIn;
                    return
                end

                %Handle case where gainphasemargin requirement is one object
                if strcmp(kIn,'GainPhaseMargin')
                    kOut = 'PhaseMargin';
                    return
                end

                %Now check display strings for matching keyword, may need to translate kIn
                %from an earlier saved version
                strEng = {...
                    'Phase margin'; ...
                    'Gain margin'; ...
                    'Closed-Loop peak gain'; ...
                    'Gain-Phase requirement'};
                strTr = {list.Label};
                idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
                if any(idx)
                    kOut = list(idx).Type;
                else
                    kOut = [];
                end
            end
        end
    
        function widgets = qeGetPropertyEditorWidgets(this)
            widgets = qeGetPropertyEditorWidgets@controllib.chart.internal.foundation.RowColumnPlot(this);
            widgets.MagnitudeResponseWidget = this.MagnitudeResponseWidget;
            widgets.PhaseResponseWidget = this.PhaseResponseWidget;
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end
    end
end