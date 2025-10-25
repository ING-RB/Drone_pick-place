classdef AccordionPanel <  matlab.hwmgr.internal.hwsetup.AccordionPanel
    % matlab.hwmgr.internal.hwsetup.appdesigner.AccordionPanel is a class
    % that implements a HW Setup panel using
    % matlab.ui.container.internal.AccordionPanel.

    % Copyright 2023 The MathWorks, Inc.

    properties(Access = public, Dependent)
        % Inherited Properties
        % Visible
        % Enable
        % Tag
        % Position
        % Title
    end

    properties(SetAccess = private, GetAccess = protected)
        % Inherited Properties
        % Parent
    end

    properties(GetAccess = protected, SetAccess = protected)
        % Inherited Properties
        % Peer
    end

    methods(Static)
        function aPeer = createWidgetPeer(parent)
            validateattributes(parent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});

            containerComponent = uipanel(parent, 'BorderType', 'none',...
                'BackgroundColor', 'w', 'AutoResizeChildren', 'off', 'Title', '');
            containerGrid = uigridlayout(containerComponent, [1, 1],...
                'RowSpacing', 0, 'ColumnSpacing', 0, 'RowHeight', {'fit'},...
                'ColumnWidth', {'1x'},...
                'Scrollable', 'on', 'Padding', [0 0 0 0]);
            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(containerGrid,'BackgroundColor',matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput);
            accordian = matlab.ui.container.internal.Accordion('Parent', containerGrid,...
                'Visible', 'on');
            aPeer = matlab.ui.container.internal.AccordionPanel('Parent', accordian, 'Title', '');
            aPeer.UserData.ContainerComponent = containerComponent;
        end
    end

    %----------------------------------------------------------------------
    % Method overrides
    % These calls are delegated to the ContainerComponent as it needs to be 
    % positioned appropriately in its parent
    %----------------------------------------------------------------------
    methods
        function pos = getPosition(obj)
            %getPosition- get position of the parent container

            pos = obj.Peer.UserData.ContainerComponent.Position;
        end

        function setPosition(obj, pos)
            %setPosition- set position on the accordian

            set(obj.Peer.UserData.ContainerComponent, 'Position', pos);
        end

        function row = getRow(obj)
            row = [];
            containerComponent = obj.Peer.UserData.ContainerComponent;
            if isprop(containerComponent, 'Layout') && ~isempty(containerComponent.Layout)
                row = containerComponent.Layout.Row;
            end
        end

        function column = getColumn(obj)
            column = [];
            containerComponent = obj.Peer.UserData.ContainerComponent;
            if isprop(containerComponent, 'Layout') && ~isempty(containerComponent.Layout)
                column = containerComponent.Layout.Column;
            end
        end

        function setRow(obj, row)
            containerComponent = obj.Peer.UserData.ContainerComponent;
            if isprop(containerComponent, 'Layout') && ~isempty(containerComponent.Layout)
                containerComponent.Layout.Row = row;
            end
        end

        function setColumn(obj, column)
            containerComponent = obj.Peer.UserData.ContainerComponent;
            if isprop(containerComponent, 'Layout') && ~isempty(containerComponent.Layout)
                containerComponent.Layout.Column = column;
            end
        end
    end
end
% LocalWords:  hwmgr hwsetup
