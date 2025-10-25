classdef ViewModelSynchronizer < handle
%

%   Copyright 2019 The MathWorks, Inc.

    properties(Access = ?gbttest.util.FigureControllerTestHelper)
        Model
        Channel
        Sync
        Transaction
    end
    
    methods(Static)
        % There should only be 1 synchronizer per figure. You should call get
        % if you are a child of the figure.
        % The synchronizer will be destroyed when cleanup goes out of scope.
        function cleanup = createSynchronizer(channelPrefix)
            cleanup = matlab.ui.internal.controller.ViewModelSynchronizer.singletonMapImpl('create', channelPrefix);
        end
        
        function synchronizer = getSynchronizer(channelPrefix)
            synchronizer = matlab.ui.internal.controller.ViewModelSynchronizer.singletonMapImpl('get', channelPrefix);
        end

        function synchronizer = hasSynchronizer(channelPrefix)
            synchronizer = matlab.ui.internal.controller.ViewModelSynchronizer.singletonMapImpl('has', channelPrefix);
        end
    end
        
    methods
        function object = createObject(this, classConstructor, varargin)
            object = classConstructor(this.Model, varargin{:});
        end
        
        function commit(this)
            matlab.graphics.internal.logger('log', 'DrawnowTimeout', 'ViewModelSynchronizer.commit')
            this.Transaction.commit
            this.Transaction = this.Model.beginTransaction;
        end
    end
    
    methods (Access = 'private')
        function this = ViewModelSynchronizer(channelPrefix)
            this.Model = mf.zero.Model;
            % GraphicsConnectorChannel knows how to integrate with
            % "drawnow nocallbacks"
            this.Channel = mf.zero.io.GraphicsConnectorChannel([channelPrefix '/viewModelSynchronizerServer'], ...
                                                               [channelPrefix '/viewModelSynchronizerClient']);
            this.Sync = mf.zero.io.ModelSynchronizer(this.Model, this.Channel);
            this.Sync.start
            this.Transaction = this.Model.beginTransaction;
        end
    end
    
    methods(Static, Access = 'private')
        function out = singletonMapImpl(operation, channelPrefix)            
            mlock
            persistent singletonMap
            if isempty(singletonMap)
                singletonMap = containers.Map;
            end
            
            out = [];
            if strcmp(operation,'destroy')
                if ~singletonMap.isKey(channelPrefix)
                    % Do not error if attempting to destroy something
                    % that has already been destroyed.
                    return
                end
                delete(singletonMap(channelPrefix))
                singletonMap.remove(channelPrefix);
            elseif strcmp(operation , 'create')
                if singletonMap.isKey(channelPrefix)
                    error(['ViewModelSynchronizer already exists for ' channelPrefix])
                end
                singletonMap(channelPrefix) = matlab.ui.internal.controller.ViewModelSynchronizer(channelPrefix);
                out = onCleanup(@()matlab.ui.internal.controller.ViewModelSynchronizer.singletonMapImpl('destroy', channelPrefix));
            elseif strcmp(operation, 'has')
                out = singletonMap.isKey(channelPrefix);                    
            elseif strcmp(operation, 'get')
                if ~singletonMap.isKey(channelPrefix)
                    error(['ViewModelSynchronizer has not been created for ' channelPrefix])
                end
                out = singletonMap(channelPrefix);
            else
                error(['Incorrect operation ' operation])
            end
        end
    end
end
