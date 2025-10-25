classdef (Abstract) InputOutputAxesView < controllib.chart.internal.view.axes.RowColumnAxesView
       
    % Copyright 2021-2024 The MathWorks, Inc.

    %% Protected methods
    methods (Access = protected)
        function inputLabels = generateStringForColumnLabels(this)
            % Create and return input labels based on input names. 
            % Input label is "Fom: In(1)" where "In(1)" is input name. 
            inputLabels = this.ColumnNames;
            for k = 1:length(inputLabels)
                inputLabels(k) = "From: " + inputLabels(k);
            end
        end

        function outputLabels = generateStringForRowLabels(this)
            % Create and return output labels based on output names.
            % Output label is "To: Out(1)" where "Out(1)" is output name.
            outputLabels = this.RowNames;
            for k = 1:length(outputLabels)
                outputLabels(k) = "To: " + outputLabels(k);
            end
        end
    end

    %% Sealed static protected methods
    methods (Sealed,Static,Access=protected)
        function mustBeInputOutputResponse(responses)
            arrayfun(@(x) mustBeA(x,'controllib.chart.internal.foundation.InputOutputModelResponse'),responses);
        end
    end
end