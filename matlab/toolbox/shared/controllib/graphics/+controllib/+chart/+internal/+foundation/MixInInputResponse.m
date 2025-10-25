classdef MixInInputResponse < controllib.chart.internal.foundation.MixInColumnResponse
    % controllib.chart.internal.foundation.MixInInputResponse
    %   - abstract class that provides properties related to inputs
    %
    % MixInInputResponse(nInputs,<name-value>)
    %   model

    % Copyright 2022-2023 The MathWorks, Inc.

    %% Properties
    properties (Hidden, Dependent, SetObservable, SetAccess = protected)
        % "NInputs": double
        % Number of Model inputs
        NInputs
    end

    properties(Hidden, Dependent, SetAccess = {?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.foundation.MixInInputResponse})
        % "InputNames": string array
        % Names of Model inputs
        InputNames
    end

    %% Constructor
    methods
        function this = MixInInputResponse(nInputs,inputNames)
            arguments
                nInputs (1,1) double {mustBeNonnegative,mustBeInteger} = 1
                inputNames (1,:) string = repmat("",1,nInputs)
            end            
            controllib.chart.internal.foundation.MixInColumnResponse(nInputs,inputNames);
        end
    end

    %% Get/Set
    methods
        % NInputs
        function NInputs = get.NInputs(this)
            NInputs = getNInputs(this);
        end

        function set.NInputs(this,NInputs)
            setNColumns(this,NInputs);
        end

        % InputNames
        function InputNames = get.InputNames(this)
            InputNames = getInputNames(this);
        end

        function set.InputNames(this,InputNames)
            setColumnNames(this,InputNames);
        end
    end

    methods (Access = protected)
        % Overload these methods to get a different column-to-input mapping
        function NInputs = getNInputs(this)
            NInputs = this.NColumns;
        end

        function setNColumns(this,NInputs)
            this.NColumns = NInputs;
        end

        function InputNames = getInputNames(this)
            InputNames = this.ColumnNames;
        end

        function setColumnNames(this,InputNames)
            this.ColumnNames = InputNames;
        end
    end
end
