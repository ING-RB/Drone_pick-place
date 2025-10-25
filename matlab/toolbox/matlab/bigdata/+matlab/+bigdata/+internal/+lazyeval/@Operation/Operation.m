%Operation
% An interface that represents an operation.

% Copyright 2015-2022 The MathWorks, Inc.

%{
classdef (Abstract) Operation < handle
    properties (SetAccess = immutable)
        % The number of inputs that the operation accepts.
        NumInputs;
        
        % The number of outputs that the operation returns.
        NumOutputs;
        
        % A flag that specifies if this operation supports preview. This is
        % true if and only if this operation can emit a small part of the output
        % based on only a small part of the input. This must be true if
        % DependsOnOnlyHead is true.
        SupportsPreview = false;
        
        % A flag that describes if this operation depends on only a small
        % number of slices that originate at the beginning.
        DependsOnOnlyHead = false;
    end
    
    properties (SetAccess=protected)
        % Does this operation support direct evaluation on gathered
        % arrays.
        SupportsDirectEvaluation = false;
    end
    
    properties (Access=protected)
        % Options for how to run this operation (RNG state etc.)
        Options = [];
    end
    
    properties (SetAccess=immutable)
        % Stack of the caller who created this operation.
        Stack;
    end
    
    methods
        % The main constructor.
        obj = Operation(numInputs, numOutputs, supportsPreview, dependsOnlyOnHead)
        
        % Immediately evaluate an operation on in-memory inputs. This
        % can be used to evaluate the operation immediately when all
        % inputs are already gathered. Do not call this on out-of-core
        % inputs.
        %
        % Syntax:
        %   [a,b,c,..] = directEvaluate(obj,x,y,..) invokes the operation on
        %   input gathered arrays {x,y,..} to produce output gathered
        %   arrays {a,b,c,..}
        varargout = directEvaluate(obj, varargin)
    end
    
    methods (Abstract)
        % Create a list of ExecutionTask instances that represent this
        % operation when applied to taskDependencies.
        %
        % Inputs:
        %  - taskDependencies: A list of ExecutionTask instances that represent
        %  the direct upstream tasks whos output will be passed into this
        %  operation.
        %  - inputFutureMap: An object that represents a mapping from the
        %  list of dependencies/taskDependencies to the list of operation inputs.
        tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
    end
    
    methods (Access=protected)
        % Per-operation implementation for direct evaluation. Do not
        % call this method directly, use directEvaluate instead
        % (template pattern).
        %
        % directEvaluate will call this with syntax:
        %   [a,b,c,..] = obj.directEvaluateImpl(x,y,..), which should
        %   immediately run the operation on input gathered arrays
        %   {x,y,..} to produce output gathered arrays {a,b,c,..}.        
        % We could provide a default implementation in terms of
        % createExecutionTasks and SerialExecutor. The reasons why we
        % don't are:
        %  1. Evaluation via SerialExecutor has too much overhead to
        %     trigger once per operation.
        %  2. Providing a version of SerialExecutor optimized for
        %  single small operations introduces a duplicate of a
        %  complicated piece of our architecture.
        varargout = directEvaluateImpl(obj, varargin) %#ok<STOUT>

        %Helper to add global state to the processor factor if required.
        % Should only be called for operations that have options.
        processorFactory = addGlobalState(obj, processorFactory)
    end
end
%}
