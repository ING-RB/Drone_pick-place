classdef MixInAxesViewLabels < handle
    
        %% Protected methods
    methods (Access = protected)
        function inputLabels = generateStringForColumnLabels(this)
            % Create and return input labels based on input names. 
            % Input label is "Fom: In(1)" where "In(1)" is input name. 
            inputLabels = this.ColumnNames;
        end

        function outputLabels = generateStringForRowLabels(this)
            % Create and return output labels based on output names.
            % Output label is "To: Out(1)" where "Out(1)" is output name.
            outputLabels = this.RowNames;
        end
    end

end