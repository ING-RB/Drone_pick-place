classdef AbstractPanelGC < controllib.ui.internal.dialog.AbstractContainer & ...
                            controllib.ui.internal.dialog.MixedInGC
    %% AbstractPanelGC - Abstract parent class for tool component views.
    %
    %  AbstractPanelGC adds the following three listeners:
    %      1. TC ComponentChanged event listener, which calls the updateUI
    %         method of the dialog.
    %      2. TC ObjectBeingDestroyed event listener, which deletes the
    %         dialog.
    %
    %  AbstractGC public properties:
    %      None
    %
    %  AbstractGC protected properties:
    %      None
    %
    %  AbstractGC public methods:
    %      getPeer - Returns TC peer
    %
    %  See also
    %      controllib.ui.internal.dialog.AbstractContainer
    
    %  Copyright 2021 The MathWorks, Inc.

    %% Constructor/Destructor
    methods
        function this = AbstractPanelGC(tcpeer)
            %% Constructs a dialog object.
            
            % Set property values.
            this.TCPeer = tcpeer;
            
            % Set listeners.
            addTCEventListeners(this)
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
    end
    
    %% Protected methods
    methods(Access = protected)
        function parentFigure = getParentFigure(this)
            % parentFigure = getParentFigure(this)
            %   "parentFigure" is empty if widget is not valid or not
            %   built. Otherwise "parentFigure" is the uifigure which
            %   contains this widget.
            parentFigure = [];
            if this.IsWidgetValid
                parentFigure = ancestor(this.Container,'figure');
            end
        end
    end
    
    %% QE methods (hidden)
    methods (Hidden)
        function qeShow(this,parent)
            arguments
                this
                parent = uigridlayout(uifigure,[1 1]);
            end
            widget = getWidget(this);
            widget.Parent = parent;
            updateUI(this);
        end
    end
    
end