classdef DiskMarginPlot < controllib.chart.internal.foundation.AbstractPlot
    % DiskMarginPlot

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        FrequencyUnit
        MagnitudeUnit
        PhaseUnit

        FrequencyScale
        MagnitudeScale
    end

    properties (GetAccess=protected,SetAccess=private)
        FrequencyUnit_I = "rad/s"
        MagnitudeUnit_I = "dB"
        PhaseUnit_I = "deg"
        FrequencyScale_I = "log"
        MagnitudeScale_I = "linear"
    end

    properties(Access = protected,Transient,NonCopyable)
        SpecifyFrequencyDialog
        SpecifyFrequencyMenu
    end

    %% Events
    events
        FrequencyChanged
    end

    %% Constructor/destructor
    methods
        function this = DiskMarginPlot(diskMarginPlotInputs,abstractPlotArguments)
            arguments
                diskMarginPlotInputs.Options (1,1) plotopts.DiskMarginOptions = controllib.chart.DiskMarginPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.AbstractPlot(abstractPlotArguments{:},...
                Options=diskMarginPlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.AbstractPlot(this);
            delete(this.SpecifyFrequencyDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,models,optionalInputs,optionalStyleInputs)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
            end

            arguments(Repeating)
                models DynamicSystem
            end

            arguments
                optionalInputs.Skew (1,1) double = 0
                optionalInputs.Frequency = []
                optionalInputs.Name (:,1) string = repmat("",length(models),1)
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if all(strcmp(optionalInputs.Name,""))
                for k = 1:length(models)
                    optionalInputs.Name(k) = string(inputname(k+1));
                end
            end

            % Create DiskMarginResponse
            for k = 1:length(models)
                % Get next and name
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end
                % Create DiskMarginResponse
                newResponse = createResponse_(this,models{k},name,optionalInputs.Skew,...
                    optionalInputs.Frequency);
                if ~isempty(newResponse.DataException)
                    throw(newResponse.DataException);
                end

                % Apply user specified style values to style object
                controllib.chart.internal.options.AddResponseStyleOptionalInputs.applyToStyle(...
                    newResponse.Style,optionalStyleInputs);

                % Add response to chart
                registerResponse(this,newResponse);
            end
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.MagUnits = char(this.MagnitudeUnit);
                options.FreqScale = char(this.FrequencyScale);
                options.MagScale = char(this.MagnitudeScale);
                options.PhaseUnits = char(this.PhaseUnit);
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'MagUnits'
                        options = char(this.MagnitudeUnit);
                    case 'FreqScale'
                        options = char(this.FrequencyScale);
                    case 'MagScale'
                        options = char(this.MagnitudeScale);
                    case 'PhaseUnits'
                        options = char(this.PhaseUnit);
                    case {'OutputLabels','InputLabels','OutputVisible','InputVisible','IOGrouping'}
                        options = this.createDefaultOptions().(propertyName);
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                options (1,1) plotopts.DiskMarginOptions = getoptions(this)
                nameValueInputs.?plotopts.DiskMarginOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Frequency Unit & Scale
            if strcmp(options.FreqUnits,'auto')
                if isempty(this.Responses)
                    this.FrequencyUnit = "rad/s";
                else
                    this.FrequencyUnit = this.Responses(1).FrequencyUnit;
                end
            else
                this.FrequencyUnit = options.FreqUnits;
            end
            this.FrequencyScale = options.FreqScale;

            % Magnitude Unit & Scale
            this.MagnitudeUnit = options.MagUnits;
            try %#ok<TRYNC>
                this.MagnitudeScale = options.MagScale;
            end

            % Phase Unit
            this.PhaseUnit = options.PhaseUnits;

            % "Fix" options limits if scalar
            sz = getVisibleAxesSize(this);
            if isscalar(options.YLimMode)
                options.YLimMode = repmat(options.YLimMode,sz(1),sz(2));
            end
            if isscalar(options.YLim)
                yLimMode = options.YLimMode;
                options.YLim = repmat(options.YLim,sz(1),sz(2));
                options.YLimMode = yLimMode;
            end

            % Call base class
            setoptions@controllib.chart.internal.foundation.AbstractPlot(this,options);
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
                this (1,1) controllib.chart.DiskMarginPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyUnits = FrequencyUnit;
            end
        end

        % MagnitudeUnit
        function MagnitudeUnit = get.MagnitudeUnit(this)
            MagnitudeUnit = this.MagnitudeUnit_I;
        end

        function set.MagnitudeUnit(this,MagnitudeUnit)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                MagnitudeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidMagnitudeUnit}
            end
            if MagnitudeUnit == "dB"
                this.MagnitudeScale = "linear";
            end
            this.MagnitudeUnit_I = MagnitudeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeUnit = MagnitudeUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeUnits = MagnitudeUnit;
            end
        end

        % PhaseUnit
        function PhaseUnit = get.PhaseUnit(this)
            PhaseUnit = this.PhaseUnit_I;
        end

        function set.PhaseUnit(this,PhaseUnit)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                PhaseUnit (1,1) string {controllib.chart.internal.utils.mustBeValidPhaseUnit}
            end
            this.PhaseUnit_I = PhaseUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseUnit = PhaseUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.PhaseUnits = PhaseUnit;
            end
        end

        % FrequencyScale
        function FrequencyScale = get.FrequencyScale(this)
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            this.FrequencyScale_I = FrequencyScale;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyScale = FrequencyScale;
                updateFocus(this.View);
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyScale = FrequencyScale;
            end
        end

        % MagnitudeScale
        function MagnitudeScale = get.MagnitudeScale(this)
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
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
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.AbstractPlot(this);
            this.Type = 'diskmargin';
            this.SynchronizeResponseUpdates = true;
            this.YLimits = {[1 10];[1 10]};
            this.YLimitsMode = {"auto";"auto"};
            this.YLimitsFocus = {[1 10];[1 10]};
            this.YLimitsFocusFromResponses = true;
            build(this);
        end

        function response = createResponse_(~,model,name,skew,freq) 
            response = controllib.chart.response.DiskMarginResponse(model,...
                Name=name,...
                Skew=skew,...
                Frequency=freq);
        end

        function response = createSigmaResponse_(~,model,name,skew,freq,isStable) 
            response = controllib.chart.response.internal.DiskMarginSigmaResponse(model,...
                Name=name,...
                Skew=skew,...
                Frequency=freq);
            response.SourceData.IsStable = isStable;
        end

        function response = createBoundResponse_(~,name,boundType,gm,pm,ts,focus) 
            response = controllib.chart.response.internal.DiskMarginBoundResponse(...
                BoundType=boundType,...
                GM=gm,...
                PM=pm,...
                Ts=ts,...
                Focus=focus,...
                Name=name);
        end

        function view = createView_(this)
            % Create View
            view = controllib.chart.internal.view.axes.DiskMarginAxesView(this);
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.AbstractPlot(this);
            
            this.SpecifyFrequencyMenu = uimenu(Parent=[],...
                Text=[getString(message('Controllib:plots:strSpecifyFrequency')),'...'],...
                Tag="specifyfrequency",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyFrequencyDialog(this));

            addMenu(this,this.SpecifyFrequencyMenu,Above="propertyeditor",CreateNewSection=false);
        end        

        %% Characteristics
        function cm = createCharacteristicOptions_(~,charType)
            switch charType
                case "DiskMarginMinimumResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strMinDiskMargin')),...
                        Visible=false);
            end
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(~)
            tags = "DiskMarginMinimumResponse";
            labels = string(getString(message('Controllib:plots:strMinDiskMargin')));
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            magConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(response.MagnitudeUnit,...
                this.MagnitudeUnit);
            for ka = 1:response.NResponses
                compute(data.DiskMarginMinimumResponse);

                isMinResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "DiskMarginMinimumResponse",magConversionFcn(data.DiskMarginMinimumResponse.Magnitude{ka}));
                arrayVisible(ka) = all(isMinResponseWithinBounds(:));
            end
            response.ArrayVisible = arrayVisible;
        end

        function limitNames = getLimitNamesForYLimitsWidget(this) %#ok<MANU>
            limitNames = string({getString(message('Controllib:plots:strMagnitude')),...
                getString(message('Controllib:plots:strPhase'))});
        end

        function cbYLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'YLimitsChangedInPropertyEditor');
            this.YLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    if limitsWidget.AutoScale
                        yLimMode = "auto";
                    else
                        yLimMode = "manual";
                    end

                    this.YLimitsMode = yLimMode;
                    limitsWidget.Limits = this.YLimits_I;
                case 'Limits'
                    this.YLimits = limitsWidget.Limits';
            end
            this.YLimitsWidget.Enable = true;
            updateYLimitsWidget(this);
            enableListeners(this,'YLimitsChangedInPropertyEditor');
        end

        function updateYLimitsWidget(this)
            if ~isempty(this.YLimitsWidget) && isvalid(this.YLimitsWidget) && this.YLimitsWidget.Enable
                setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                setLimits(this.YLimitsWidget,this.YLimits_I{2},1,2);
                isAuto = strcmp(this.YLimitsMode_I{1},"auto") && strcmp(this.YLimitsMode_I{2},"auto");
                setAutoScale(this.YLimitsWidget,isAuto);
            end
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits',...
                'MagnitudeUnits','PhaseUnits','FrequencyScale','MagnitudeScale');
            % Remove 'auto' from frequency unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];

            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.MagnitudeUnits = this.MagnitudeUnit;
            this.UnitsWidget.PhaseUnits = this.PhaseUnit;
            this.UnitsWidget.FrequencyScale = this.FrequencyScale;
            this.UnitsWidget.MagnitudeScale = this.MagnitudeScale;

            % Add listeners for widget to data
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'FrequencyScale','PostSet',...
                @(es,ed) cbFrequencyScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeScale','PostSet',...
                @(es,ed) cbMagnitudeScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'PhaseUnits','PostSet',...
                @(es,ed) cbPhaseUnitChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertEditor",...
                "FrequencyScaleChangedInPropertyEditor","MagnitudeUnitChangedInPropertyEditor",...
                "MagnitudeScaleChangedInPropertyEditor","PhaseUnitChangedInPropertyEditor"]);

            % Local callback functions
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbFrequencyScaleChangedInPropertyEditor(this,ed)
                this.FrequencyScale = ed.AffectedObject.FrequencyScale;
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

        function names = getCustomPropertyGroupNames(this)
            names = ["FrequencyUnit","FrequencyScale","MagnitudeUnit","MagnitudeScale","PhaseUnit"];
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function sz = getPropertyDialogSize()
            sz = [430 410];
        end

        function n = getNumYLabels()
            n = 2;
        end

        
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = plotopts.DiskMarginOptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        % Used by TuningGoal.Margins
        function addSigmaResponse(this,models,optionalInputs,optionalStyleInputs)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
            end

            arguments(Repeating)
                models DynamicSystem {mustBeNonempty}
            end

            arguments
                optionalInputs.IsStable = []
                optionalInputs.Skew (1,1) double = 0
                optionalInputs.Frequency = []
                optionalInputs.Name (:,1) string = repmat("",length(models),1)
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if all(strcmp(optionalInputs.Name,""))
                for k = 1:length(models)
                    optionalInputs.Name(k) = string(inputname(k+1));
                end
            end

            % Create DiskMarginSigmaResponse
            for k = 1:length(models)
                % Get next and name
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end
                % Create DiskMarginSigmaResponse
                newResponse = createSigmaResponse_(this,models{k},name,optionalInputs.Skew,...
                    optionalInputs.Frequency,optionalInputs.IsStable);
                if ~isempty(newResponse.DataException)
                    throw(newResponse.DataException);
                end

                % Apply user specified style values to style object
                controllib.chart.internal.options.AddResponseStyleOptionalInputs.applyToStyle(...
                    newResponse.Style,optionalStyleInputs);

                % Add response to chart
                registerResponse(this,newResponse);
            end
        end

        function addBoundResponse(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.DiskMarginPlot
                optionalInputs.BoundType (1,1) string = "lower"
                optionalInputs.Focus (1,2) double = [0 Inf]
                optionalInputs.GM (1,1) double = 7.6
                optionalInputs.PM (1,1) double = 45
                optionalInputs.Ts (1,1) double = 0
                optionalInputs.Name (1,1) string = ""
                optionalInputs.FaceColor = []
                optionalInputs.EdgeColor = []
                optionalInputs.FaceAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.EdgeAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.LineStyle (1,1) string = ""
                optionalInputs.MarkerStyle (1,1) string = ""
                optionalInputs.LineWidth double {mustBeScalarOrEmpty} = []
                optionalInputs.MarkerSize double {mustBeScalarOrEmpty} = []
            end

            % Define Name
            if all(strcmp(optionalInputs.Name,""))
                optionalInputs.Name = string(inputname(2));
            end

            % Get next and name
            if isempty(optionalInputs.Name) || optionalInputs.Name == ""
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create DiskMarginBoundResponse
            newResponse = createBoundResponse_(this,name,optionalInputs.BoundType,...
                optionalInputs.GM,optionalInputs.PM,optionalInputs.Ts,...
                optionalInputs.Focus);
            if ~isempty(newResponse.DataException)
                throw(newResponse.DataException);
            end

            if ~isempty(optionalInputs.FaceColor)
                newResponse.Style.FaceColor = optionalInputs.FaceColor;
            end

            if ~isempty(optionalInputs.EdgeColor)
                newResponse.Style.EdgeColor = optionalInputs.EdgeColor;
            end

            if ~isempty(optionalInputs.FaceAlpha)
                newResponse.Style.FaceAlpha = optionalInputs.FaceAlpha;
            end

            if ~isempty(optionalInputs.EdgeAlpha)
                newResponse.Style.EdgeAlpha = optionalInputs.EdgeAlpha;
            end

            if ~strcmp(optionalInputs.LineStyle,"")
                newResponse.Style.LineStyle = optionalInputs.LineStyle;
            end

            if ~strcmp(optionalInputs.MarkerStyle,"")
                newResponse.Style.MarkerStyle = optionalInputs.MarkerStyle;
            end

            if ~isempty(optionalInputs.LineWidth)
                newResponse.Style.LineWidth = optionalInputs.LineWidth;
            end

            if~isempty(optionalInputs.MarkerSize)
                newResponse.Style.MarkerSize = optionalInputs.MarkerSize;
            end

            % Add response to chart
            registerResponse(this,newResponse);
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end

        function sz = getVisibleAxesSize(~)
            sz = [2 1];
        end

        function sz = getYLimitsSize(~)
            sz = [2 1];
        end
    end
end