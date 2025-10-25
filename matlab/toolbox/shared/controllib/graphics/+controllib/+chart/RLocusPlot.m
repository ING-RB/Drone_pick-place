classdef RLocusPlot < controllib.chart.PZPlot
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

    %   Copyright 2021-2024 The MathWorks, Inc.


    %% Constructor/destructor
    methods
        function this = RLocusPlot(rLocusPlotInputs,abstractPlotArguments)
            arguments
                rLocusPlotInputs.Options (1,1) plotopts.PZOptions = controllib.chart.RLocusPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.PZPlot(abstractPlotArguments{:},Options=rLocusPlotInputs.Options);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,feedbackGains,optionalInputs,optionalStyleInputs)
            % addResponse adds the root locus response to the chart
            %
            %   addResponse(h,sys)
            %       adds the root locus response of "sys" to the chart "h"
            %
            %   addResponse(h,sys,K)
            %       K               [] (default) | vector | cell array
            %
            %   addResponse(h,______,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.RLocusPlot
                model DynamicSystem
                feedbackGains (:,1) double = []
                optionalInputs.Name (:,1) string = repmat("",length(model),1)
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create RLocusResponse
            % Get next name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create RLocusResponse
            newResponse = createResponse_(this,model,name,feedbackGains);
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
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.PZPlot(this);
            this.Type = 'rlocus';
        end

        %% Responses
        function response = createResponse_(~,model,name,feedbackGains)
            response = controllib.chart.response.RootLocusResponse(model,...
                FeedbackGains=feedbackGains,...
                Name=name);
        end

        % View
        function view = createView_(this)
            % Create view
            view = controllib.chart.internal.view.axes.RootLocusAxesView(this);
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = pzoptions('cstprefs');
            options.Title.String = getString(message('Controllib:plots:strRootLocus'));
        end
    end
end