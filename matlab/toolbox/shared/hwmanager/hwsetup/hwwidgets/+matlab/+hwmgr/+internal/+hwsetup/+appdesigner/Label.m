classdef Label < matlab.hwmgr.internal.hwsetup.Label
    % matlab.hwmgr.internal.hwsetup.appdesigner.Label is a class that implements a
    % HW Setup button using uilabel.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.Label
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access = private)
        %TextType- Users can enter label text as a cell, char or string with newline
        % character. However, uilabel peer stores text with newlines as cell arrays.
        % As a result, we need to store the type of user input and then convert
        % the text read from the peer to the expected type.
        TextType
    end
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = uilabel('Parent', aParent, 'Visible', 'on',...
                'WordWrap', 'on',...
                'VerticalAlignment', 'top',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
    end
    
    methods(Access = protected)
        %set Peer property
        function setText(obj, text)
            obj.TextType = class(text);
            if ~iscell(text) && contains(text, newline)
                % uilabel uses a cell array to display multiple lines of text.
                text =  splitlines(text);
            end
            obj.Peer.Text = text;
        end
        
        function setTextAlignment(obj, value)
            obj.Peer.HorizontalAlignment = value;
        end
        
        %get Peer property
        function text = getText(obj)
            if strcmp(obj.TextType, 'cell')
                text = obj.Peer.Text;
            else
                % if user has entered non-cell input, they should expect a
                % non-cell
                text = char(obj.Peer.Text);
            end
        end
        
        function alignment = getTextAlignment(obj)
            alignment = char(obj.Peer.HorizontalAlignment);
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = Label(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Label(varargin{:});
        end
    end
end