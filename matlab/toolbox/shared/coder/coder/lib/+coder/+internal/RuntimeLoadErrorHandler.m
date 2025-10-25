classdef RuntimeLoadErrorHandler
    %MATLAB Code Generation Private Class

    %   Copyright 2021 The MathWorks, Inc.
    %#codegen
    properties
        CurrentError = coder.ReadStatus.Success;
        ThrowErrors;
    end
    methods
        function this = RuntimeLoadErrorHandler(t)
            this.ThrowErrors = t;
        end
        function this = assertOrAssignError(this, cond, ec, varargin)
            coder.internal.allowEnumInputs;
            coder.internal.prefer_const(cond, ec)
            if this.CurrentError == coder.ReadStatus.Success && ~cond
                this.CurrentError = ec; %errors might be disabled even when the user requests them
            end
            if this.ThrowErrors
                coder.internal.assert(cond, ['Coder:toolbox:CoderRead', char(ec)], varargin{:})
            end
        end
        function out = noErrorsYet(this)
            out = this.CurrentError == coder.ReadStatus.Success;
        end
    end
    methods (Access = private, Static = true)
        function result = matlabCodegenNontunableProperties(~)
            result = {'throwErrors'};
        end
    end
end