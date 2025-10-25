classdef HelpText < matlab.hwmgr.internal.hwsetup.HelpText
    %matlab.hwmgr.internal.hwsetup.appdesigner.HelpText is a class that
    %implements HelpText widget. It renders three text areas for display.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.HelpText
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for HelpText
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.HelpTextWrapper(aParent);
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = HelpText(varargin)
            %HelpText - constructor to set defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.HelpText(varargin{:});
            
            %This listener will invoke the destructor of the BusyOverlay
            %when it's parent is destroyed.
            addlistener(obj.Parent, 'ObjectBeingDestroyed',...
                @obj.parentDeleteCallback);
        end
    end
    
    methods(Access = protected)
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete BusyOverlay when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
    
    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods (Access = protected)
        function setAboutSelection(obj, value)
            obj.Peer.AboutSelection = value;
        end
        
        function setWhatToConsider(obj, value)            
            obj.Peer.WhatToConsider = value;
        end
        
        function setAdditional(obj, value)            
            obj.Peer.Additional = value;
        end
    end

    %----------------------------------------------------------------------
    % getter methods
    %----------------------------------------------------------------------
    methods (Access = protected)
        function value = getAboutSelection(obj)
            %getAboutSelection - get text for AboutSelection
            
            value = obj.Peer.AboutSelection;
        end
        
        function value = getWhatToConsider(obj)
            %getWhatToConsider - get text for WhatToConsider
            
            value = obj.Peer.WhatToConsider;
        end
        
        function value = getAdditional(obj)
            %getAdditional - get text for Additional
            
            value = obj.Peer.Additional;
        end
    end
end