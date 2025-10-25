classdef AbstractDialogGC < controllib.ui.internal.dialog.AbstractDialog & ...
                            controllib.ui.internal.dialog.MixedInGC
    %% ABSTRACTGC - Abstract parent class for tool component views.
    %
    %  AbstractGC adds the following three listeners:
    %      1. TC ComponentChanged event listener, which calls the updateUI
    %         method of the dialog.
    %      2. TC ObjectBeingDestroyed event listener, which deletes the
    %         dialog.
    %      3. Dialog's CloseEvent listener, which deletes the dialog.
    %
    %  Set DeleteOnClose to false to remove the default CloseEvent
    %  listener.
    %
    %  AbstractGC public properties:
    %      None
    %
    %  AbstractGC protected properties:
    %      DeleteOnClose - Deletes the dialog object when clicking the
    %                      cross button. Default value is true.
    %
    %  AbstractGC public methods:
    %      getPeer - Returns TC peer
    %
    %  See also
    %      controllib.ui.internal.dialog.AbstractDialog
    
    %  Copyright 2020 The MathWorks, Inc.

    %% Properties
    properties(Dependent,Access=protected)
        % Flag for deleting the dialog object on close event.
        DeleteOnClose
    end
    
    properties(Access=private)
        % Name of the close event listener.
        CloseEventListenerName = 'DefaultCloseEventListener';
        
        LocalDeleteOnClose = true;
    end
    
    %% Constructor/Destructor
    methods
        function this = AbstractDialogGC(tcpeer)
            %% Constructs a dialog object.
            
            % Set property values.
            this.TCPeer = tcpeer;
            
            % Set listeners.
            addTCEventListeners(this)
            addCloseEventListener(this)
        end
        
    end
    
    %% Set/Get
    methods
        function value = get.DeleteOnClose(this)
            %% Returns current value of DeleteOnClose.
            
            value = this.LocalDeleteOnClose;
        end

        function set.DeleteOnClose(this,delOnClose)
            %% Set value of DeleteOnClose.
            
            if delOnClose == this.LocalDeleteOnClose
                return
            end
            
            this.LocalDeleteOnClose = delOnClose;
            
            if delOnClose
                addCloseEventListener(this)
            else
                unregisterUIListeners(this,this.CloseEventListenerName)
            end
                                
        end
    end
    
    
    %% Private methods
    methods(Access=private)
        function addTCEventListeners(this)
            %% Adds listeners to TC peer events.
            
            registerDataListeners(this,[...
                addlistener(this.TCPeer,'ComponentChanged', ...
                @(src,data)updateUI(this)); ...
                addlistener(this.TCPeer,'ObjectBeingDestroyed', ...
                @(src,data)delete(this)) ...
                ]);
        end
                    
        function addCloseEventListener(this)
            %% Adds close event listener.
            registerUIListeners(this,addlistener(this,'CloseEvent', ...
                @(src,data)close(this)),this.CloseEventListenerName)
        end
    end
end