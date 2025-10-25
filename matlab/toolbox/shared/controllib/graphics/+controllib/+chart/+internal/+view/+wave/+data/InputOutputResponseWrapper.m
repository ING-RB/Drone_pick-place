classdef InputOutputResponseWrapper < controllib.chart.internal.view.wave.data.ResponseWrapper
    % ResponseWrapper provides a read-only copy of the response for
    % the response view classes. Ensure that ResponseWrapper has GetAccess
    % to a response property for it to be accessible.

    % Copyright 2023 The MathWorks, Inc.
    properties (Hidden, Dependent, SetAccess={?controllib.chart.internal.view.wave.BaseResponseView})
        NInputs
        NOutputs
    end

    methods
        function this = InputOutputResponseWrapper(Response)
            this@controllib.chart.internal.view.wave.data.ResponseWrapper(Response);
            this.NOutputs = Response.NOutputs;
            this.NInputs = Response.NInputs;
        end

        function set.NInputs(this,NInputs)
            this.NColumns = NInputs;
        end

        function NInputs = get.NInputs(this)
            NInputs = this.NColumns;
        end

        function set.NOutputs(this,NOutputs)
            this.NRows = NOutputs;
        end

        function NOutputs = get.NOutputs(this)
            NOutputs = this.NRows;
        end
    end
end