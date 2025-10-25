%GroupedFunction
% Function that applies an action once per group per chunk, for a set of
% inputs that consist of the same groups and group heights.
%
% This requires the group keys and counts across multiple inputs to have
% been merged before invoking this function.
%
% Note:
%  1. The input is expected to already be split into groups.
%  2. Multiple inputs are expected to have identical grouping.
%  3. Multiple outputs are expected to have identical grouping.

% Copyright 2016-2017 The MathWorks, Inc.

classdef GroupedFunction < handle & matlab.mixin.Copyable
    properties (SetAccess = immutable)
        % Underlying function handle.
        Handle
        
        % Logical scalar flag that specifies if single slice per group
        % output should be wrapped as a GroupedBroadcast.
        IsInputGuaranteedBroadcast;
    end
    
    methods (Static)
        function functionHandle = wrap(functionHandle, varargin)
            % Wrap a FunctionHandle with the logic to invoke over groups of
            % data.
            %
            % Syntax:
            %   keyedFcn = GroupedFunction.wrap(fcnHandle, name1, value1, ..)
            %
            % Where the optional name-value parameters consist of:
            %
            %  IsInputGuaranteedBroadcast: A flag that specifies if all
            %  input are guaranteed broadcast. If true, any output that is
            %  single slice per group is automatically group broadcasted.
            %  By default this is false.
            import matlab.bigdata.internal.splitapply.GroupedFunction;
            functionHandle = functionHandle.copyWithNewHandle(...
                GroupedFunction(functionHandle.Handle, varargin{:}));
        end
    end
    
    methods
        function [groupKeys, groupCounts, varargout] = feval(obj, groupKeys, groupCounts, varargin)
            % Apply the grouped action to the given groups of inputs.
            import matlab.bigdata.internal.util.validateSameOutputHeight;
            
            % In the case of no groups, return zero chunks.
            if isempty(groupKeys)
                varargout = repmat({cell(0, 1)}, 1, nargout - 2);
                return;
            end
            
            % If all inputs are broadcasts, we are in a special case where
            % the output ought to follow broadcast logic as well. For example,
            % splitapply(@(x) sin(sum(x,1)),tX,tG) would generate a single
            % row per group output from sum(x,1). This input, both its data
            % and its keys, will be put into a GroupedBroadcast state. The
            % sin elementfun will hit true here.
            if isa(groupKeys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
                groupKeys = groupKeys.Keys;
            end
            
            [isInputNormalBroadcast, isInputGroupedBroadcast] = isBroadcast(varargin{:});
            
            % If the input consists of the vertical concatenation of two
            % chunks, it will contain the same group key multiple times. We
            % need to fuse those groups together. This is typical in most
            % reductions, e.g. splitapply(@(x) sum(x,1),tX,tG).
            [groupKeys, varargin{:}] = canonicalizeGroups(groupKeys, varargin{:});
            
            % Each GroupedBroadcast contains values for all known groups
            % across the tall array. We need to extract the ones that match
            % the groups that exist in this chunk. Note, this is not a
            % direct indexing operation, as 0 can also be a key. This 0 key
            % corresponds to NaN GNUM values.
            if any(isInputGroupedBroadcast)
                [varargin{isInputGroupedBroadcast}] = flattenGroupedBroadcasts(groupKeys, varargin{isInputGroupedBroadcast});
            end
            
            % We're now in a good state to apply the actual operation to
            % the data.
            numOutputs = nargout - 2;
            varargout = applyToGroups(obj.Handle, numOutputs, groupKeys, varargin{:});
            
            % This is the assertion that all outputs have the same
            % height.
            groupCounts = zeros(numel(groupKeys), 1);
            for ii = 1:size(groupKeys, 1)
                groupCounts(ii) = validateSameOutputHeight(varargout{ii, :});
            end
            varargout = num2cell(varargout, 1);
            
            % In order to allow singleton expansion, we wrap the special
            % case where all groups have height 1 in a scalar GroupedBroadcast.
            isAllInputBroadcast = obj.IsInputGuaranteedBroadcast || all(isInputNormalBroadcast | isInputGroupedBroadcast);
            if isAllInputBroadcast && all(groupCounts == 1)
                [groupKeys, groupCounts, varargout{:}] = groupBroadcast(groupKeys, groupCounts, varargout{:});
            end
        end
    end
    
    methods (Access = private)
        function obj = GroupedFunction(handle, varargin)
            % Private constructor for the wrap method.
            import matlab.bigdata.internal.FunctionHandle;
            
            p = inputParser;
            p.addParameter('IsInputGuaranteedBroadcast', false, @(x) islogical(x) && isscalar(x));
            p.parse(varargin{:});
            
            obj.Handle = handle;
            obj.IsInputGuaranteedBroadcast = p.Results.IsInputGuaranteedBroadcast;
        end
    end
    
    methods (Access = protected)
        function obj = copyElement(obj)
            % Perform a deep copy of this object and everything underlying
            % it.
            import matlab.bigdata.internal.splitapply.GroupedFunction
            if isa(obj.Handle, 'matlab.mixin.Copyable')
                obj = GroupedFunction(copy(obj.Handle), ...
                    'IsInputGuaranteedBroadcast', obj.IsInputGuaranteedBroadcast);
            end
        end
    end
end
