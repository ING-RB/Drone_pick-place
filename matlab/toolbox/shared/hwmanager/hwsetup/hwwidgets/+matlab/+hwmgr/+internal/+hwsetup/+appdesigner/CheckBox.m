classdef CheckBox < matlab.hwmgr.internal.hwsetup.CheckBox
    % matlab.hwmgr.internal.hwsetup.appdesigner.CheckBox is a class that implements a
    % HW Setup checkbox using uicheckbox.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.CheckBox
    
    % Copyright 2019-2021 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {}, 'createWidgetPeer', 'aParent');
            
            aPeer = uicheckbox('Parent', aParent,...
                'Visible', 'on',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
    end
    
    methods(Access = protected)
        % setters & getters for peer properties
        function setCallback(obj)
            obj.Peer.ValueChangedFcn = @obj.valueChangedCbk;
        end
        
        function valueChangedCbk(obj, varargin)
            %varargin should be two elements an object and an event
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(varargin{2}, {'event.PropertyEvent', 'matlab.ui.eventdata.ActionData',...
                'matlab.ui.eventdata.ValueChangedData'}, {});
            obj.safeCallbackInvoke(obj.ValueChangedFcn, varargin{2});
        end
        
        function setText(obj, text)
            if ~iscell(text) && contains(text, newline)
                % uicheckbox uses a cell array to format text with
                % multiple lines.
                text = splitlines(text);
            end
            obj.Peer.Text = text;
        end
        
        function setValue(obj, value)
            obj.Peer.Value = value;
        end
        
        function text = getText(obj)
            text = char(obj.Peer.Text);
        end
        
        function value = getValue(obj)
            value = obj.Peer.Value;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = CheckBox(varargin)
            obj@matlab.hwmgr.internal.hwsetup.CheckBox(varargin{:});
            addlistener(obj, 'Value', 'PostSet', @obj.valueChangedCbk);
        end
    end
end