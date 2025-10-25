classdef RadioButton < matlab.hwmgr.internal.hwsetup.RadioButton
    %matlab.hwmgr.internal.hwsetup.appdesigner.RadioButton is a class that
    %implements a HW Setup radio button using uiradiobutton.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.RadioButton
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for RadioButton
            %widget.
            
            %Radio buttons have to be parented to a button group.
            validateattributes(aParent, {'matlab.ui.container.ButtonGroup'},...
                {}, 'createWidgetPeer', 'aParent');
            
            aPeer = uiradiobutton('Parent', aParent,...
                'Visible', 'on',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
    end
    
    methods(Access = protected)
        function setText(obj, text)
            %setText - set text on radio button peer
            
            if ~iscell(text) && contains(text, newline)
                %uiradiobutton uses a cell array to label the button with
                %multiple lines of text.
                text = splitlines(text);
            end
            obj.Peer.Text = text;
        end
        
        function setValue(obj, value)
            %setValue - set value on radio button peer
            
            obj.Peer.Value = value;
        end
        
        function text = getText(obj)
            %getText - get text on radio button peer
                
            text = char(obj.Peer.Text);
        end
        
        function value = getValue(obj)
            %getValue - get radio button value
            
            value = obj.Peer.Value;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = RadioButton(varargin)
            %RadioButton constructor

            obj@matlab.hwmgr.internal.hwsetup.RadioButton(varargin{:});
        end
    end
    
end