classdef AbstractGC < ctrluis.component.AbstractUI
    % Master super class for all the GC components
    % sub-classes include AbstractDialogGC and AbstractPanelGC
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    %% Protected properties
    properties(Access = protected)
        % Tool Component peer
        TCPeer       
    end
    
    %% Public methods
    methods (Hidden)

        function this = AbstractGC(tcpeer)
            % The constructor takes in an AbstractTC object
            
            % store the TC reference
            this.TCPeer = tcpeer;
            % add listener such that if TC data changes, GC updates UI
            addlistener(this.TCPeer,'ComponentChanged', @(hSrc,hData) updateUI(this));
            % add listener such that if TC is deleted, delete GC
            addlistener(this.TCPeer,'ObjectBeingDestroyed', @(hSrc,hData) delete(this));
        end
        
    end
    
    methods
        
        function tc = getPeer(this)
            % return TC peer
            tc = this.TCPeer;
        end
        
    end
        
end