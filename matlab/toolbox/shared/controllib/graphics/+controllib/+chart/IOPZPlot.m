classdef IOPZPlot < controllib.chart.internal.foundation.RowColumnPlot & ...
                    controllib.chart.internal.foundation.MixInInputOutputPlot
    % Construct a StepPlot.
    %
    % h = controllib.chart.StepPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.StepPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.StepPlot("NInputs",2,"NOutputs",2,"InputLabels",["u1","u2"],"OutputLabels",["y1","y2"]);
    % h = controllib.chart.StepPlot("NInputs",2,"NOutputs",2);
    %
    %   Example:
    %
    %   sysG = rss(3,2,2);
    %   sysH = rss(3,2,2);
    %   f = figure;
    %   ax = axes(f);
    %   ax.Position = [0.1 0.1 0.5 0.5];
    %   h = controllib.chart.PZPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        TimeUnit
        FrequencyUnit
    end

    properties (Dependent,Access=private)
        NumberOfStandardDeviations
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeUnit_I = "seconds"
        FrequencyUnit_I = "rad/s"
        NumberOfStandardDeviations_I = controllib.chart.IOPZPlot.createDefaultOptions().ConfidenceRegionNumberSD
    end

    properties(Access = protected,Transient,NonCopyable)
        ConfidenceRegionWidget 
    end

    %% Constructor/destructor
    methods
        function this = IOPZPlot(iopzPlotInputs,inputOutputPlotArguments)
            arguments
                iopzPlotInputs.Options (1,1) plotopts.PZOptions = controllib.chart.IOPZPlot.createDefaultOptions()
                inputOutputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            inputOutputPlotArguments = namedargs2cell(inputOutputPlotArguments);
            this@controllib.chart.internal.foundation.RowColumnPlot(inputOutputPlotArguments{:},...
                Options=iopzPlotInputs.Options);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,optionalInputs)
            % addResponse adds the iopz response to the chart
            %
            %   addResponse(h,sys)
            %       adds the iopz responses of "sys" to the chart "h"
            %
            %   addResponse(h,sys,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.IOPZPlot
                model DynamicSystem
                optionalInputs.Name (:,1) string = repmat("",length(model),1)
                optionalInputs.Color = []
                optionalInputs.MarkerSize double {mustBeScalarOrEmpty} = []
                optionalInputs.LineWidth double {mustBeScalarOrEmpty} = []    
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

           % Create IOPZResponse
           % Get next name
           if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
               name = getNextSystemName(this);
           else
               name = optionalInputs.Name;
           end

           % Create IOPZResponse
           newResponse = createResponse_(this,model,name);
           if ~isempty(newResponse.DataException) && ~strcmp(this.ResponseDataExceptionMessage,"none")
               if strcmp(this.ResponseDataExceptionMessage,"error")
                   throw(newResponse.DataException);
               else % warning
                   warning(newResponse.DataException.identifier,newResponse.DataException.message);
               end
           end

           if ~isempty(optionalInputs.Color)
               newResponse.Color = optionalInputs.Color;
           end

           if ~isempty(optionalInputs.MarkerSize)
               newResponse.MarkerSize = optionalInputs.MarkerSize;
           end

            if ~isempty(optionalInputs.LineWidth)
                newResponse.Style.LineWidth = optionalInputs.LineWidth;
            end

           % Add response to chart
           registerResponse(this,newResponse);
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.IOPZPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.TimeUnits = char(this.TimeUnit);

                options.ConfidenceRegionNumberSD = this.NumberOfStandardDeviations;
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'TimeUnits'
                        options = char(this.TimeUnit);
                    case 'ConfidenceRegionNumberSD'
                        options = this.NumberOfStandardDeviations;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.IOPZPlot
                options (1,1) plotopts.PZOptions = getoptions(this)
                nameValueInputs.?plotopts.PZOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Set units
            if strcmp(options.TimeUnits,'auto')
                if isempty(this.Responses)
                    this.TimeUnit = "seconds";
                else
                    this.TimeUnit = this.Responses(1).TimeUnit;
                end
            else
                this.TimeUnit = options.TimeUnits;
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

            % Set characteristic options
            this.NumberOfStandardDeviations = options.ConfidenceRegionNumberSD;

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.RowColumnPlot(this,options);
        end
    end

    %% Get/Set methods
    methods        
        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            TimeUnit = this.TimeUnit_I;
        end

        function set.TimeUnit(this,TimeUnit)
            arguments
                this (1,1) controllib.chart.IOPZPlot
                TimeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidTimeUnit} 
            end
            this.TimeUnit_I = TimeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.TimeUnit = TimeUnit;
            end

            % Update property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.TimeUnits = TimeUnit;
            end
        end

        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            arguments
                this (1,1) controllib.chart.IOPZPlot
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

        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = get.NumberOfStandardDeviations(this)
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end

        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.IOPZPlot
                NumberOfStandardDeviations (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'ConfidenceRegion')
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = NumberOfStandardDeviations;
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.Type = 'iopzmap';
            this.SynchronizeResponseUpdates = true;
            this.XLimitsSharing = "column";
            this.XLimits = repmat({[1 10]},1,this.NInputs);
            this.XLimitsMode =  repmat({"auto"},1,this.NInputs);
            build(this);
        end

        function response = createResponse_(~,model,name)
            response = controllib.chart.response.IOPZResponse(model,Name=name);
        end

        %% View
        function view = createView_(this)
            % Create view
            view = controllib.chart.internal.view.axes.IOPZAxesView(this);
        end

        function tf = hasCustomGrid(this)
            isDiscrete = false(size(this.Responses));
            for ii = 1:length(this.Responses)
                isDiscrete(ii) = this.Responses(ii).IsDiscrete;
            end
            if isempty(isDiscrete)
                tf = false;
            elseif this.AxesStyle.GridType == "default"
                tf = all(isDiscrete) || ~any(isDiscrete);
            else
                tf = true;
            end
        end
        
        function cbResponseChanged(this,response)
            cbResponseChanged@controllib.chart.internal.foundation.RowColumnPlot(this,response);
            updateForCustomGrid(this.AxesStyle);
        end

        function cbResponseDeleted(this)
            cbResponseDeleted@controllib.chart.internal.foundation.RowColumnPlot(this);
            updateForCustomGrid(this.AxesStyle);
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(this,charType)
            switch charType
                case "ConfidenceRegion"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strConfidenceRegion')),...
                        Visible=false);
                    cm.VisibilityChangedFcn = @(es,ed) cbConfidenceRegionVisibility(this);
                    addCharacteristicProperty(cm,"NumberOfStandardDeviations",...
                        this.NumberOfStandardDeviations);
                    p = findprop(cm,"NumberOfStandardDeviations");
                    p.SetMethod = @(~,value) updateNumberOfStandardDeviations(this,value);
            end
        end
        
        function applyCharacteristicOptionsToResponse(this,response)
            if isprop(response,"NumberOfStandardDeviations")
                response.NumberOfStandardDeviations = this.NumberOfStandardDeviations;
            end
        end

        function cbConfidenceRegionVisibility(this)
            setCharacteristicVisibility(this,"ConfidenceRegion");
            if ~isempty(this.View) && isvalid(this.View)
                updateFocus(this.View);
            end
        end

        function updateNumberOfStandardDeviations(this,value)
            arguments
                this (1,1) controllib.chart.IOPZPlot
                value (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = value;
            this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations_I = value;
            
            % Update responses
            for k = 1:length(this.Responses)
                if isprop(this.Responses(k),'NumberOfStandardDeviations')
                    this.Responses(k).NumberOfStandardDeviations = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                end
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                updateCharacteristic(this.View,"ConfidenceRegion",this.Responses);
            end

            % Update property editor widget
            if ~isempty(this.ConfidenceRegionWidget) && isvalid(this.ConfidenceRegionWidget)
                disableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
                this.ConfidenceRegionWidget.ConfidenceNumSD = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                enableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
            end
        end

        %% Property editor
        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit'},ColumnWidth={'1x'},Padding=0);

            % Build Time Response widget and add to layout
            buildConfidenceRegionWidget(this);
            w = getWidget(this.ConfidenceRegionWidget);
            w.Parent = layout;
            w.Layout.Row = 1;
            w.Layout.Column = 1;

            % Add layout/widget to tab
            addTab(this.PropertyEditorDialog,getString(message('Controllib:gui:strOptions')),layout);
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('TimeUnits','FrequencyUnits');
            
            % Remove 'auto' from frequency and time unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];
            this.UnitsWidget.ValidTimeUnits(1,:) = [];
            
            % Set default units
            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.TimeUnits = this.TimeUnit;

            % Add custom label
            labelLayout = uigridlayout(RowHeight={'fit'},ColumnWidth={'1x'},Parent=[],Padding=[20 0 0 0]);
            uilabel(labelLayout,Text=getString(message('Controllib:gui:PZPlotFrequencyUnitDescriptionLabel')));
            setCustomWidget(this.UnitsWidget,labelLayout);

            % Add listeners for widget to data 
            registerListeners(this,...
                addlistener(this.UnitsWidget,'TimeUnits','PostSet',@(es,ed) cbTimeUnitChangedInPropertyEditor(this,ed)),...
                'TimeUnitChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',@(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                'FrequencyUnitChangedInPropertyEditor');

            % Local callback functions
            function cbTimeUnitChangedInPropertyEditor(this,ed)
                this.TimeUnit = ed.AffectedObject.TimeUnits;
            end

            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end
        end

        function buildConfidenceRegionWidget(this)
            this.ConfidenceRegionWidget = controllib.widget.internal.cstprefs.ConfidenceRegionContainer(...
                ShowStandardDeviationEditfield=true);

            this.ConfidenceRegionWidget.ConfidenceNumSD = this.NumberOfStandardDeviations;

            registerListeners(this,addlistener(this.ConfidenceRegionWidget,'ConfidenceNumSD','PostSet',...
                @(es,ed) cbConfidenceNumSDChangedInPropertyEditor(this,ed)),...
                'ConfidenceNumSDChangedInPropertyEditor');
            
            function cbConfidenceNumSDChangedInPropertyEditor(this,ed)
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = ed.AffectedObject.ConfidenceNumSD;
            end
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["TimeUnit","FrequencyUnit"];
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeSampleTime(Ts)
            if Ts ~= -1
                mustBePositive(Ts);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = pzoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function openPropertyDialog(this)
            openPropertyDialog@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.ConfidenceRegionWidget.Visible = any(arrayfun(@(x) isprop(x,'NumberOfStandardDeviations'),this.Responses));
        end

        function registerResponse(this,newResponse,~)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                ~
            end
            registerResponse@controllib.chart.internal.foundation.RowColumnPlot(this,newResponse);
            updateForCustomGrid(this.AxesStyle);
        end
    end
end