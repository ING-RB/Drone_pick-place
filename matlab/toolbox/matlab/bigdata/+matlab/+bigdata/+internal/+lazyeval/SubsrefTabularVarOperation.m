%SubsrefTabularVarOperation
% An operation that performs subsref of table/timetable variables.

% Copyright 2018 The MathWorks, Inc.

classdef SubsrefTabularVarOperation < matlab.bigdata.internal.lazyeval.SlicewiseFusableOperation
    
    properties (SetAccess = immutable)
        % Underlying Operation called by SubsrefTabularVar: SlicewiseOperation
        UnderlyingOperation;
        
        % Small subscripts
        Subs;
        
        % Function handle
        FunctionHandle;
    end
    
    methods
        % SubsrefTabularVarOperation constructor
        function obj = SubsrefTabularVarOperation(numInputs, numOutputs, isGrouped, subsrefType, subs)
            fh = @(varargin) subsrefTabularVarFunction(subsrefType, subs, varargin{:});
            functionHandle = matlab.bigdata.internal.FunctionHandle(fh);
            if isGrouped
                functionHandle = matlab.bigdata.internal.splitapply.GroupedFunction.wrap(functionHandle);
            end
            options = matlab.bigdata.internal.PartitionedArrayOptions;
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.SlicewiseFusableOperation(numInputs, numOutputs, supportsPreview);
            obj.UnderlyingOperation = matlab.bigdata.internal.lazyeval.SlicewiseOperation(options, functionHandle, numInputs, numOutputs);
            obj.Subs = subs;
            obj.FunctionHandle = functionHandle;
        end
    end
    
    methods
        % Methods overridden in the Operation interface
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            task = createExecutionTasks(obj.UnderlyingOperation, taskDependencies, inputFutureMap);
        end
    end
    
    methods
        % Methods overridden in the SlicewiseFusableOperation interface
        function tf = isSlicewiseFusable(obj)
            tf = isSlicewiseFusable(obj.UnderlyingOperation);
        end
        
        function fh = getCheckedFunctionHandle(obj)
            fh = getCheckedFunctionHandle(obj.UnderlyingOperation);
        end
    end
end

function varargout = subsrefTabularVarFunction(subsrefType, smallSubs, varargin)

if ~isempty(smallSubs)
    % Unwrap special arrays such as BroadcastArray.
    for ii = 1:numel(smallSubs)
        if isa(smallSubs{ii}, 'matlab.bigdata.internal.BroadcastArray')
            smallSubs{ii} = getUnderlying(smallSubs{ii});
        end
    end
    
    varargout = cell(size(varargin));
    
    for ii = 1:numel(varargin)
        if any(strcmp(subsrefType, {'()', '{}'})) % subsrefParens, subsrefBraces
            subs = substruct(subsrefType, [{':'}, smallSubs]);
        else % subsrefDot
            subs = substruct(subsrefType, smallSubs{:});
        end
        varargout{ii} = subsref(varargin{ii}, subs);
    end
else
    % No small indices to apply
    varargout = varargin;
end
end
