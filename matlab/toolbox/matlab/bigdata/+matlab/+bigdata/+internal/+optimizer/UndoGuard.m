%UndoGuard
% RAII class that reverses all optimizer actions in case of error.
%
% If an error occurs during gather, we want to ensure that predecessors to
% the operation that errored are not tied to it's failure.

% Copyright 2016-2024 The MathWorks, Inc.

classdef UndoGuard < handle
    
    properties (SetAccess = private)
        % The original ClosureFuture objects prior to optimization.
        OriginalFutures = matlab.bigdata.internal.lazyeval.ClosureFuture.empty();
        
        % The new ClosureFuture objects post optimization.
        OptimizedFutures = matlab.bigdata.internal.lazyeval.ClosureFuture.empty();
    end
    
    properties (Dependent)
        % A logical scalar that is true if this guard has actions to
        % perform on destruction.
        HasActions;
    end
    
    methods
        function tf = get.HasActions(obj)
            tf = ~isempty(obj.OriginalFutures);
        end
        
        function delete(obj)
            % Perform the revert action if this has not already be
            % disarmed.
            originalFutures = obj.OriginalFutures;
            optimizedFutures = obj.OptimizedFutures;
            for ii = numel(optimizedFutures) : -1 : 1
                if ~originalFutures(ii).IsDone
                    swap(originalFutures(ii), optimizedFutures(ii));
                elseif ~originalFutures(ii).IsPartitionIndependent
                    % Partition dependent futures hold onto the upstream
                    % operation graph even when done. We need to undo the
                    % optimization on this, even though we are still
                    % marking the future as done.
                    swap(originalFutures(ii), optimizedFutures(ii));
                    setValue(originalFutures(ii).Promise, optimizedFutures(ii).Value);
                end
            end
        end
        
        function disarm(obj)
            % Disarm the cleanup. The optimized futures will no longer be
            % reverted on destruction of this object.
            import matlab.bigdata.internal.lazyeval.ClosureFuture;
            obj.OriginalFutures = ClosureFuture.empty();
            obj.OptimizedFutures = ClosureFuture.empty();
        end

        function swapAndAppend(obj, originalFutures, optimizedFutures)
            % Swap the given original and optimized futures and then add to
            % the UndoGuard.
            assert(numel(originalFutures) == numel(optimizedFutures), ...
                'UndoGuard must be given the same number of optimized as original futures');
            for ii = 1:numel(originalFutures)
                swap(originalFutures(ii), optimizedFutures(ii));
            end
            obj.OriginalFutures = [obj.OriginalFutures; originalFutures(:)];
            obj.OptimizedFutures = [obj.OptimizedFutures; optimizedFutures(:)];
        end
        
        function obj = combine(varargin)
            % Combine 2 or more UndoGuard objects. In the combined
            % object, futures will be reverted in reverse order.
            import matlab.bigdata.internal.optimizer.UndoGuard;
            objs = vertcat(varargin{:});
            originalFutures = vertcat(objs.OriginalFutures);
            optimizedFutures = vertcat(objs.OptimizedFutures);
            obj = UndoGuard();
            obj.OriginalFutures = originalFutures;
            obj.OptimizedFutures = optimizedFutures;
            for ii = 1 : numel(varargin)
                disarm(varargin{ii});
            end
        end
    end
end
