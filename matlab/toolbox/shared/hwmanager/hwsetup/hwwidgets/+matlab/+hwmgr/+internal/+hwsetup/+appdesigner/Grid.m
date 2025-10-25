classdef Grid <  matlab.hwmgr.internal.hwsetup.Grid
    %matlab.hwmgr.internal.hwsetup.appdesigner.Grid is a class that
    %implements a Hardware Setup grid layout.

    % Copyright 2021-2022 The MathWorks, Inc.

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

    methods
        function obj = Grid(varargin)
            %Grid- constructor

            obj@matlab.hwmgr.internal.hwsetup.Grid(varargin{:});
        end
    end

    methods(Static)
        function aPeer = createWidgetPeer(parent)
            %createWidgetPeer- initialize a grid using uigridlayout as peer.

            validateattributes(parent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel',...
                'matlab.ui.container.GridLayout',...
                'matlab.ui.container.internal.AccordionPanel'}, {});

            aPeer = uigridlayout('Parent', parent,...
                'Visible', 'on',...
                'RowSpacing', 0,...
                'Scrollable', 'on',...
                'ColumnSpacing', 0);

            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(aPeer,'BackgroundColor',matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput);
        end
    end
end