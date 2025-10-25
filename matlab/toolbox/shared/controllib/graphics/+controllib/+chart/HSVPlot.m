classdef HSVPlot < controllib.chart.internal.foundation.AbstractPlot
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
    %   h = controllib.chart.HSVPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        YScale
    end

    properties (GetAccess=protected,SetAccess=private)
        YScale_I = "log"
    end
    
    properties(Access = protected,Transient,NonCopyable)
        YScaleMenu
        YScaleSubMenu
    end

    %% Constructor/destructor
    methods
        function this = HSVPlot(hsvPlotInputs,inputOutputPlotArguments)
            arguments
                hsvPlotInputs.Options (1,1) plotopts.HSVOptions = controllib.chart.HSVPlot.createDefaultOptions()
                inputOutputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            inputOutputPlotArguments = namedargs2cell(inputOutputPlotArguments);
            this@controllib.chart.internal.foundation.AbstractPlot(inputOutputPlotArguments{:},...
                Options=hsvPlotInputs.Options);
        end
    end

    %% Public methods
    methods
        function updateSystem(this,sys,idx)
            % updateSystem: Updates the dynamic system of the chart.
            %
            %   updateSystem(h,sys)     updates the first response of the chart with the 
            %                           response of sys
            %   updateSystem(h,sys,N)   updates Nth response of the chart with the response
            %                           of sys
            arguments
                this
                sys DynamicSystem {mustBeNonempty,mustBeNonsparse}
                idx (1,1) double {localValidateUpdateSystemIdx(this,idx)} = 1
            end
            %warning(message('Controllib:plots:UpdateSystemWarning'));
            R = reducespec(sys,'balanced');
            if isa(this.Responses(idx).SourceData.R,'mor.BalancedTruncation')
                opts = this.Responses(idx).SourceData.R.Options;
                R.Options = opts;
            end
            this.Responses(idx).SourceData.R = R;
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.HSVPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this);
                options.YScale = char(this.YScale);
            else
                switch propertyName
                    case 'YScale'
                        options = char(this.YScale);
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
                this (1,1) controllib.chart.HSVPlot
                options (1,1) plotopts.HSVOptions = getoptions(this)
                nameValueInputs.?plotopts.HSVOptions
            end

            options = copy(options);

            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % YScale
            this.YScale = options.YScale;

            % Call base class
            setoptions@controllib.chart.internal.foundation.AbstractPlot(this,options);
        end
    end

    %% Get/Set methods
    methods
        % YScale
        function YScale = get.YScale(this)
            YScale = this.YScale_I;
        end

        function set.YScale(this,YScale)
            arguments
                this (1,1) controllib.chart.HSVPlot
                YScale (1,1) string {mustBeMember(YScale,["log","linear"])}
            end
            this.YScale_I = YScale;

            if ~isempty(this.View) && isvalid(this.View)
                this.View.StateContributionScale = YScale;
                updateFocus(this.View);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.AbstractPlot(this);
            this.Type = 'hsv';
            this.SynchronizeResponseUpdates = true;            
            build(this);
        end

        function response = createResponse_(~,R,name,HSVType)
            response = controllib.chart.response.HSVResponse(R,...
                Name=name,...
                HSVType=HSVType);
        end

        %% View
        function view = createView_(this)
            % Create view
            view = controllib.chart.internal.view.axes.HSVAxesView(this);
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.AbstractPlot(this);
            removeMenu(this,"systems")

            % Y Scale Menu
            this.YScaleMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strYScale')),...
                Tag="yscale");            
            this.YScaleSubMenu = createArray([2,1],'matlab.ui.container.Menu');
            this.YScaleSubMenu(1) = uimenu(this.YScaleMenu,...
                Text=getString(message('Controllib:plots:strLinear')),...
                Checked=strcmp(this.YScale,'linear'),...
                Tag="yscalelinear",...
                MenuSelectedFcn=@(es,ed) set(this,YScale="linear"));
            this.YScaleSubMenu(2) = uimenu(this.YScaleMenu,...
                Text=getString(message('Controllib:plots:strLog')),...
                Checked=strcmp(this.YScale,'log'),...
                Tag="yscalelog",...
                MenuSelectedFcn=@(es,ed) set(this,YScale="log"));

            addMenu(this,this.YScaleMenu,Above="grid");
        end

        function cbContextMenuOpening(this)
            cbContextMenuOpening@controllib.chart.internal.foundation.AbstractPlot(this);
            this.YScaleSubMenu(1).Checked = strcmp(this.YScale,'linear');
            this.YScaleSubMenu(2).Checked = strcmp(this.YScale,'log');
        end

        function cbResponseChanged(this,response)
            cbResponseChanged@controllib.chart.internal.foundation.AbstractPlot(this,response);
            updateLegendPlotChildren(this);
        end

        function permuteLegendObjects(this) %#ok<MANU>
        end

        function numberOfLabelsAddedToLegend = updateLegendWithCustomDataLabels(this,dataLabels)
            dataLabelIdx = 1;
            numberOfMaxLabels = min(length(this.PlotChildrenForLegend),length(dataLabels));
            plotChildrenIncludedInLegend = getPlotChildrenToIncludeInLegend(this);
            this.Legend.PlotChildren = plotChildrenIncludedInLegend(1:numberOfMaxLabels);
            for k = 1:numberOfMaxLabels
                if isvalid(this.PlotChildrenForLegend(k))
                    plotChildrenIncludedInLegend(k).DisplayName = dataLabels(dataLabelIdx);
                    dataLabelIdx = dataLabelIdx + 1;
                end
            end            
            numberOfLabelsAddedToLegend = dataLabelIdx;
        end

        function names = getCustomPropertyGroupNames(this)
            names = "YScale";
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = hsvoptions('cstprefs');
        end
    end

    %% Private methods
    methods (Access=private)
        function localValidateUpdateSystemIdx(this,idx)
            try
                mustBeMember(idx,1:length(this.Responses));
            catch
                error(message('Controllib:plots:UpdateSystem1',length(this.Responses)))
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function addResponse(this,R,optionalInputs)
            arguments
                this (1,1) controllib.chart.HSVPlot
                R (1,1) mor.GenericBTSpec
                optionalInputs.HSVType (1,1) string = "sigma";
                optionalInputs.Name (1,1) string = ""
            end

            if isempty(this.Responses)
                % Get next name
                if isempty(optionalInputs.Name) || optionalInputs.Name == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name;
                end
                % Create HSVResponse
                newResponse = createResponse_(this,R,name,optionalInputs.HSVType);
                if ~isempty(newResponse.DataException) && ~strcmp(this.ResponseDataExceptionMessage,"none")
                    if strcmp(this.ResponseDataExceptionMessage,"error")
                        throw(newResponse.DataException);
                    else % warning
                        warning(newResponse.DataException.identifier,newResponse.DataException.message);
                    end
                end

                % Use registerResponse to add response to chart
                registerResponse(this,newResponse);
            else
                error(message('Controllib:plots:hsvplot1'));
            end
        end
    end
end