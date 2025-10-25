classdef NyquistPlot < controllib.chart.internal.foundation.RowColumnPlot & ...
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
    %   h = controllib.chart.StepPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        FrequencyUnit
        MagnitudeUnit
        PhaseUnit
        ShowNegativeFrequencies
    end

    properties (Dependent,Access=private)
        NumberOfStandardDeviations
        DisplaySampling
    end

    properties (GetAccess=protected,SetAccess=private)
        FrequencyUnit_I = "rad/s"
        MagnitudeUnit_I = "dB"
        PhaseUnit_I = "deg"
        ShowNegativeFrequencies_I = matlab.lang.OnOffSwitchState(true)

        NumberOfStandardDeviations_I = controllib.chart.NyquistPlot.createDefaultOptions().ConfidenceRegionNumberSD
        DisplaySampling_I = controllib.chart.NyquistPlot.createDefaultOptions().ConfidenceRegionDisplaySpacing
    end

    properties (Access = protected,Transient,NonCopyable)
        ConfidenceRegionWidget 

        NormalizeMenu
        ShowMenu
        ZoomCPMenu
        ShowSubMenu

        SpecifyFrequencyDialog
        SpecifyFrequencyMenu
    end

    properties (Hidden, SetAccess = protected)
        DGMStyleManager
    end

    %% Events
    events
        FrequencyChanged
    end

    %% Constructor/destructor
    methods
        function this = NyquistPlot(nyquistPlotInputs,rowColumnPlotArguments)
            arguments
                nyquistPlotInputs.Options (1,1) plotopts.NyquistOptions = controllib.chart.NyquistPlot.createDefaultOptions();
                rowColumnPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            rowColumnPlotArguments = namedargs2cell(rowColumnPlotArguments);
            this@controllib.chart.internal.foundation.RowColumnPlot(rowColumnPlotArguments{:},...
                Options=nyquistPlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.AbstractPlot(this);
            delete(this.SpecifyFrequencyDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,frequency,optionalInputs,optionalStyleInputs)
            % addResponse adds the nyquist response to the chart
            %
            %   addResponse(h,sys)
            %       adds the nyquist response of "sys" to the chart "h"
            %
            %   addResponse(h,sys,w)
            %       w               [] (default) | vector | cell array
            %
            %   addResponse(h,_____,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.NyquistPlot
                model DynamicSystem
                frequency = []
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create NyquistResponse
            % Get next name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create NyquistResponse
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
                this (1,1) controllib.chart.NyquistPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.MagUnits = char(this.MagnitudeUnit);
                options.PhaseUnits = char(this.PhaseUnit);

                options.ShowFullContour = char(this.ShowNegativeFrequencies);

                options.ConfidenceRegionNumberSD = this.NumberOfStandardDeviations;
                options.ConfidenceRegionDisplaySpacing = this.DisplaySampling;
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'MagUnits'
                        options = char(this.MagnitudeUnit);
                    case 'PhaseUnits'
                        options = char(this.PhaseUnit);
                    case 'ShowFullContour'
                        options = char(this.ShowNegativeFrequencies);
                    case 'ConfidenceRegionNumberSD'
                        options = this.NumberOfStandardDeviations;
                    case 'ConfidenceRegionDisplaySpacing'
                        options = this.DisplaySampling;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                options (1,1) plotopts.NyquistOptions = getoptions(this)
                nameValueInputs.?plotopts.NyquistOptions
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

            % Show negative frequencies
            this.ShowNegativeFrequencies = options.ShowFullContour;

            % Set characteristic options
            this.NumberOfStandardDeviations = options.ConfidenceRegionNumberSD;
            this.DisplaySampling = options.ConfidenceRegionDisplaySpacing;

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.RowColumnPlot(this,options);
        end
    end

    %% Get/Set methods
    methods        
        % DGMStyleManager
        function set.DGMStyleManager(this,DGMStyleManager)
            this.DGMStyleManager = DGMStyleManager;

            try %#ok<TRYNC>
                unregisterListeners(this,"DGMResponseStyleManagerChangedListener");
            end
            % Add Listener for DGMStyleManager
            L = addlistener(this.DGMStyleManager,"ResponseStyleManagerChanged",...
                @(es,ed) cbDGMResponseStyleManagerChanged(this));
            registerListeners(this,L,"DGMResponseStyleManagerChangedListener");
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Update property editor widgets
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
                this (1,1) controllib.chart.NyquistPlot
                MagnitudeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidMagnitudeUnit}
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
                this (1,1) controllib.chart.NyquistPlot
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

        % ShowNegativeFrequencies
        function ShowNegativeFrequencies = get.ShowNegativeFrequencies(this)
            ShowNegativeFrequencies = this.ShowNegativeFrequencies_I;
        end

        function set.ShowNegativeFrequencies(this,ShowNegativeFrequencies)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                ShowNegativeFrequencies (1,1) matlab.lang.OnOffSwitchState
            end
            this.ShowNegativeFrequencies_I = ShowNegativeFrequencies;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.ShowFullContour = ShowNegativeFrequencies;
                updateFocus(this.View);
            end
        end

        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = get.NumberOfStandardDeviations(this)
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end

        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                NumberOfStandardDeviations (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'ConfidenceRegion')
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = NumberOfStandardDeviations;
            end
        end

        % DisplaySampling
        function DisplaySampling = get.DisplaySampling(this)
            DisplaySampling = this.DisplaySampling_I;
        end

        function set.DisplaySampling(this,DisplaySampling)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                DisplaySampling (1,1) double {mustBePositive,mustBeInteger}
            end
            this.DisplaySampling_I = DisplaySampling;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'ConfidenceRegion')
                this.Characteristics.ConfidenceRegion.DisplaySampling = DisplaySampling;
            end
        end
    end

    %% Protected methods
    methods (Access = protected)    
        function initialize(this)
            % Set DGMStyleManager
            if isempty(this.Parent)
                theme = matlab.graphics.theme.GraphicsTheme();
            else
                theme = ancestor(this.Parent,'figure').Theme;
                if isempty(theme)
                    theme = matlab.graphics.theme.GraphicsTheme();
                end
            end
            colorOrder = [getRGB(controllib.plot.internal.utils.GraphicsColor(5),theme);...
                getRGB(controllib.plot.internal.utils.GraphicsColor(1),theme);...
                getRGB(controllib.plot.internal.utils.GraphicsColor(10),theme);...
                getRGB(controllib.plot.internal.utils.GraphicsColor(3),theme)];
            colorOrder = mat2cell(colorOrder,ones(1,size(colorOrder,1)),3);
            this.DGMStyleManager = controllib.chart.internal.options.ResponseStyleManager;
            this.DGMStyleManager.ColorOrder = colorOrder;

            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);

            this.Type = 'nyquist';
            this.SynchronizeResponseUpdates = true;
            build(this);
        end

        function update(this)
            update@controllib.chart.internal.foundation.RowColumnPlot(this);
            % Updates for theme changes
            if ~isempty(this.View) && isvalid(this.View)
                colorOrder = [getRGB(controllib.plot.internal.utils.GraphicsColor(5),this.Theme);...
                    getRGB(controllib.plot.internal.utils.GraphicsColor(1),this.Theme);...
                    getRGB(controllib.plot.internal.utils.GraphicsColor(10),this.Theme);...
                    getRGB(controllib.plot.internal.utils.GraphicsColor(3),this.Theme)];
                colorOrder = mat2cell(colorOrder,ones(1,size(colorOrder,1)),3);
                this.DGMStyleManager.ColorOrder = colorOrder;

                % Need to update color on legend object (if semantic colors
                % used)
                for k = 1:length(this.Responses)
                    if isvalid(this.Responses(k))
                        responseView = getResponseView(this.View,this.Responses(k));
                        if ~isempty(responseView) && isvalid(responseView)
                            updateLegendObjectOnThemeChange(responseView,this.Theme);
                        end
                    end
                end
            end
        end

        function postLoadInitialization(thisLoaded)
            postLoadInitialization@controllib.chart.internal.foundation.RowColumnPlot(thisLoaded)
            % Load handles
            thisLoaded.DGMStyleManager = thisLoaded.SavedValues.DGMStyleManager;
        end

        function postCopyInitialization(this,oldThis)
            postCopyInitialization@controllib.chart.internal.foundation.RowColumnPlot(this,oldThis)
            % Copy handles
            this.DGMStyleManager = copy(oldThis.DGMStyleManager);
        end

        function cbResponseStyleManagerChanged(this)
            isNyquistResponse = arrayfun(@(x) isa(x,"controllib.chart.response.NyquistResponse"),this.Responses);
            responses = this.Responses(isNyquistResponse);
            for k = 1:length(responses)
                % if this.Responses(k).Style.Mode == "auto"
                style = getStyle(this.StyleManager,this.ResponseStyleIndex(k));

                % Copy appropriate values from current response style
                copyPropertiesNotSetByStyleManager(style,responses(k).Style);
                copyPropertiesIfManualMode(style,responses(k).Style);

                % Use existing manual semantic colors if specified in
                % Response Style
                if responses(k).Style.ColorMode == "semantic"
                    style.SemanticColor = responses(k).Style.SemanticColor;
                end
                if responses(k).Style.FaceColorMode == "semantic"
                    style.SemanticFaceColor = responses(k).Style.SemanticFaceColor;
                end
                if responses(k).Style.EdgeColorMode == "semantic"
                    style.SemanticEdgeColor = responses(k).Style.SemanticEdgeColor;
                end

                % Set style object on response
                responses(k).Style = style;
            end
        end

        function cbDGMResponseStyleManagerChanged(this)
            isNyquistResponse = arrayfun(@(x) isa(x,"controllib.chart.response.NyquistResponse"),this.Responses);
            responses = this.Responses(~isNyquistResponse);
            for k = 1:length(responses)
                % if this.Responses(k).Style.Mode == "auto"
                style = getStyle(this.DGMStyleManager,this.ResponseStyleIndex(k));

                % Copy appropriate values from current response style
                copyPropertiesNotSetByStyleManager(style,responses(k).Style);
                copyPropertiesIfManualMode(style,responses(k).Style);

                % Use existing manual semantic colors if specified in
                % Response Style
                if responses(k).Style.ColorMode == "semantic"
                    style.SemanticColor = responses(k).Style.SemanticColor;
                end
                if responses(k).Style.FaceColorMode == "semantic"
                    style.SemanticFaceColor = responses(k).Style.SemanticFaceColor;
                end
                if responses(k).Style.EdgeColorMode == "semantic"
                    style.SemanticEdgeColor = responses(k).Style.SemanticEdgeColor;
                end

                % Set style object on response
                responses(k).Style = style;
            end
        end

        function [style,styleIndex] = dealNextSystemStyle(this)
            % dealNextSystemStyle: Return the style object for the next
            %   response based on StyleManager.
            %
            %   style = dealNextSystemStyle(h)
            %   style = dealNextSystemStyle(h,viewType) - viewType is 'Line'(default)|'Patch'
            if ~isempty(this.Responses)
                dgmResponses = arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses);
                responses = this.Responses(~dgmResponses);
                idx = this.ResponseStyleIndex(~dgmResponses);
                if ~isempty(responses)
                    styleIndicesInUse = idx(idx~=0);
                    styleIndicesNotUsed = setdiff((1:length(responses))',sort(styleIndicesInUse(:)));
                    if isempty(styleIndicesNotUsed)
                        styleIndex = length(responses)+1;
                    else
                        styleIndex = min(styleIndicesNotUsed);
                    end
                else
                    styleIndex = 1;
                end
            else
                styleIndex = 1;
            end
            % Generate style
            style = getStyle(this.StyleManager,styleIndex);
        end

        function [style,styleIndex] = dealNextDGMSystemStyle(this)
            % dealNextSystemStyle: Return the style object for the next
            %   response based on StyleManager.
            %
            %   style = dealNextSystemStyle(h)
            %   style = dealNextSystemStyle(h,viewType) - viewType is 'Line'(default)|'Patch'
            if ~isempty(this.Responses)
                dgmResponses = arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses);
                responses = this.Responses(dgmResponses);
                idx = this.ResponseStyleIndex(dgmResponses);
                if ~isempty(responses)
                    styleIndicesInUse = idx(idx~=0);
                    styleIndicesNotUsed = setdiff((1:length(responses))',sort(styleIndicesInUse(:)));
                    if isempty(styleIndicesNotUsed)
                        styleIndex = length(responses)+1;
                    else
                        styleIndex = min(styleIndicesNotUsed);
                    end
                else
                    styleIndex = 1;
                end
            else
                styleIndex = 1;
            end
            % Generate style
            style = getStyle(this.DGMStyleManager,styleIndex);
            style.FaceAlpha = 0.3;
            style.EdgeAlpha = 0.3;
            style.Mode = "auto";
        end

        function response = createResponse_(~,model,name,frequency)
            % Create system
            response = controllib.chart.response.NyquistResponse(model,...
                Name=name,...
                Frequency=frequency);
        end

        function response = createDGMResponse_(~,dgm,name,style,dgmType)
            % Create system
            response = robustplot.response.DiskMarginResponse(dgm,...
                Name=name,...
                Style=style,...
                DGMType=dgmType);
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(this,charType)
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
                case "ConfidenceRegion"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strConfidenceRegion')),...
                        Visible=false);
                    cm.VisibilityChangedFcn = @(es,ed) cbConfidenceRegionVisibility(this);
                    addCharacteristicProperty(cm,"NumberOfStandardDeviations",...
                        this.NumberOfStandardDeviations);
                    p = findprop(cm,"NumberOfStandardDeviations");
                    p.SetMethod = @(~,value) updateNumberOfStandardDeviations(this,value);
                    addCharacteristicProperty(cm,"DisplaySampling",...
                        this.DisplaySampling);
                    p = findprop(cm,"DisplaySampling");
                    p.SetMethod = @(~,value) updateDisplaySampling(this,value);
                case "DiskMargins"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Robust:plots:strDiskMargins')),...
                        Visible=false);
            end
        end

        function applyCharacteristicOptionsToResponse(this,response)
            if isprop(response,"NumberOfStandardDeviations")
                response.NumberOfStandardDeviations = this.NumberOfStandardDeviations;
            end
        end

        function cbConfidenceRegionVisibility(this)
            setCharacteristicVisibility(this,"ConfidenceRegion");
            updateFocus(this.View);
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(this)
            tags = string.empty;
            labels = string.empty;
            if this.NInputs == 1 && this.NOutputs == 1
                tags = ["GainMargin","PhaseMargin"];
                labels = [string(getString(message('Controllib:plots:strGainMargin'))),...
                            string(getString(message('Controllib:plots:strPhaseMargin')))];
            end
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            for ka = 1:response.NResponses
                if ~isempty(data.MinimumStabilityMargin)
                    compute(data.MinimumStabilityMargin);
                end
                
                isGainMarginWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "GainMargin",mag2db(data.MinimumStabilityMargin.GainMargin{ka}));
                isPhaseMarginWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "PhaseMargin",rad2deg(data.MinimumStabilityMargin.PhaseMargin{ka}));

                arrayVisible(ka) = all(isGainMarginWithinBounds(:) & ...
                                       isPhaseMarginWithinBounds(:));
            end
            response.ArrayVisible = arrayVisible;
        end

        function updateNumberOfStandardDeviations(this,value)
            arguments
                this (1,1) controllib.chart.NyquistPlot
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

        function updateDisplaySampling(this,value)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                value (1,1) double {mustBePositive,mustBeInteger}
            end
            this.DisplaySampling_I = value;
            this.Characteristics.ConfidenceRegion.DisplaySampling_I = value;

            % Update responses
            for k = 1:length(this.Responses)
                if isprop(this.Responses(k),'ConfidenceDisplaySampling')
                    this.Responses(k).ConfidenceDisplaySampling = this.Characteristics.ConfidenceRegion.DisplaySampling;
                end
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                updateCharacteristic(this.View,"ConfidenceRegion",this.Responses);
            end
        end

        %% View
        function view = createView_(this)
            % Create view
            view = controllib.chart.internal.view.axes.NyquistAxesView(this);
        end

        function tf = hasCustomGrid(this)
            tf = this.NInputs == 1 && this.NOutputs == 1;
        end
        
        function updateGridSize(this,newResponses)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                newResponses (:,1) controllib.chart.internal.foundation.BaseResponse = controllib.chart.internal.foundation.BaseResponse.empty
            end
            updateGridSize@controllib.chart.internal.foundation.RowColumnPlot(this,newResponses);
            updateForCustomGrid(this.AxesStyle);
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

            % Show Menu
            this.ShowMenu = uimenu(this.ContextMenu,Text=getString(message('Controllib:plots:strShow')));
            this.ShowSubMenu = uimenu(this.ShowMenu,...
                Text=getString(message('Controllib:plots:strNegativeFrequencies')),...
                Checked=this.ShowNegativeFrequencies,...
                MenuSelectedFcn=@(es,ed) set(this,ShowNegativeFrequencies=~this.ShowNegativeFrequencies));
            addMenu(this,this.ShowMenu,Above='grid',CreateNewSection=true);

            % ZoomCP menu
            this.ZoomCPMenu = uimenu(this.ContextMenu,Text=getString(message('Controllib:plots:strZoomOnNegative1')),...
                MenuSelectedFcn=@(es,ed) zoomcp(this));
            addMenu(this,this.ZoomCPMenu,Above='fullview');
        end

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.RowColumnPlot(this);
            % Show Menu
            this.ShowSubMenu.Checked = this.ShowNegativeFrequencies;
            this.ShowMenu.Visible = any(arrayfun(@(x) isa(x,'controllib.chart.response.NyquistResponse'),this.Responses));
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
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits','MagnitudeUnits','PhaseUnits');
            % Remove 'auto' from time unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];               

            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.MagnitudeUnits = this.MagnitudeUnit;
            this.UnitsWidget.PhaseUnits = this.PhaseUnit;

            % Add listeners for widget to data
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'PhaseUnits','PostSet',...
                @(es,ed) cbPhaseUnitChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertyEditor","MagnitudeUnitChangedInPropertyEditor",...
                "PhaseUnitChangedInPropertyEditor"]);

            % Local callback functions            
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbMagnitudeUnitChangedInPropertyEditor(this,ed)
                this.MagnitudeUnit = ed.AffectedObject.MagnitudeUnits;
            end

            function cbPhaseUnitChangedInPropertyEditor(this,ed)
                this.PhaseUnit = ed.AffectedObject.PhaseUnits;
            end
        end

        function buildConfidenceRegionWidget(this)
            % Build confidence region widget
            this.ConfidenceRegionWidget = controllib.widget.internal.cstprefs.ConfidenceRegionContainer();

            this.ConfidenceRegionWidget.ConfidenceNumSD = this.NumberOfStandardDeviations;

            % Add listeners
            registerListeners(this,addlistener(this.ConfidenceRegionWidget,'ConfidenceNumSD','PostSet',...
                @(es,ed) cbConfidenceNumSDChangedInPropertyEditor(this,ed)),...
                'ConfidenceNumSDChangedInPropertyEditor');
            
            function cbConfidenceNumSDChangedInPropertyEditor(this,ed)
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = ed.AffectedObject.ConfidenceNumSD;
            end
        end

        function openSpecifyFrequencyDialog(this)
            dgmResponse = arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses);
            if any(arrayfun(@(x) issparse(x.Model),this.Responses(~dgmResponse)))
                enableAuto = false;
                enableFrequencyRange = false;
                enableVector = true;
            else
                enableAuto = true;
                enableFrequencyRange = true;
                enableVector = true;
            end
            if isempty(this.SpecifyFrequencyDialog) || ~isvalid(this.SpecifyFrequencyDialog)
                dgmResponse = arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses);
                nyquistResponses = this.Responses(~dgmResponse);
                if isempty(nyquistResponses)
                    f = [];
                else
                    f = nyquistResponses(end).SourceData.FrequencySpec;
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
                dmResponse = arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses);
                nyResponses = this.Responses(~dmResponse);
                for k = 1:length(nyResponses)
                    if ~isempty(ed.Data.Frequency)
                        cf = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                            ed.Data.FrequencyUnits,this.Responses(k).FrequencyUnit);
                        if iscell(ed.Data.Frequency)
                            nyResponses(k).SourceData.FrequencySpec = {cf(ed.Data.Frequency{1}), cf(ed.Data.Frequency{2})};
                        else
                            nyResponses(k).SourceData.FrequencySpec = cf(ed.Data.Frequency);
                        end
                    else
                        nyResponses(k).SourceData.FrequencySpec = ed.Data.Frequency;
                    end
                end
                ev = controllib.chart.internal.utils.GenericEventData(ed.Data.Frequency);
                notify(this,'FrequencyChanged',ev);
            end
        end

        function this = saveobj(this)
            this = saveobj@controllib.chart.internal.foundation.RowColumnPlot(this);

            this.SavedValues.DGMStyleManager = this.DGMStyleManager;
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["FrequencyUnit","MagnitudeUnit",...
                "PhaseUnit","ShowNegativeFrequencies"];
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = nyquistoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function addDGMResponse(this,dgm,optionalInputs)
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
                this (1,1) controllib.chart.NyquistPlot
            end
            arguments (Repeating)
                dgm (1,2) double
            end
            arguments
                optionalInputs.DGMType (1,1) string = "nyquist"
                optionalInputs.DGMSpec (1,1) logical = true
                optionalInputs.Name (:,1) string = repmat("",length(dgm),1)
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
                for k = 1:length(dgm)
                    optionalInputs.Name(k) = string(inputname(k+1));
                end
            end

            % Create DiskMarginResponse
            for k = 1:length(dgm)
                % Get next style and name
                style = dealNextDGMSystemStyle(this);
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end
                
                % Create DiskMarginResponse
                newResponse = createDGMResponse_(this,dgm{k},name,style,optionalInputs.DGMType);  
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
                registerDGMResponse(this,newResponse);
            end
        end

        function registerDGMResponse(this,newResponse)
            arguments
                this (1,1) controllib.chart.NyquistPlot
                newResponse (1,1) robustplot.response.DiskMarginResponse
            end
            if strcmp(newResponse.Style.Mode,"auto")
                [style,styleIndex] = dealNextDGMSystemStyle(this);
                newResponse.Style = style;
            else
                styleIndex = 0;
            end
            this.ResponseStyleIndex = [this.ResponseStyleIndex(:); styleIndex];
            addResponseToChart(this,newResponse,[],"","",[]);
        end

        function showDGMDataTips(this)
            showDGMDataTips(this.View);
        end

        function zoomcp(this)
            if ~isempty(this.View) && isvalid(this.View)
                zoomcp(this.View,this.VisibleResponses);
            end
            if strcmp(this.XLimitsSharing,"all")
                this.XLimitsMode = "manual";
            else
                this.XLimitsMode = repmat({"manual"},size(this.XLimitsMode));
            end
            if strcmp(this.YLimitsSharing,"all")
                this.YLimitsMode = "manual";
            else
                this.YLimitsMode = repmat({"manual"},size(this.YLimitsMode));
            end
        end

        function openPropertyDialog(this)
            openPropertyDialog@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.UnitsWidget.MagnitudeRowVisible = any(arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses));
            this.UnitsWidget.PhaseRowVisible = any(arrayfun(@(x) isa(x,'robustplot.response.DiskMarginResponse'),this.Responses));
            this.ConfidenceRegionWidget.Visible = any(arrayfun(@(x) isprop(x,'NumberOfStandardDeviations'),this.Responses));
        end

        function widgets = qeGetPropertyEditorWidgets(this)
            widgets = qeGetPropertyEditorWidgets@controllib.chart.internal.foundation.AbstractPlot(this);
            widgets.ConfidenceRegionWidget = this.ConfidenceRegionWidget;
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end

        function registerResponse(this,newResponse,~)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                ~
            end

            if isa(newResponse,'robustplot.response.DiskMarginResponse')
                registerDGMResponse(this,newResponse)
            else
                registerResponse@controllib.chart.internal.foundation.RowColumnPlot(this,newResponse);
            end
        end
    end
