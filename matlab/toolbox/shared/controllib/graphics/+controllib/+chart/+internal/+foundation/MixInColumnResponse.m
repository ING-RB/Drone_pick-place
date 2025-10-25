classdef MixInColumnResponse < matlab.mixin.SetGet & matlab.mixin.Copyable
    % controllib.chart.internal.foundation.MixInRowResponse
    %   - abstract class that provides properties related to rows
    %
    % MixInRowResponse(nRows,Name-Value)

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden, Dependent, SetObservable, SetAccess = protected)
        % "NColumns": double
        % Number of chart columns
        NColumns
    end

    properties(Hidden, Dependent, SetAccess = protected)
        % "ColumnNames": string array
        % Names of chart columns
        ColumnNames
    end

    properties (GetAccess=protected,SetAccess=private)
        NColumns_I = 1
        ColumnNames_I = ""
    end

    %% Public Methods
    methods
        function this = MixInColumnResponse(nColumns,columnNames)
            arguments
                nColumns (1,1) double {mustBeNonnegative,mustBeInteger} = 1
                columnNames (1,:) string = strings(1,nColumns)
            end            
            this.NColumns = nColumns;
            this.ColumnNames = columnNames;
        end
    end

    %% Get/Set
    methods
        % NColumns
        function NColumns = get.NColumns(this)
            NColumns = this.NColumns_I;
        end

        function set.NColumns(this,NColumns)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInColumnResponse
                NColumns (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            if NColumns > this.NColumns_I
                this.ColumnNames_I = [this.ColumnNames_I,strings(1,NColumns-this.NColumns_I)];
            else
                this.ColumnNames_I = this.ColumnNames_I(1:NColumns);
            end
            this.NColumns_I = NColumns;
        end

        % ColumnNames
        function ColumnNames = get.ColumnNames(this)
            ColumnNames = this.ColumnNames_I;
        end

        function set.ColumnNames(this,ColumnNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInColumnResponse
                ColumnNames (1,:) string {mustBeColumnSize(this,ColumnNames)}
            end
            this.ColumnNames_I = ColumnNames;
        end
    end

    %% Private methods
    methods (Access=private)
        function mustBeColumnSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[1 this.NColumns]);
        end
    end
end
