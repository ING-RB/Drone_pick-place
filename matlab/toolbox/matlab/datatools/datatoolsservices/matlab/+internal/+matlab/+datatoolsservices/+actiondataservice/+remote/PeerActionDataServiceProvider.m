classdef PeerActionDataServiceProvider
    %PEERNODEACTIONPROVIDER PeerActionDataServiceProvider is a peermodel provider for the ActionDataService.
    % Creates the PeerModelServer either as a client or server instance and
    % enables synchronization.
        
    %TODO: Legacy file, deprecate all peer versions as a follow-up
    %(g2446528).
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties 
       PeerModelServer;
    end
    
   properties (SetAccess='protected')
       Namespace = "/Actions/DefaultNameSpace";       
       RootType = "Root";
       Root
   end
    
    methods
        function this = PeerActionDataServiceProvider(namespace)
            if (nargin > 0)
                this.Namespace = namespace;
            end
            this.PeerModelServer = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider(this.Namespace);
            this.Root = this.PeerModelServer.getRoot();        
        end
        
         function modelServer = get.PeerModelServer(this)
            modelServer = this.PeerModelServer;
         end       
         
         function peerAction = addAction(this, action)
             peerAction = internal.matlab.datatoolsservices.actiondataservice.remote.PeerActionWrapper(action, this.getRoot());                          
         end     
        
         % TODO:Mark file for delete
         function delete(this)
%             if ~isempty(this.PeerModelServer) && isvalid(this.PeerModelServer)                 
%                 peermodel.internal.PeerModelManagers.deleteManager(this.PeerModelServer);                
%             end            
         end           
        
        % Gets the root of the peerTree. Creates a new root on the 
        % PeerModelServer if one does not exist. 
        function root =  getRoot(this)          
            this.createRoot(this.RootType);
            root = this.PeerModelServer.getRoot();
        end    
    end
      % Protected methods
    methods(Access='protected')        
        function createRoot(this, RootType)
            if isempty(this.PeerModelServer.getRoot()) && ~eq(this.Mode, "ActAsClient")
                this.PeerModelServer.createRoot(RootType);
            end
        end               
    end       
end

