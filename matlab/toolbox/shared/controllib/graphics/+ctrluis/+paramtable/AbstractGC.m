classdef AbstractGC < controllib.ui.internal.dialog.AbstractDialog
    %%
    
    % ABSTRACTGC - Abstract parent class for tool component views.
    
    %  Copyright 2020 The MathWorks, Inc.

    %% Properties
    properties(GetAccess=protected,SetAccess=private)
        % Tool component peer
        TCPeer            
    end
    
    %% Constructor/Desctructor
    methods
        function this = AbstractGC(tcpeer)
            %% ABSTRACTGC Construct AbstractGC
            
            this.TCPeer = tcpeer;
            this.CloseMode = 'destroy';
            registerListeners(this)            
        end
    end
    
    %% Public methods
    methods
        function tc = getPeer(this)
            %% Returns tool component peer.
            
            % Adding this method for back compatibility.
            tc = this.TCPeer;
        end
                
        function dlg = getDialog(this)
            %% Returns reference of the visual component.
            
            % Adding this method for back compatibility. The getWidget
            % method on MixedInDialog class provides the functionality.
            dlg = this.UIFigure;
        end
    end
    
    %% Private methods.
    methods(Access=private)
        function registerListeners(this)
            %% Register listeners 
            
            % Update UI when TC is changed.
            registerDataListeners(this,addlistener(this.TCPeer, ...
                'ComponentChanged',@(src,data)updateUI(this)));
            
            % If TC is destroyed, delete Dialog.
            registerDataListeners(this,addlistener(this.TCPeer, ...
                'ObjectBeingDestroyed',@(src,data)delete(this)));
        end
    end
end