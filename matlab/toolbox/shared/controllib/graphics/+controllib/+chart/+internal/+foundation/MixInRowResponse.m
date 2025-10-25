classdef MixInRowResponse < matlab.mixin.SetGet & matlab.mixin.Copyable
    % controllib.chart.internal.foundation.MixInRowResponse
    %   - abstract class that provides properties related to rows
    %
    % MixInRowResponse(nRows,Name-Value)

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden, Dependent, SetObservable, SetAccess = protected)
        % "NRows": double
        % Number of chart rows
        NRows
    end

    properties(Hidden, Dependent, SetAccess = protected)
        % "RowNames": string array
        % Names of chart rows
        RowNames
    end

    properties (GetAccess=protected,SetAccess=private)
        NRows_I = 1
        RowNames_I = ""
    end

    %% Public Methods
    methods
        function this = MixInRowResponse(nRows,rowNames)
            arguments
                nRows (1,1) double {mustBeNonnegative,mustBeInteger} = 1
                rowNames (:,1) string = strings(nRows,1)
            end            
            this.NRows = nRows;
            this.RowNames = rowNames;
        end
    end

    %% Get/Set
    methods
        % NRows
        function NRows = get.NRows(this)
            NRows = this.NRows_I;
        end

        function set.NRows(this,NRows)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInRowResponse
                NRows (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            if NRows > this.NRows_I
                this.RowNames_I = [this.RowNames_I;strings(NRows-this.NRows_I,1)];
            else
                this.RowNames_I = this.RowNames_I(1:NRows);
            end
            this.NRows_I = NRows;
        end

        % RowNames
        function RowNames = get.RowNames(this)
            RowNames = this.RowNames_I;
        end

        function set.RowNames(this,RowNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInRowResponse
                RowNames (:,1) string {mustBeRowSize(this,RowNames)}
            end
            this.RowNames_I = RowNames;
        end
    end

    %% Private methods
    methods (Access=private)
        function mustBeRowSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NRows 1]);
        end
    end
end
