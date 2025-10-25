classdef absGC < handle
    %
    
    % Author(s): A. Stothert 15-Mar-2011
    % Copyright 2011-2012 The MathWorks, Inc.
    % $Revision: 1.1.4.2 $ $Date: 2014/04/19 02:50:34 $
    
    % ABSGC  Abstract parent class for component views
    %
    %  Class provides common graphical view properties and methods to aid
    %  testing
    %
    
    properties(GetAccess = protected, SetAccess = protected)
        TCPeer       %Tool-Component peer
        TCListeners  %Tool-Component listeners
        
        Dlg               %Dialog handle
        Panel             %Main Panel handle
        GUIListeners      %GUI listeners
    end
    
    methods(Access = protected)
        function obj = absGC(tcpeer)
            %ABSGC Construct an absGC object
            %
            
            obj.TCPeer = tcpeer;
            connectTC(obj)
        end
    end
    
    methods(Access = public)
        function tc = getPeer(this)
            %GETPEER
            %
            
            tc = this.TCPeer;
        end
        function dlg = getDialog(this)
            %GETDIALOG
            %
            
            dlg = this.Dlg;
        end
        function pnl = getPanel(this)
            %GETPANEL
            %
            
            pnl = this.Panel;
        end
    end
    
    methods(Access = protected)
        function connectTC(this)
            %CONNECTTC Connect the Graphical component to a tool component
            %
            
            %Add Listeners for tool component change and destroy events
            this.TCListeners = {...
                addlistener(this.TCPeer,'ComponentChanged', @(hSrc,hData) update(this)); ...
                addlistener(this.TCPeer,'ObjectBeingDestroyed', @(hSrc,hData) cleanup(this))};
            
            %Add listener to our own delete so we can disconnect from TC
            addlistener(this,'ObjectBeingDestroyed', @(hSrc,hData) disconnectTC(this));
        end
        function disconnectTC(this)
            %DISCONNECTTC Drop connection to Tool component
            %
            
            %Destroy any tool-component listeners
            tcl = this.TCListeners;
            this.TCListeners = [];
            if iscell(tcl)
                for ct=1:numel(tcl)
                    delete(tcl{ct});
                end
            else
                delete(tcl);
            end
        end
        function cleanup(this)
            %CLEANUP Cleanup object for destruction
            %
            if isvalid(this)
                %Cleanup the GUI
                cleanupGUI(this)
            
                %Drop connection to tool-component
                disconnectTC(this)
                
                %Delete ourselves
                delete(this)
            end
        end
    end
    
    methods(Abstract = true, Access = protected)
        update(this)
        cleanupGUI(this)
    end

    methods(Abstract = true, Access = public)
        wdgts = getWidgets(this);
        show(this,hAnchor,floating)
    end
end