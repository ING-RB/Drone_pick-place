classdef InputOutputResponseView < controllib.chart.internal.view.wave.BaseResponseView
    % InputOutputResponseView

    % Copyright 2022-2023 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,SetAccess = protected)
        InputVisible
        OutputVisible
    end

    properties (Dependent, SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        InputNames
        OutputNames
    end

    %% Constructor
    methods
        function this = InputOutputResponseView(response,optionalInputs)      
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.InputOutputModelResponse')}
                optionalInputs.InputVisible (1,:) logical = true(1,response.NInputs);
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.view.wave.BaseResponseView(response,...                
                NRows=response.NRows,NColumns=response.NColumns,...
                RowVisible=optionalInputs.OutputVisible,ColumnVisible=optionalInputs.InputVisible,...
                ArrayVisible=optionalInputs.ArrayVisible);
            this.OutputNames = this.Response.OutputNames;
            this.InputNames = this.Response.InputNames;
        end
    end

    % %% Public methods
    % methods
    %     function updateVisibility(this,responseVisible,optionalInputs)
    %         arguments
    %             this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
    %             responseVisible (1,1) logical = this.Response.Visible
    %             optionalInputs.InputVisible (1,:) logical...
    %                 {validateVisibilitySize(this,optionalInputs.InputVisible,'InputVisible')} = this.ColumnVisible
    %             optionalInputs.OutputVisible (:,1) logical...
    %                 {validateVisibilitySize(this,optionalInputs.OutputVisible,'OutputVisible')} = this.RowVisible
    %             optionalInputs.ArrayVisible logical...
    %                 {validateVisibilitySize(this,optionalInputs.ArrayVisible,'ArrayVisible')} = this.ArrayVisible
    %         end            
    %         updateVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,...
    %             responseVisible,...
    %             ColumnVisible=optionalInputs.InputVisible,...
    %             RowVisible=optionalInputs.OutputVisible,...
    %             ArrayVisible=optionalInputs.ArrayVisible);
    %     end
    % end

    %% Get/Set
    methods
        % InputVisible
        function InputVisible = get.InputVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
            end
            InputVisible = this.ColumnVisible;
        end

        function set.InputVisible(this,InputVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
                InputVisible (1,:) logical {validateVisibilitySize(this,InputVisible,'InputVisible')} 
            end
            this.ColumnVisible = InputVisible;
        end

        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
            end
            OutputVisible = this.RowVisible;
        end

        function set.OutputVisible(this,OutputVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
                OutputVisible (:,1) logical {validateVisibilitySize(this,OutputVisible,'OutputVisible')} 
            end
            this.RowVisible = OutputVisible;
        end

        % InputNames
        function InputNames = get.InputNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
            end
            InputNames = this.ColumnNames;
        end

        function set.InputNames(this,InputNames)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
                InputNames (1,:) string
            end
            this.ColumnNames = InputNames;
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
            end
            OutputNames = this.RowNames;
        end

        function set.OutputNames(this,OutputNames)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
                OutputNames (:,1) string
            end
            this.RowNames = OutputNames;
        end
    end

    %% Protected methods (to override in subclass)
    methods(Access = protected)
        function ioRow = getIODataTipRow(this,inputIdx,outputIdx)
            arguments
                this (1,1) controllib.chart.internal.view.wave.InputOutputResponseView
                inputIdx (1,1) double {mustBePositive, mustBeInteger} = 1
                outputIdx (1,1) double {mustBePositive, mustBeInteger} = 1
            end
            if (this.Response.NInputs > 1 || this.Response.NOutputs > 1 || ...
                    (~isempty(this.PlotColumnIdx) && max(this.PlotColumnIdx) > 1) || ...
                    (~isempty(this.PlotRowIdx) && max(this.PlotRowIdx) > 1)) && ...
                    length(this.InputNames) >= inputIdx && length(this.OutputNames) >= outputIdx
                ioLabel = getString(message('Controllib:plots:InputToOutput',this.InputNames(inputIdx),...
                    this.OutputNames(outputIdx)));
                ioRow = dataTipTextRow(getString(message('Controllib:plots:strIO')),@(x) string(ioLabel));
            else
                ioRow = matlab.graphics.datatip.DataTipTextRow.empty;
            end
        end

        function updateColumnNames(this)
            for k = 1:length(this.Characteristics)
                updateIODataTipRow(this.Characteristics(k));
            end
            if this.IsResponseViewValid
                updateIODataTipRow(this);
            end
        end

        function updateIODataTipRow(this)
            if this.IsResponseDataTipsCreated
                % Update response data tips
                for ko = 1:this.Response.NOutputs
                    for ki = 1:this.Response.NInputs
                        ioRow = getIODataTipRow(this,ki,ko);
                        if isempty(ioRow)
                            continue;
                        end
                        for ka = 1:this.Response.NResponses
                            responseObjects = getResponseObjects(this,ko,ki,ka);
                            for k = 1:numel(responseObjects{1})
                                if isprop(responseObjects{1}(k),'DataTipTemplate')
                                    idx = find(contains({responseObjects{1}(k).DataTipTemplate.DataTipRows.Label},...
                                        getString(message('Controllib:plots:strIO'))),1);
                                    if ~isempty(idx)
                                        responseObjects{1}(k).DataTipTemplate.DataTipRows(idx) = ioRow;
                                    end
                                end
                            end
                        end
                    end
                end

                % Update characteristic data tips
                for k = 1:length(this.Characteristics)
                    updateIODataTipRow(this.Characteristics(k));
                end
            end
        end
        
        function updateRowNames(this)
            for k = 1:length(this.Characteristics)
                updateIODataTipRow(this.Characteristics(k));
            end
            if this.IsResponseViewValid
                updateIODataTipRow(this);
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function responseWrapper = createResponseWrapper(response)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.InputOutputModelResponse')}
            end
            responseWrapper = controllib.chart.internal.view.wave.data.InputOutputResponseWrapper(response);
        end
    end

    %% Private methods
    methods (Access=private)        
        function validateVisibilitySize(this,visibility,type)
            switch type
                case 'InputVisible'
                    expectedVisible = this.InputVisible;
                case 'OutputVisible'
                    expectedVisible = this.OutputVisible;
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
                    for ki = 1:this.Response.NInputs
                        % I/O row
                        ioDataTipRow = getIODataTipRow(this,ki,ko);

                        % Custom Data Tip Row
                        customDataTipRows = getCustomDataTipRows(this,ko,ki,ka);

                        % Call subclass implementation to create data
                        % tips
                        createResponseDataTips_(this,ko,ki,ka,...
                            nameDataTipRow,ioDataTipRow,customDataTipRows);
                    end
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