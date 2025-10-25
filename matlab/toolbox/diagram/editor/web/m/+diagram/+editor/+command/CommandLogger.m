classdef CommandLogger < handle
    %CommandLogger ...
    
    methods (Abstract)
        logRequest(self, request);
        logResponse(self, response);
    end
    
    methods
        function self = CommandLogger()
            self.m_uuid = diagram.editor.command.CppCommandLogger.generateNewUUID();
        end
        
        function installed = isInstalled(self)
            installed = self.getCppPeer.isInstalled();
        end
        
        function uninstalled = uninstall(self)
            peer = self.getCppPeer;
            uninstalled = peer.uninstall();
        end
        
        function delete(self)
            self.uninstall();
        end
    end
    
    properties (Access = private)
        m_uuid;
    end
    
    methods (Sealed, Hidden)
        function uuid = getUUID(self)
            uuid = self.m_uuid;
        end
    end
    
    methods (Sealed, Hidden, Access = protected)
        function peer = getCppPeer(self)
            peer = diagram.editor.command.CppCommandLogger.getCppPeer(self);
        end
    end
    
    
end