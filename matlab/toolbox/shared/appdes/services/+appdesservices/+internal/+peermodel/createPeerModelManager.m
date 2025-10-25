function peerModelManager = createPeerModelManager(uniqueNameSpace, rootNodeType, rootProperties)
% CREATEPEERMODELMANAGER Creates a com.mathworks.peermodel.PeerModelManager
% object
%
%
% Inputs:
%
%   uniqueNameSpace         - A string that represents a unique
%                             namespace for the PeerModelManager to be
%                             created
%
%   rootNodeType            - A string representing the type of
%                             node to create and use for the root Peer Node
%
%   rootNodePropertiesMap   - A Java Map representing the set
%                             of properties for the root Peer Node
%
% Outputs:
%
%   peerModelManager        - The created PeerModelManager.
%
%                             The root will be populated with a node of the
%                             given type and property set.

% Peer Model Manager creation
peerModelManager = com.mathworks.peermodel.PeerModelManagers.getInstance(uniqueNameSpace);
peerModelManager.setSyncEnabled(true);

% Create the Root
peerModelManager.setRoot(rootNodeType, rootProperties);
end