classdef SectorPlot < controllib.chart.internal.foundation.AbstractPlot
    % SIGMAPLOT     Construct a chart of singular value plots.
    %
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2)},Frequency=logspace(-2,2,100));

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        FrequencyUnit
        IndexUnit
        FrequencyScale
        IndexScale
    end

    properties (GetAccess=protected,SetAccess=private)
        FrequencyUnit_I = "rad/s"
        IndexUnit_I = "abs"
        FrequencyScale_I = "log"
        IndexScale_I = "log"
    end

    properties (Access=protected, Transient, NonCopyable)
        SpecifyFrequencyDialog
        SpecifyFrequencyMenu
    end

    %% Events
    events
        FrequencyChanged
    end

    %% Public methods
    methods
        function this = SectorPlot(sectorPlotInputs,abstractPlotArguments)
            arguments
                sectorPlotInputs.Options (1,1) plotopts.SectorPlotOptions = controllib.chart.SectorPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.AbstractPlot(abstractPlotArguments{:},...
                Options=sectorPlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.AbstractPlot(this);
            delete(this.SpecifyFrequencyDialog);
        end
    end

    %% Public methods
    methods        
        function addResponse(this,models,Q,optionalInputs,optionalStyleInputs)
            % ADDSYSTEM Add a singular value plot of a system to an existing SIGMAPLOT.
            %
            %   ADDSYSTEM(H,SYS) adds a singular value plot of SYS to existing sigmaplot H.
            %
            %   ADDSYSTEM(H,{SYS1,SYS2}) adds singular value plots of SYS1 and SYS2 to H.
            %
            %   ADDSYSTEM(H,{SYS1,SYS2},Name,Value)
            %       SystemName      cell array of system names
            %       Frequency       frequencies specified in radians/TimeUnit
            %       Color           1x3 array specifying RGB values
            %       LineStyle       string
            %       LineWidth       double

            arguments
                this (1,1) controllib.chart.SectorPlot
            end

            arguments(Repeating)
                models DynamicSystem
                Q
            end

            arguments
                optionalInputs.Frequency = []
                optionalInputs.Name (:,1) string = repmat("",length(models),1)
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name if optional input not used
            if all(strcmp(optionalInputs.Name,""))
                for k = 1:length(models)
                    optionalInputs.Name(k) = string(inputname(k+1));
                end
            end

            % Create SectorResponse
            for k = 1:length(models)
                % Get next name
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end

                % Create SectorResponse
                newResponse = createResponse_(this,models{k},Q{k},name,...
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
                this (1,1) controllib.chart.SectorPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.FreqScale = char(this.FrequencyScale);
                options.IndexScale = char(this.IndexScale);
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'FreqScale'
                        options = char(this.FrequencyScale);
                    case 'IndexScale'
                        options = char(this.IndexScale);
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
                this (1,1) controllib.chart.SectorPlot
                options (1,1) plotopts.SectorPlotOptions = getoptions(this)
                nameValueInputs.?plotopts.SectorPlotOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Set units
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

            try %#ok<TRYNC>
                this.IndexScale = options.IndexScale;
            end

            % Call base class for limits, style
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
                this (1,1) controllib.chart.SectorPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Update property editor
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyUnits = FrequencyUnit;
            end
        end

        % IndexUnit
        function IndexUnit = get.IndexUnit(this)
            IndexUnit = this.IndexUnit_I;
        end

        function set.IndexUnit(this,IndexUnit) 
            arguments
                this (1,1) controllib.chart.SectorPlot
                IndexUnit (1,1) string {controllib.chart.internal.utils.mustBeValidMagnitudeUnit}
            end     
            if IndexUnit == "dB"
                this.IndexScale = "linear";
            end
            this.IndexUnit_I = IndexUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeUnit = IndexUnit;
            end

            % Update property editor
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeUnits = IndexUnit;
            end
        end

        % Frequency scale
        function FrequencyScale = get.FrequencyScale(this)
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.SectorPlot
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

        % Magnitude scale
        function IndexScale = get.IndexScale(this)
            IndexScale = this.IndexScale_I;
        end

        function set.IndexScale(this,IndexScale)
            arguments
                this (1,1) controllib.chart.SectorPlot
                IndexScale (1,1) string {mustBeMember(IndexScale,["log","linear"])}
            end
            if this.IndexUnit == "dB" && IndexScale == "log"
                error(message('Controllib:plots:indexUnitScaleIncompatible'));
            end
            this.IndexScale_I = IndexScale;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.IndexScale = IndexScale;
                updateFocus(this.View);
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeScale = IndexScale;
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.AbstractPlot(this);
            this.Type = 'sector';
            this.SynchronizeResponseUpdates = true;            
            build(this);
        end

        function response = createResponse_(~,model,q,name,frequency)
            response = controllib.chart.response.SectorResponse(model,q,...
                Frequency=frequency,...
                Name=name);
        end

        function response = createBoundResponse_(~,model,name,boundType,focus,...
                frequency)
            response = controllib.chart.response.internal.SectorBoundResponse(model,...
                BoundType = boundType,...
                Focus = focus,....
                Frequency=frequency,...
                Name=name);
        end

        % View
        function view = createView_(this)
            % Create View
            view = controllib.chart.internal.view.axes.SectorAxesView(this);
        end

        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.AbstractPlot(this);
            
            this.SpecifyFrequencyMenu = uimenu(this.ContextMenu,...
                Text=[getString(message('Controllib:plots:strSpecifyFrequency')),'...'],...
                Tag="specifyfrequency",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyFrequencyDialog(this));

            addMenu(this,this.SpecifyFrequencyMenu,Above="propertyeditor",CreateNewSection=false);
        end

        % Characteristics
        function cm = createCharacteristicOptions_(~,charType)
            switch charType
                case "SectorWorstIndexResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strWorstIndex')),...
                        Visible=false);
            end
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(~)
            tags = "SectorWorstIndexResponse";
            labels = string(getString(message('Controllib:plots:strWorstIndex')));
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            magConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(response.IndexUnit,...
                this.IndexUnit);
            for ka = 1:response.NResponses
                compute(data.SectorWorstIndexResponse);
                
                isPeakResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "SectorWorstIndexResponse",magConversionFcn(data.SectorWorstIndexResponse.Value{ka}));
                arrayVisible(ka) = all(isPeakResponseWithinBounds(:));
            end
            response.ArrayVisible = arrayVisible;
        end

        % Property editor
        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer(...
                'FrequencyUnits','FrequencyScale','MagnitudeUnits','MagnitudeScale');

            % Remove 'auto' from frequency and time unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];

            % Set default units
            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.MagnitudeUnits = this.IndexUnit;
            this.UnitsWidget.FrequencyScale = this.FrequencyScale;
            this.UnitsWidget.MagnitudeScale = this.IndexScale;
            

            % Add listeners for widget to data 
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                    @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'FrequencyScale','PostSet',...
                    @(es,ed) cbFrequencyScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                    @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeScale','PostSet',...
                    @(es,ed) cbMagnitudeScaleChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertEditor",...
                "FrequencyScaleChangedInPropertyEditor","MagnitudeUnitChangedInPropertyEditor",...
                "MagnitudeScaleChangedInPropertyEditor"]);

            % Local callback functions
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbFrequencyScaleChangedInPropertyEditor(this,ed)
                this.FrequencyScale = ed.AffectedObject.FrequencyScale;
            end

            function cbMagnitudeUnitChangedInPropertyEditor(this,ed)
                this.IndexUnit = ed.AffectedObject.MagnitudeUnits;
            end

            function cbMagnitudeScaleChangedInPropertyEditor(this,ed)
                this.IndexScale = ed.AffectedObject.MagnitudeScale;
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
            names = ["FrequencyUnit","FrequencyScale","IndexUnit","IndexScale"];
        end
    end
    
    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = sectorplotoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function addBoundResponse(this,models,optionalInputs)
            % ADDBOUNDSYSTEM Add a singular value bounded plot of a system to an existing SIGMAPLOT.
            %
            %   ADDBOUNDSYSTEM(H,SYS) adds a singular value bounded plot of SYS to existing sigmaplot H.
            %
            %   ADDBOUNDSYSTEM(H,{SYS1,SYS2}) adds singular value bounded plots of SYS1 and SYS2 to H.
            %
            %   ADDBOUNDSYSTEM(H,{SYS1,SYS2},Name,Value)
            %       SystemName          cell array of system names
            %       BoundType           upper or lower bounded
            %       Focus               frequency range for bound
            %       UseFrequencyFocus   link XLimit to focus
            %       UseMagnitudeFocus   link YLimit to focus
            %       Frequency           frequencies specified in radians/TimeUnit
            %       Color               1x3 array specifying RGB values
            %       LineStyle           string
            %       LineWidth           double

            arguments
                this (1,1) controllib.chart.SectorPlot
            end

            arguments(Repeating)
                models DynamicSystem {mustBeNonempty}
            end

            arguments
                optionalInputs.BoundType (1,1) string = "upper"
                optionalInputs.Focus (1,2) double = [0 Inf]
                optionalInputs.Frequency = []
                optionalInputs.Name (:,1) string = repmat("",length(models),1)
                optionalInputs.FaceColor = []
                optionalInputs.EdgeColor = []
                optionalInputs.FaceAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.EdgeAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.LineStyle (1,1) string = ""
                optionalInputs.MarkerStyle (1,1) string = ""
                optionalInputs.LineWidth double {mustBeScalarOrEmpty} = []
                optionalInputs.MarkerSize double {mustBeScalarOrEmpty} = []
            end

            % Define Name if optional input not used
            if all(strcmp(optionalInputs.Name,""))
                for k = 1:length(models)
                    optionalInputs.Name(k) = string(inputname(k+1));
                end
            end

            % Create SectorBoundResponse
            for k = 1:length(models)
                % Get next name
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end

                % Create SectorBoundResponse
                newResponse = createBoundResponse_(this,models{k},name,optionalInputs.BoundType, ...
                    optionalInputs.Focus, optionalInputs.Frequency);
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
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end
    end
end