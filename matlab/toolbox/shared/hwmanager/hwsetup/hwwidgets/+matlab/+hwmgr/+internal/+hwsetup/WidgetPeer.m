classdef (Abstract) WidgetPeer < handle
    %WIDGETPEER provides an interface to define a Peer property that is a
    %handle to implementation specific UI object
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    properties(SetAccess = protected, ...
        GetAccess = {?hwsetup.testtool.TesterBase, ?matlab.hwmgr.internal.hwsetup.WidgetPeer})
        %Peer - Handle to the UI object
        Peer
    end
    
    methods(Abstract, Static)
        %WIDGETPEER = CREATEWIDGETPEER(PARENTPEER) creates a technology 
        %    specific ui widget, parents it to parentPeer and returns a 
        %    handle -  widgetPeer to the ui object. If the parentpeer is an
        %    invalid handle then createWidgetPeer throws an error. The
        %    visibility of widgetPeer is turned off in the
        %    createWidgetPeer. The visibility should be explicitly set
        %    using the SHOW method.
        
        widgetPeer = createWidgetPeer(parentPeer);
    end
    
    methods
        function delete(obj)
            %DELETE(OBJ) deletes the peer for the object
            if ismethod(obj.Peer, 'delete')
                delete(obj.Peer)
            end
        end
    end
end
