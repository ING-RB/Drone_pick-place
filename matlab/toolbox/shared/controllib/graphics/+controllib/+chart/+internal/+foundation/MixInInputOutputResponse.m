classdef MixInInputOutputResponse < controllib.chart.internal.foundation.MixInRowResponse & ...
                                    controllib.chart.internal.foundation.MixInColumnResponse
    % controllib.chart.internal.foundation.MixInInputOutputResponse
    %   - abstract class that provides properties related to inputs and
    %   outputs
    %
    % MixInInputOutputResponse(nInputs,nOutputs,Name-Value)

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden, Dependent, SetObservable, SetAccess = protected)
        % "NOutputs": double
        % Number of Model outputs
        NOutputs

        % "NInputs": double
        % Number of Model inputs
        NInputs
    end

    properties(Hidden, Dependent, SetAccess = protected)
        % "OutputNames": string array
        % Names of Model outputs
        OutputNames

        % "InputNames": string array
        % Names of Model inputs
        InputNames
    end

    properties (GetAccess = protected,SetAccess=private)
        NInputs_I
        NOutputs_I
        InputNames_I
        OutputNames_I
    end

    %% Constructor
    methods
        function this = MixInInputOutputResponse(nInputs,nOutputs,optionalInputs)
            arguments
                nInputs (1,1) double {mustBePositive,mustBeInteger} = 1
                nOutputs (1,1) double {mustBePositive,mustBeInteger} = 1
                optionalInputs.InputNames (:,1) string = strings(nInputs,1)
                optionalInputs.OutputNames (:,1) string = strings(nOutputs,1)
            end

            this.NInputs_I = nInputs;
            this.NOutputs_I = nOutputs;
            this.InputNames_I = optionalInputs.InputNames;
            this.OutputNames_I = optionalInputs.OutputNames;
            
            updateRowsAndColumns(this);            
        end
    end

    %% Get/Set
    methods
        % NInputs
        function NInputs = get.NInputs(this)
            NInputs = this.NInputs_I;
        end

        function set.NInputs(this,NInputs)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInInputOutputResponse
                NInputs (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            if NInputs > this.NInputs_I
                this.InputNames_I = [this.InputNames_I;strings(NInputs-this.NInputs_I,1)];
            else
                this.InputNames_I = this.InputNames_I(1:NInputs);
            end
            this.NInputs_I = NInputs;
            updateRowsAndColumns(this);
        end

        % NOutputs
        function NOutputs = get.NOutputs(this)
            NOutputs = this.NOutputs_I;
        end

        function set.NOutputs(this,NOutputs)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInInputOutputResponse
                NOutputs (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            if NOutputs > this.NOutputs_I
                this.OutputNames_I = [this.OutputNames_I;strings(NOutputs-this.NOutputs_I,1)];
            else
                this.OutputNames_I = this.OutputNames_I(1:NOutputs);
            end
            this.NOutputs_I = NOutputs;
            updateRowsAndColumns(this);
        end

        % InputNames
        function InputNames = get.InputNames(this)
            InputNames = this.InputNames_I;
        end

        function set.InputNames(this,InputNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInInputOutputResponse
                InputNames (:,1) string {mustBeInputSize(this,InputNames)}
            end
            this.InputNames_I = InputNames;
            updateRowsAndColumns(this);
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = this.OutputNames_I;
        end

        function set.OutputNames(this,OutputNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInInputOutputResponse
                OutputNames (:,1) string {mustBeOutputSize(this,OutputNames)}
            end
            this.OutputNames_I = OutputNames;
            updateRowsAndColumns(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function [nRows,nColumns] = getNumberOfRowsAndColumns(this)
            nRows = this.NOutputs;
            nColumns = this.NInputs;
        end

        function [rowNames,columnNames] = getRowAndColumnNames(this)
            rowNames = this.OutputNames;
            columnNames = this.InputNames;
        end
    end

    %% Private methods
    methods (Access = private)
        function updateRowsAndColumns(this)
            [nRows,nColumns] = getNumberOfRowsAndColumns(this);
            this.NRows = nRows;
            this.NColumns = nColumns;

            [rowNames,columnNames] = getRowAndColumnNames(this);
            this.RowNames = rowNames;
            this.ColumnNames = columnNames;
        end
		
        function mustBeInputSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NInputs 1]);
        end

        function mustBeOutputSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NOutputs 1]);
        end
    end
end