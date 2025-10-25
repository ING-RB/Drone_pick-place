classdef EditText < matlab.hwmgr.internal.hwsetup.EditText & ...
        matlab.hwmgr.internal.hwsetup.mixin.FontProperties
    % matlab.hwmgr.internal.hwsetup.appdesigner.EditText is a class that implements a
    % HW Setup edit box using uieditfield.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.EditText
    
    % Copyright 2019-2021 The MathWorks, Inc.
    
    properties(Access = private, SetObservable)
        % Value property on uieditfield is not defined to be SetObservable.
        % Hence, we cannot listen for changes. Define our own property to
        % do this.
        Value
    end
    
    methods(Static)
        function aPeer = createWidgetPeer(parentPeer)
            validateattributes(parentPeer, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = uieditfield('Parent', parentPeer,...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize(),...
                'Visible','on');
        end
    end
    
    methods
        function set.Value(obj, value)
           obj.Value = value; 
        end
    end
    
    methods(Access = protected)
        function setCallback(obj)
            obj.Peer.ValueChangedFcn = @obj.editTextCallbackHandler;
        end
        
        function editTextCallbackHandler(obj, varargin)
            %varargin should be two elements an object and an event
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(varargin{2}, {'event.PropertyEvent', 'matlab.ui.eventdata.ValueChangedData'}, {});
            obj.safeCallbackInvoke(obj.ValueChangedFcn, varargin{2});
        end
        
        function setText(obj, value)
            % ValueChangedFcn for uieditfield gets triggered only when
            % value changes from UI.
            obj.Peer.Value = value;
            % set Value property to trigger PostSet listener
            obj.Value = value;
        end
        
        function setTextAlignment(obj, value)
            obj.Peer.HorizontalAlignment = value;
        end
        
        function text = getText(obj)
            text = char(obj.Peer.Value);
        end
        
        function alignment = getTextAlignment(obj)
            alignment = char(obj.Peer.HorizontalAlignment);
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = EditText(varargin)
            obj@matlab.hwmgr.internal.hwsetup.EditText(varargin{:});
            addlistener(obj, 'Value', 'PostSet', @obj.editTextCallbackHandler);
        end
    end
end