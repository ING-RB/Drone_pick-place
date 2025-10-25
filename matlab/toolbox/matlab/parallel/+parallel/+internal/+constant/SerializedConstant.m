%SerializedConstant Trivial helper so that public Constant constructor can
%unambiguously identity arguments used to rebuild a serialized Constant.

% Copyright 2023 The MathWorks, Inc.
classdef (Hidden) SerializedConstant
    properties (SetAccess = immutable)
        ID
        Arg
        CleanupFcn
    end
    methods (Access = ?parallel.pool.Constant)
        function obj = SerializedConstant(id, arg, cleanupFcn)
            arguments
                id;
                arg;
                cleanupFcn = function_handle.empty();
            end
            obj.ID = id;
            obj.Arg = arg;
            obj.CleanupFcn = cleanupFcn;
        end

        function [id, arg, cleanupFcn] = unpackInputs(obj)
            id = obj.ID;
            arg = obj.Arg;
            cleanupFcn = obj.CleanupFcn;
        end
    end
end
    
