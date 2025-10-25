classdef BusyOverlay < matlab.hwmgr.internal.hwsetup.Widget
    %BUSYOVERLAY This class provides an instance of a BusyOverlay widget as
    % a result of calling getInstance. This widget renders an animated
    % spinning icon to indicate an operation is in progress.
    %
    %   BUSYOVERLAY Widget Properties
    %   Visible               -Widget visibility specified as 'on' or 'off'
    %   Text                  -Text displayed below the spinning icon
    %   Position (Read-Only)   -Position of the icon [0 0 470 390]
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   b = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(p);
    %   b.Text = 'Loading...';
    %   b.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties
        %Text - text to be displayed on the overlay
        Text
    end
    
    methods(Access = protected)
        function obj = BusyOverlay(varargin)
            %BusyOverlay constructor
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            obj.Text = message('hwsetup:widget:BusyOverlayText').getString;
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            %getInstance - returns instance of BusyOverlay object
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end
    
    methods
        function set.Text(obj, text)
            %set.Text - set the text specified by user by passing it to the
            %technology specific setText implementation.
            validateattributes(text, {'char', 'string'}, {});
            obj.setText(text);
            obj.Text = text;
        end
    end
    
    methods(Abstract, Access = protected)
        %setText - Technology specific implementation for setting text
        setText(obj, text)
    end
end

% LocalWords:  hwmgr hwsetup
