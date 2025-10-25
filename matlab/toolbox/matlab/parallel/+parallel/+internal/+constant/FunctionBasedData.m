%FunctionBasedData Represents the structural data for a function-based
%Constant.

% Copyright 2022-2023 The MathWorks, Inc.

classdef FunctionBasedData < parallel.internal.constant.AbstractConstantData

    properties (SetAccess = immutable, GetAccess = private)
        % Initialization function.
        InitFcn function_handle

        % Cleanup function.
        CleanupFcn function_handle
    end

    properties (Transient, Access = private)
        % FunctionBasedData has a Value property that is Transient, and
        % assigned only once the InitFcn is first evaluated.
        Value

        % Has the InitFcn been evaluated?
        Initialized (1,1) logical = false

        % Any captured errors.
        Error MException {mustBeScalarOrEmpty} = MException.empty()
    end

    methods
        function obj = FunctionBasedData(initFcn, cleanupFcn)
            obj.InitFcn = initFcn;
            if isempty(cleanupFcn)
                obj.CleanupFcn = @iNoOp;
            else
                obj.CleanupFcn = cleanupFcn;
            end
        end

        function obj = initialize(obj)
            % Evaluate the initialization function. Capture any errors.
            if obj.Initialized
                return;
            end
            
            fcn = obj.InitFcn;
            try
                obj.Value = fcn();
            catch err
                % Don't throw the error now, client can handle it if they
                % attempt to access the Value later.
                if parallel.internal.pool.isPoolWorker()
                    err = addCause(MException(message('MATLAB:parallel:constant:ConstantBuildFailed')),err);
                end
                obj.Error = err;
            end

            obj.Initialized = true;
        end

        function cleanup(obj)
            % Evaluate the cleanup function if required. This may throw.
            if obj.Initialized
                fcn = obj.CleanupFcn;
                fcn(obj.Value);
            end
        end

        function value = getValue(obj)
            % Returns the Value. If there is a stored error, throw it now.
            if ~isempty(obj.Error)
                throw(obj.Error);
            end
            value = obj.Value;
        end

        function args = getConstructorArgs(obj)
            args = {obj.InitFcn, obj.CleanupFcn};
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A handy NO-OP function handle
function iNoOp(~)
end
