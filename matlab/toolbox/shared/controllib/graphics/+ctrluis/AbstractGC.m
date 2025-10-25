classdef AbstractGC < controllib.ui.internal.dialog.AbstractDialog
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
    
    %  Copyright 2020-2021 The MathWorks, Inc.

    %% Properties
    properties(GetAccess=protected,SetAccess=private)
        %Tool-Component peer
        TCPeer            
    end
    
    properties(Dependent,Access=protected)
        % Flag for deleting the dialog object on close event.
        DeleteOnClose
    end
    
    properties(Access=private)
        % Name of the close event listener.
        CloseEventListenerName = 'DefaultCloseEventListener';
        
        LocalDeleteOnClose = true;
    end

    properties(Hidden)
        ShowButtons = true;
        ShowHelpButton = true;
        Padding = 10;
        RowSpacing = 5;
        ColumnSpacing = 5;
    end
    
    %% Constructor/Desctructor
    methods
        function this = AbstractGC(tcpeer)
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
    
    %% Public methods
    methods        
        function peer = getPeer(this)
            %% Returns TC peer.
           
           % Adding this method for back compatibility.
           peer = this.TCPeer;
        end
    end
    
    %% Private methods
    methods(Access=private)
        function addTCEventListeners(this)
            %% Adds listeners to TC peer events.
            weakThis = matlab.lang.WeakReference(this);
            registerDataListeners(this,[...
                addlistener(this.TCPeer,'ComponentChanged', ...
                @(src,data)updateUI(weakThis.Handle)); ...
                addlistener(this.TCPeer,'ObjectBeingDestroyed', ...
                @(src,data)delete(weakThis.Handle)) ...
                ]);
        end
                    
        function addCloseEventListener(this)
            %% Adds close event listener.
            weakThis = matlab.lang.WeakReference(this);
            registerUIListeners(this,addlistener(this,'CloseEvent', ...
                @(src,data)delete(weakThis.Handle)),this.CloseEventListenerName)
        end
    end
end