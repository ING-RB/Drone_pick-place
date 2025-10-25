classdef WindowPanelAdaptor < matlab.hwmgr.internal.hwsetup.Window & matlab.hwmgr.internal.rootpane.PeerAccessible
    % This class adapts a hardware manager panel into a hardware setup
    % window for compatibility when hosting hardware setup within hardware
    % manager.
    
    % Copyright 2017-2020 The Mathworks, Inc.
    
    
    methods
        % Constructor
        function obj = WindowPanelAdaptor(hardwareManagerPanel)
            obj@matlab.hwmgr.internal.hwsetup.Window(hardwareManagerPanel);
        end
        
        function bringToFront(obj)
            % This method is invoked by hardware setup workflow's launch()
            % method and should bring the running hardware setup into focus.
            % In this case, the hardware manager window will be focused.
            % Hardware manager figure -> hardware manager panel -> hardware
            % setup panel
            figure(obj.Peer.Parent.Parent);
        end
        
    end
    
    
end