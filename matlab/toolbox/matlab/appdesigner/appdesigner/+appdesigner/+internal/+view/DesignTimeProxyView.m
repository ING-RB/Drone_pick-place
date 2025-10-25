classdef DesignTimeProxyView < appdesservices.internal.peermodel.PeerNodeProxyView
    % DesignTimeProxyView The ProxyView which wraps PeerNodes
    %
    % DesignTimeProxyView processes the property data to be set on
    % a component
    
    % Copyright 2014-2019 The MathWorks, Inc.
    
    properties(GetAccess = 'public', SetAccess = 'private')
        % Proxy view's proeprties have been synced to the model or not
        HasSyncedToModel = false;
    end
    
    methods(Access=public)
        function obj = DesignTimeProxyView(peerNode, hasSyncedToModel)
            % Error Checks
            narginchk(1, 2);
            % Add assertion for ViewModel interface which is part of effort
            % to get rid of PeerModel
            assert(appdesservices.internal.peermodel.PeerNodeProxyView.isNode(peerNode));
            
            obj@appdesservices.internal.peermodel.PeerNodeProxyView(peerNode);
            
            if nargin == 2
                obj.HasSyncedToModel = hasSyncedToModel;
            end            
        end
    end
    
    methods (Access = protected)
        function deletePeerNode(~)
            % no-op for design-time
            % since the peernode is client-driven to delete.
            % Under ViewModel mode, if deleting on both client and MATLAB
            % side, an exception would be thrown from mf0
        end
    end
end