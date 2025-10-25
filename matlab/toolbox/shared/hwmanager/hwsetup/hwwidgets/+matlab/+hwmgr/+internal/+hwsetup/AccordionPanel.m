classdef AccordionPanel < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.FontProperties & ...
        matlab.hwmgr.internal.hwsetup.Container
    % matlab.hwmgr.internal.hwsetup.AccordionPanel is a class that defines a
    % collapsible Hardware Setup panel
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   ap = matlab.hwmgr.internal.hwsetup.AccordionPanel.getInstance(w);
    %   p.Title = 'MyPanel';
    %   p.show();

    %   Copyright 2022 The MathWorks, Inc.

    properties(Access = public, Dependent)
        Title % Panel title

        Collapsed % Collapsed state

        % Inherited Properties
        % Visible
        % Tag
        % Position
    end

    properties(SetAccess = protected, GetAccess = protected)
        % Inherited Properties
        % Peer
    end

    properties(SetAccess = immutable, GetAccess = protected)
        % Inherited Properties
        % Parent
    end

    properties(SetAccess = protected, GetAccess = private)
        % Inherited Properties
        % DeleteFcn
    end


    methods(Access = protected)
        function obj = AccordionPanel(varargin)
            %Panel- constructor to set defaults.

            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            %if parent is a grid
            if ~isequal(class(obj.Parent),...
                    'matlab.hwmgr.internal.hwsetup.appdesigner.Grid')
                [pW, pH] = obj.getParentSize();
                obj.Position = [pW*0.25 pH*0.25 pW*0.5 pH*0.5];
            end
            obj.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
            obj.Title = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.PanelTitle;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
        end
    end

    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end

    %% Property setter and getter
    methods
        function title = get.Title(obj)
            title = obj.Peer.Title;
        end

        function set.Title(obj, title)
            validateattributes(title, {'char', 'string'}, {});
            set(obj.Peer, 'Title', title);
        end

        function collapsed = get.Collapsed(obj)
            collapsed = obj.Peer.Collapsed;
        end

        function set.Collapsed(obj, collapsed)
            validateattributes(collapsed, {'logical'}, {'nonempty'}, '', '''Collapsed''');
            set(obj.Peer, 'Collapsed', collapsed)
        end
    end

    methods(Access = ?matlab.hwmgr.internal.hwsetup.TemplateBase)
        function disable(obj)
            set(findall(obj.Peer, '-property', 'enable'), 'enable', 'off')
        end

        function enable(obj)
            try
                set(findall(obj.Peer, '-property', 'enable'), 'enable', 'on')
            catch
                % During renable of screens on cleanup, if found that the
                % parent HW setup window is terminated then throw an error.
                % Instead of 'Invalid or deleted object.' error we will now
                % throw 'Hardware Setup Terminated, please try again.' in
                % command window.
                error(message('hwsetup:widget:HWSetupTerminated'));
            end
        end
    end
end