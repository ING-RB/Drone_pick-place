%FusedSlicewiseFunction
% Function that is the fusion of 2 or more slicewise functions.

% Copyright 2018-2022 The MathWorks, Inc.

classdef FusedSlicewiseFunction < handle & matlab.mixin.Copyable
    
    properties (SetAccess = immutable)
        % A cell array of function handles
        Functions (1,:) cell
        
        % For each function, the corresponding error stack of the line of
        % code that created the original function.
        FunctionErrorStacks (1,:) cell
        
        % For each function, an array of indices of the temporary local
        % variables to be used as input arguments.
        FunctionInputIndices (1,:) cell
        
        % For each function, an array of indices of the temporary local
        % variables to be used as output arguments.
        FunctionOutputIndices (1,:) cell
        
        % For each function, an array of indices of the temporary local
        % variables to be deleted during function evaluation.
        DeleteIndices (1,:) cell
        
        % Number of temporary local variables required.
        NumLocalVariables (1,1) double
        
        % Indices of the temporary local variables to be emitted as output
        % of the FusedSlicewiseFunction.
        GlobalOutputIndices (1,:) double
    end
    
    methods
        function obj = FusedSlicewiseFunction(functions, errorStacks, ...
                functionInputIndices, functionOutputIndices, ...
                deleteIndices, numLocalVariables, globalOutputIndices)
            % Build a FusedSlicewiseFunction. See SlicewiseFusingOptimizer
            % for more details.
            obj.Functions = functions;
            obj.FunctionErrorStacks = errorStacks;
            obj.FunctionInputIndices = functionInputIndices;
            obj.FunctionOutputIndices = functionOutputIndices;
            obj.DeleteIndices = deleteIndices;
            obj.NumLocalVariables = numLocalVariables;
            obj.GlobalOutputIndices = globalOutputIndices;
        end
        
        function varargout = feval(obj, varargin)
            % Evaluate the fused slicewise function on the given input
            % arguments.
            functions = obj.Functions;
            functionInputIndices = obj.FunctionInputIndices;
            functionOutputIndices = obj.FunctionOutputIndices;
            deleteIndices = obj.DeleteIndices;
            
            localVariables = cell(obj.NumLocalVariables, 1);
            localVariables(1:numel(varargin)) = varargin;
            varargin = []; %#ok<NASGU>
            for ii = 1:numel(functions)
                inputargs = localVariables(functionInputIndices{ii});
                localVariables(deleteIndices{ii}) = {[]};
                [localVariables{functionOutputIndices{ii}}] ...
                    = feval(functions{ii}, inputargs{:});
            end
            varargout = localVariables(obj.GlobalOutputIndices)';
        end
        
        function handleIncompatibleSizeError(obj, err, isTooShortVector, isTooLongVector)
            % Find the first instance of function inputs where
            % input arguments marked as too short is used for the same
            % function as an input argument that is too long.
            %
            % This works by propagating ID +1 for too long and ID -1 for
            % too short through the graph of data flow until they meet.
            import matlab.bigdata.BigDataException
            localVariables = zeros(obj.NumLocalVariables, 1);
            localVariables(isTooShortVector) = -1;
            localVariables(isTooLongVector) = 1;
            for ii = 1:numel(obj.FunctionErrorStacks)
                data = localVariables(obj.FunctionInputIndices{ii});
                if any(data < 0) && any(data > 0)
                    err = BigDataException.build(err);
                    err = attachSubmissionStack(err, obj.FunctionErrorStacks{ii});
                    updateAndRethrow(err);
                end
                if all(data == 0)
                    out = 0;
                else
                    out = unique(data(data ~= 0));
                end
                localVariables(obj.FunctionOutputIndices{ii}) = out;
            end
            % We should not be able to reach here given this optimizer only
            % fuses together connected subgraphs.
            assert(false, 'Assertion failed: Unable to determine cause of incompatible inputs');
        end
    end
end
