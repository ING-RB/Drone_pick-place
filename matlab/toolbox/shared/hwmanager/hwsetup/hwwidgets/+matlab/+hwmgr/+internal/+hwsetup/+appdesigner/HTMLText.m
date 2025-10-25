classdef HTMLText < matlab.hwmgr.internal.hwsetup.HTMLText
    %matlab.hwmgr.internal.hwsetup.appdesigner.HTMLText is a class that
    %implements HTMLText. Its uses a uilabel with interpreter html.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.HTMLText
    
    % Copyright 2020-2021 The MathWorks, Inc.

    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for HTMLText
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTextWrapper(aParent);
            aPeer.BackgroundColor = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = HTMLText(varargin)
            %HTMLText - constructor to set defaults.

            obj@matlab.hwmgr.internal.hwsetup.HTMLText(varargin{:});
            
            %this listener will invoke the destructor of the
            %DeviceInfoTable when it's parent is destroyed
            addlistener(obj.Parent,...
                'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
    end
    
    methods(Access = protected)
        function setText(obj, text)
            obj.Peer.Text = text;
        end
        
        function text = getText(obj)
            text = char(obj.Peer.Text);
        end
        
        function color = getBackgroundColor(obj)
            color = obj.Peer.BackgroundColor;
        end
        
        function setBackgroundColor(obj, color)
            obj.Peer.BackgroundColor = color;
        end
        
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete HTMLText when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
end