end

function copyPropertiesNotSetByStyleManager(style,currentStyle)
% Set properties not managed by StyleManager
style.FaceAlpha = currentStyle.FaceAlpha;
style.EdgeAlpha = currentStyle.EdgeAlpha;
style.LineWidth = currentStyle.LineWidth;
style.MarkerSize = currentStyle.MarkerSize;
style.CharacteristicsMarkerStyle = currentStyle.CharacteristicsMarkerStyle;
style.CharacteristicsMarkerSize = currentStyle.CharacteristicsMarkerSize;
end

function copyPropertiesIfManualMode(style,currentStyle)
% Copy Color/SemanticColor if needed
if strcmp(currentStyle.ColorMode,"semantic")
    style.SemanticColor = currentStyle.SemanticColor;
elseif strcmp(currentStyle.ColorMode,"manual")
    style.Color = currentStyle.Color;
end

% Copy FaceColor and EdgeColor if needed
if currentStyle.FaceColorMode == "semantic"
    style.SemanticFaceColor = currentStyle.SemanticFaceColor;
end
if currentStyle.EdgeColorMode == "semantic"
    style.SemanticEdgeColor = currentStyle.SemanticEdgeColor;
end

% Copy LineStyle if needed
if strcmp(currentStyle.LineStyleMode,"manual")
    style.LineStyle = currentStyle.LineStyle;
end

% Copy MarkerStyle if needed
if strcmp(currentStyle.MarkerStyleMode,"manual")
    style.MarkerStyle = currentStyle.MarkerStyle;
end
end
