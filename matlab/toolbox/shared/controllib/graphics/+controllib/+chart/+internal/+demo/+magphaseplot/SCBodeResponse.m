classdef SCBodeResponse < controllib.chart.response.BodeResponse
    methods
        function this = SCBodeResponse(varargin)
            this@controllib.chart.response.BodeResponse(varargin{:});
            if all(strcmp(this.InputNames,""))
                this.InputNames = "In (" + string(1:this.NInputs) + ")";
            end
            if all(strcmp(this.OutputNames,""))
                this.OutputNames = "Out (" + string(1:this.NOutputs) + ")";
            end
        end
    end
    
    % Override getNumberOfRowsAndColumns() and getRowAndColumnNames() to
    % map input/outputs to rows/columns.
    methods (Access = protected)
       function [nRows,nColumns] = getNumberOfRowsAndColumns(this)
            nRows = this.NOutputs + this.NInputs;
            nColumns = 1;
        end

        function [rowNames,columnNames] = getRowAndColumnNames(this)
            rowNames = repmat("",1,this.NOutputs + this.NInputs);
            columnNames = "";
            ctr = 1;
            for ko = 1:this.NOutputs
                for ki = 1:this.NInputs
                    rowNames(ctr) = this.InputNames(ki) + "-to-" + this.OutputNames(ko);
                    ctr = ctr+1;
                end
            end
        end
    end
end