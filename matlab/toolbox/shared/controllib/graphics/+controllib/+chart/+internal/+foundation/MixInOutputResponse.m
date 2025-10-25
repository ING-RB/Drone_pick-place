classdef MixInOutputResponse < controllib.chart.internal.foundation.MixInRowResponse
    % controllib.chart.internal.foundation.MixInOutputResponse
    %   - abstract class that provides properties related to outputs
    %
    % MixInOutputResponse(nOutputs,Name-Value)

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden, Dependent, SetObservable, SetAccess = protected)
        % "NOutputs": double
        % Number of Model outputs
        NOutputs
    end

    properties(Hidden, Dependent, SetAccess = {?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.foundation.MixInOutputResponse})
        % "OutputNames": string array
        % Names of Model outputs
        OutputNames
    end

    %% Constructor
    methods
        function this = MixInOutputResponse(nOutputs,outputNames)
            arguments
                nOutputs (1,1) double {mustBeNonnegative,mustBeInteger} = 1
                outputNames (:,1) string = repmat("",nOutputs,1)
            end            
            controllib.chart.internal.foundation.MixInRowResponse(nOutputs,outputNames);
        end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            NOutputs = getNOutputs(this);
        end

        function set.NOutputs(this,NOutputs)
            setNRows(this,NOutputs);
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = getOutputNames(this);
        end

        function set.OutputNames(this,OutputNames)
            setRowNames(this,OutputNames);
        end
    end

    methods (Access = protected)
        % Overload these methods to get a different row-to-output mapping
        function NOutputs = getNOutputs(this)
            NOutputs = this.NRows;
        end

        function setNRows(this,NOutputs)
            this.NRows = NOutputs;
        end

        function OutputNames = getOutputNames(this)
            OutputNames = this.RowNames;
        end

        function setRowNames(this,OutputNames)
            this.RowNames = OutputNames;
        end
    end
end
