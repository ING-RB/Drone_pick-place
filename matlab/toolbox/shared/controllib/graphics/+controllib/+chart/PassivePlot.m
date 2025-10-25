classdef PassivePlot < controllib.chart.SectorPlot
    % SIGMAPLOT     Construct a chart of singular value plots.
    %
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.SigmaPlot("SystemModels",{rss(3,2,2)},Frequency=logspace(-2,2,100));

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Constructor/destructor
    methods
        function this = PassivePlot(passivePlotInputs,abstractPlotArguments)
            arguments
                passivePlotInputs.Options (1,1) plotopts.SectorPlotOptions = controllib.chart.PassivePlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.SectorPlot(abstractPlotArguments{:},Options=passivePlotInputs.Options);
        end
    end

    %% Public methods
    methods        
        function addResponse(this,models,optionalInputs,optionalStyleInputs)
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
                this (1,1) controllib.chart.PassivePlot
            end

            arguments(Repeating)
                models DynamicSystem
            end

            arguments
                optionalInputs.Type (1,1) string = "relative"'
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

            % Create PassiveResponse
            for k = 1:length(models)
                % Get next name
                if isempty(optionalInputs.Name(k)) || optionalInputs.Name(k) == ""
                    name = getNextSystemName(this);
                else
                    name = optionalInputs.Name(k);
                end
                
                % Create PassiveResponse
                newResponse = createResponse_(this,models{k},name,optionalInputs.Type,...
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
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.SectorPlot(this);
            this.Type = 'passive';
        end

        function response = createResponse_(~,model,name,type,frequency)
            response = controllib.chart.response.PassiveResponse(model,...
                Name=name,...
                PassiveType=type,...
                Frequency=frequency);
        end

        % View
        function view = createView_(this)
            % Create View
            view = controllib.chart.internal.view.axes.PassiveAxesView(this);
        end

        % Characteristics
        function cm = createCharacteristicOptions_(~,charType)
            switch charType
                case "PassiveWorstIndexResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strWorstIndex')),...
                        Visible=false);
            end
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(~)
            tags = "PassiveWorstIndexResponse";
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
                compute(data.PassiveWorstIndexResponse);
                
                isPeakResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "PassiveWorstIndexResponse",magConversionFcn(data.PassiveWorstIndexResponse.Value{ka}));
                arrayVisible(ka) = all(isPeakResponseWithinBounds(:));
            end
            response.ArrayVisible = arrayVisible;
        end
    end    

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = sectorplotoptions('cstprefs');
            options.Title.String = getString(message('Control:analysis:passiveplotTitle'));
        end
    end
end