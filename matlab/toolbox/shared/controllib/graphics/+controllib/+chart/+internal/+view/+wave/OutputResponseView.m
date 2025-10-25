classdef OutputResponseView < controllib.chart.internal.view.wave.BaseResponseView

    %% Properties
    properties (Dependent, SetAccess = protected)
        OutputVisible
    end

    properties (Dependent, SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        OutputNames
    end

    %% Constructor
    methods
        function this = OutputResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.MixInRowResponse')}
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end

            this@controllib.chart.internal.view.wave.BaseResponseView(response,...              
                NRows=response.NOutputs,RowVisible=optionalInputs.OutputVisible,...
                ArrayVisible=optionalInputs.ArrayVisible);
            this.OutputNames = this.Response.OutputNames;
        end
    end

    %% Public methods
    methods
        function updateVisibility(this,responseVisible,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
                responseVisible (1,1) logical = this.Response.Visible
                optionalInputs.RowVisible (:,1) logical...
                    {validateVisibilitySize(this,optionalInputs.RowVisible,'OutputVisible')} = this.RowVisible
                optionalInputs.ArrayVisible logical...
                    {validateVisibilitySize(this,optionalInputs.ArrayVisible,'ArrayVisible')} = this.ArrayVisible
            end            
            updateVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,...
                responseVisible,...
                RowVisible=optionalInputs.RowVisible,...
                ArrayVisible=optionalInputs.ArrayVisible);
        end
    end

    %% Get/Set
    methods
        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
            end
            OutputVisible = this.RowVisible;
        end

        function set.OutputVisible(this,OutputVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
                OutputVisible (:,1) logical {validateVisibilitySize(this,OutputVisible,'OutputVisible')} 
            end
            this.RowVisible = OutputVisible;
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
            end
            OutputNames = this.RowNames;
        end

        function set.OutputNames(this,OutputNames)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
                OutputNames (:,1) string
            end
            this.RowNames = OutputNames;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows) %#ok<*INUSD>

        end

        function ioRow = getOutputDataTipRow(this,outputIdx)
            arguments
                this (1,1) controllib.chart.internal.view.wave.OutputResponseView
                outputIdx (1,1) double {mustBePositive, mustBeInteger} = 1
            end
            if (this.Response.NOutputs > 1 || (~isempty(this.PlotRowIdx) && max(this.PlotRowIdx) > 1)) && ...
                    length(this.OutputNames) >= outputIdx
                ioRow = dataTipTextRow(getString(message('Controllib:plots:strOutput')),@(x) string(this.OutputNames(outputIdx)));
            else
                ioRow = matlab.graphics.datatip.DataTipTextRow.empty;
            end
        end

        function updateOutputDataTipRow(this)
            % Update response data tips
            for ko = 1:this.Response.NOutputs
                outputRow = getOutputDataTipRow(this,ko);
                if isempty(outputRow)
                    continue;
                end
                for ka = 1:this.Response.NResponses
                    responseObjects = getResponseObjects(this,ko,1,ka);
                    for k = 1:numel(responseObjects{1})
                        if isprop(responseObjects{1}(k),'DataTipTemplate')
                            idx = find(contains({responseObjects{1}(k).DataTipTemplate.DataTipRows.Label},...
                                getString(message('Controllib:plots:strOutput'))),1);
                            if ~isempty(idx)
                                responseObjects{1}(k).DataTipTemplate.DataTipRows(idx) = outputRow;
                            end
                        end
                    end
                end
            end
            % Update characteristic data tips
            for k = 1:length(this.Characteristics)
                updateOutputDataTipRow(this.Characteristics(k));
            end
        end

        function updateRowNames(this)
            for k = 1:length(this.Characteristics)
                updateOutputDataTipRow(this.Characteristics(k));
            end
            if this.IsResponseViewValid
                updateOutputDataTipRow(this);
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function responseWrapper = createResponseWrapper(response)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.MixInRowResponse')}
            end
            responseWrapper = controllib.chart.internal.view.wave.data.OutputResponseWrapper(response);
        end
    end

    %% Private methods
    methods (Access=private)        
        function validateVisibilitySize(this,visibility,type)
            switch type
                case 'OutputVisible'
                    expectedVisible = this.RowVisible;
                case 'ArrayVisible'
                    expectedVisible = this.ArrayVisible;
            end
            controllib.chart.internal.utils.validators.mustBeSize(visibility,size(expectedVisible));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function createResponseDataTips(this)
            % Create data tip for all lines
            for ka = 1:this.Response.NResponses
                % Name Data Tip Row
                nameDataTipRow = getNameDataTipRow(this,ka);

                for ko = 1:this.Response.NOutputs
                    % Output row
                    outputDataTipRow = getOutputDataTipRow(this,ko);

                    % Custom Data Tip Row
                    customDataTipRows = getCustomDataTipRows(this,ko,1,ka);

                    % Call subclass implementation to create data
                    % tips
                    createResponseDataTips_(this,ko,ka,...
                        nameDataTipRow,outputDataTipRow,customDataTipRows);
                end
            end

            for k = 1:length(this.Characteristics)
                if this.Characteristics(k).IsInitialized
                    createDataTips(this.Characteristics(k));
                end
            end
            
            this.IsResponseDataTipsCreated = true;
        end
    end
end