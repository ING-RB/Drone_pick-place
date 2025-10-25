%AdvancedGroupedFunction
% Function that applies an action once per group per chunk, for a set of
% inputs that consist of the same groups, but where groups are allowed to
% have different heights.
%
% Note:
%  1. The input is expected to already be split into groups.
%  2. The same groups must be present across all inputs.
%  3. Each input is allowed to have groups of different heights compared to
%     other inputs.
%  4. Each output is allowed to have groups of different heights compared
%     to other outputs.

% Copyright 2017 The MathWorks, Inc.

classdef AdvancedGroupedFunction < handle & matlab.mixin.Copyable
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
            %   keyedFcn = GroupedFunction.wrap(fcnHandle)
            %
            import matlab.bigdata.internal.splitapply.AdvancedGroupedFunction;
            functionHandle = functionHandle.copyWithNewHandle(...
                AdvancedGroupedFunction(functionHandle.Handle, varargin{:}));
        end
    end
    
    methods
        function [varargout] = feval(obj, varargin)
            % Apply the grouped action to the given groups of inputs.
            %
            % Syntax:
            %  [outKeys1,outCounts1,out1,..] = feval(obj,inKeys1,inCounts1,in1,..);
            %
            import matlab.bigdata.internal.splitapply.GroupedBroadcast;
            
            numInputs = (nargin - 1) / 3;
            assert(mod(numInputs, 1) == 0, ...
                'Assertion failed: AdvancedGroupedFunction must receive inputs in <key,count,value> tuples');
            
            numOutputs = nargout / 3;
            assert(mod(numOutputs, 1) == 0, ...
                'Assertion failed: AdvancedGroupedFunction can only emit outputs in <key,count,value> tuples');
            
            % We ignore input group counts, they're not useful for the
            % calculation. We still declare them as input so that any
            % upstream assertion from GroupedPartitionedArray still runs.
            inGroupKeys = varargin(1:3:end);
            varargin = varargin(3:3:end);
            
            [isInputNormalBroadcast, isInputGroupedBroadcast] = isBroadcast(varargin{:});
            isInputAnyBroadcast = isInputNormalBroadcast | isInputGroupedBroadcast;
            
            % This operation asserts all inputs consists of the same
            % groups. We just pick out one set of group keys here, later we
            % will assert all the rest are the same after canonicalization.
            if all(isInputAnyBroadcast)
                outGroupKeys = inGroupKeys{find(isInputGroupedBroadcast, 1, 'first')};
                outGroupKeys = outGroupKeys.Keys;
            else
                outGroupKeys = inGroupKeys{find(~isInputAnyBroadcast, 1, 'first')};
            end
            outGroupKeys = unique(outGroupKeys);
            
            % Now to parse all inputs, ensuring they align with group keys
            % picked out earlier.
            for ii = 1 : numInputs
                if isInputNormalBroadcast(ii)
                    % Do nothing.
                elseif isInputGroupedBroadcast(ii)
                    [varargin{ii}] = flattenGroupedBroadcasts(outGroupKeys, varargin{ii});
                else
                    [inGroupKeys{ii}, varargin{ii}] = canonicalizeGroups(inGroupKeys{ii}, varargin{ii});
                    assert(isequal(inGroupKeys{ii}, outGroupKeys), ...
                        'Assertion failed: Grouping mismatch.');
                end
            end
            
            % Now all inputs are aligned, we can do the actual work.
            out = applyToGroups(obj.Handle, numOutputs, outGroupKeys, varargin{:});
            outGroupCounts = cellfun(@iHeight, out);
            
            % Finally, we need to split out the outputs into
            % <key,count,value> tuples. For each individual output, if that
            % output can be group broadcasted (i.e. a single chunk with a
            % single slice per group), we must do that here. This is to
            % allow successor operations to use singleton expansion.
            isAllInputBroadcast = obj.IsInputGuaranteedBroadcast || all(isInputNormalBroadcast | isInputGroupedBroadcast);
            varargout = cell(1, nargout);
            for ii = 1 : numOutputs
                outBaseIdx = ii * 3 - 2;
                varargout{outBaseIdx} = outGroupKeys;
                varargout{outBaseIdx + 1} = outGroupCounts(:, ii);
                varargout{outBaseIdx + 2} = out(:, ii);
                if isAllInputBroadcast && all(varargout{outBaseIdx + 1} == 1)
                    [varargout{outBaseIdx + (0:2)}] = groupBroadcast(varargout{outBaseIdx + (0:2)});
                end
            end
        end
    end
    
    methods (Access = private)
        function obj = AdvancedGroupedFunction(handle, varargin)
            % Private constructor for the wrap method.
            p = inputParser();
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
            import matlab.bigdata.internal.splitapply.AdvancedGroupedFunction
            if isa(obj.Handle, 'matlab.mixin.Copyable')
                obj = AdvancedGroupedFunction(copy(obj.Handle), ...
                    'IsInputGuaranteedBroadcast', obj.IsInputGuaranteedBroadcast);
            end
        end
    end
end

function out = iHeight(in)
% Helper function for calculating the height.
out = size(in,1);
end
