classdef Button < matlab.hwmgr.internal.hwsetup.Button
    % matlab.hwmgr.internal.hwsetup.appdesigner.Button is a class that implements a
    % HW Setup button using uibutton.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.Button
    
    %   Copyright 20192-201 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = uibutton('Parent', aParent,...
                'Visible', 'on',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
    end
    
    methods(Access = protected)
        %set Peer property
        function setCallback(obj)
            obj.Peer.ButtonPushedFcn = @obj.buttonPushedCbk;
        end
        
        %get Peer property
        function text = setText(obj, text)
            if ~iscell(text) && contains(text, newline)
                % uibutton uses a cell array to label the button with 
                % multiple lines of text.
               text = splitlines(text);
            end
            obj.Peer.Text = text;
        end
        
        function text = getText(obj)
            text = char(obj.Peer.Text);
        end
    end
    
    methods
        % giving access to unit test to test this callback
        function buttonPushedCbk(obj, varargin)
            obj.safeCallbackInvoke(obj.ButtonPushedFcn, varargin);
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = Button(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Button(varargin{:});
        end
    end
    
end