classdef BusyOverlay < matlab.hwmgr.internal.hwsetup.BusyOverlay
    %matlab.hwmgr.internal.hwsetup.appdesigner.BusyOverlay is a class that
    %implements a busy overlay using a combination of CircularProgressIndicator
    %and uilabel. It exposes all of the settable and gettable properties 
    %defined by the interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.BusyOverlay
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for BusyOverlay
            %widget. We use a CircularProgressIndicator with accompanying
            %text.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = uigridlayout(aParent,...
                'RowHeight', {'2x', 32, '1x', '2x'},...
                'ColumnWidth', {'2x', 32, '2x'},...
                'Padding', [0 0 0 0]);
            
            %busy spinner using CircularProgressIndicator
            pIndicator = matlab.ui.control.internal.CircularProgressIndicator(...
                'Parent', aPeer,...
                'Indeterminate', true);
            pIndicator.Layout.Row = 2;
            pIndicator.Layout.Column = 2;
            
            % label to display the text
            pLabel = uilabel(aPeer,...
                'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'top',...
                'FontColor', [0.5, 0.5, 0.5],...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
            pLabel.Layout.Row = 3;
            pLabel.Layout.Column = [1, 3];
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = BusyOverlay(varargin)
            %BusyOverlay constructor
            
            obj@matlab.hwmgr.internal.hwsetup.BusyOverlay(varargin{:});
            
            %This listener will invoke the destructor of the BusyOverlay
            %when it's parent is destroyed.
            addlistener(obj.Parent, 'ObjectBeingDestroyed',...
                @obj.parentDeleteCallback);
        end
    end
    
    methods
        function setPosition(~, ~)
            %setPosition - overrides setPosition method of
            %matlab.hwmgr.internal.hwsetup.WidgetBase
            %Throw a warning to indicate the Position property is read only.
            
            warning(message('hwsetup:widget:BusyOverlayPositionReadOnly'));
        end
        
        function position = getPosition(~)
            %getPosition - override to return the default position as size of
            %ContentPanel.
            
            position = [0 0 470 390];
        end
    end
    
    methods(Access = protected)
        function setText(obj, text)
            %setText - find the label within the grid and set the text.
            
            label = findobj(obj.Peer.Children, 'Type', 'uilabel');
            if ~isempty(label)
                label.Text = text;
            end
            drawnow(); %immediately reflect the change
        end
             
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete BusyOverlay when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
end

% LocalWords:  hwmgr hwsetup appdesigner uiimage uilabel hwmanager hwwidgets
