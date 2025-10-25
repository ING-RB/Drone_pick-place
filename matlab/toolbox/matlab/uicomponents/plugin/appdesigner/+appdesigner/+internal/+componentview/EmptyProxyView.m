classdef EmptyProxyView < appdesservices.internal.interfaces.view.AbstractProxyView
    % EmptyProxyView The ProxyView which has no-op 
    % and is just for retrieving PV pairs when loading an app or getting 
    % design time component defaults
    %
    % In the future, if the runtime and design time logic can be separated
    % for the controller, and no need to check whehter the proxyview is
    % empty or not to determine design time, we can get rid of this no-op
    % proxyview for loading and getting defaults
    
    % Copyright 2016 - 2023 The MathWorks, Inc.
        
    properties(GetAccess = 'public', SetAccess = 'private')
        % Proxy view's properties have been synced to the model or not
        HasSyncedToModel;
        
        % PeerNode to meet the requirement of the real proxyview
        PeerNode;
        
        % Adapter property to meet the requirement of the real proxyview
        Adapter;

        % Flag to set if this is during loading an app in App Designer
        IsLoaded = false;
    end
    
    methods(Access=public)
        function obj = EmptyProxyView(isLoaded)
            obj.HasSyncedToModel = true;
            obj.PeerNode = appdesservices.internal.interfaces.view.EmptyViewModel.Instance;
            obj.Adapter = [];
            if nargin == 1
                obj.IsLoaded = isLoaded;
            end
        end
        
        function setProperties(obj, pvPairs)
            % no-op
        end
        
        function id = getId(obj)
            id = '';
        end
        
        function valueStruct = getProperties(obj)
            valueStruct = struct();
        end
    end
end


