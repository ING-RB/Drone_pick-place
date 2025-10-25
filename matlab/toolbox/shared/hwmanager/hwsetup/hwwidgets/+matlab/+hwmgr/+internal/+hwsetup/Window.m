classdef Window < matlab.hwmgr.internal.hwsetup.WidgetBase & ...
        matlab.hwmgr.internal.hwsetup.Container
    %   matlab.hwmgr.internal.hwsetup.Window defines a Window class.
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance()
    %   w.show()

    %   Copyright 2017-2024 The MathWorks, Inc.

    properties(Access = public, Dependent)
        % Title - Window Title specified as a string
        Title
        Resize
        % Inherited Properties
        % Visible
        % Tag
        % Position
        % Color
    end

    properties(GetAccess = protected, SetAccess = protected)
        % Inherited Properties
        % Peer
    end

    properties(Access = private, Dependent)
        % DeleteFcn - Function invoked before the object gets deleted
        %    specified as a function handle. The delete function should
        %    take a single argument which is the HW Setup Window object. To
        %    cleare the DeleteFcn -
        %    obj.DeleteFcn = function_handle.empty;
        DeleteFcn
    end

    methods(Static)
        function obj = getInstance(varargin)
            %   GETINSTANCE get an instance of the HW Setup Window
            %   Widget

            obj = matlab.hwmgr.internal.hwsetup.Window(varargin{:});
        end
    end

    methods
        function bringToFront(obj)
            % BRINGTOFRONT brings the Hardware Setup Window in focus by
            % displaying it on top of other Hardware Setup windows

            figure(obj.Peer);
        end

        function show(obj)
            % SHOW display the HW Setup Window
            %   It validates if the HW Setup Window fits within the screen
            %   width, if not it will throw a warning.

            %matlab.hwmgr.internal.hwsetup.util.Layout.isWindowVisible(obj.Position);
            obj.Visible = 'on';
        end
    end

    methods
        function peer = getPeer(obj)
            peer = obj.Peer;
        end

        function set.DeleteFcn(obj, deleteFcn)
            validateattributes(deleteFcn, {'function_handle'},...
                {'nonempty'});
            set(obj.Peer, 'CloseRequestFcn', {deleteFcn, obj});
        end

        function deleteFcn = get.DeleteFcn(obj)
            deleteFcn = get(obj.Peer, 'CloseRequestFcn');
        end

        function title = get.Title(obj)
            title = get(obj.Peer, 'Name');
        end

        function set.Title(obj, title)
            validateattributes(title, {'char','string'}, {'nonempty'});
            set(obj.Peer, 'Name', title);
        end

        function set.Resize(obj, value)
            set(obj.Peer, 'Resize', value)
        end

        function out = get.Resize(obj)
            out = get(obj.Peer, 'Resize');
        end
    end

    methods(Access = protected)
        function obj = Window(varargin)
            if nargin == 1
                obj.Peer = varargin{1};
            else
                % Create a Peer
                obj.Peer = matlab.hwmgr.internal.hwsetup.Window.createWidgetPeer();
                % Set Defaults
                obj.Position = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.getDefaultWindowPosition();
                matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.Peer, 'Color', matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput);
                obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Window.onDeleteFcn;
                obj.Title = message('hwsetup:widget:DefaultWindowTitle').getString;
                obj.Resize = 'off';
            end
        end
    end

    methods(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?matlab.hwmgr.internal.hwsetup.Widget,...
            ?hwsetuptest.util.WidgetTester, ?hwsetuptest.util.TemplateBaseTester})

        function showErrorDlg(obj, title, msg)
            % showErrorDlg Displays an embedded alert dialog with a specified
            % title and message.

            if matlab.internal.feature('HWSetupEmbeddedDlgs')
                uialert(obj.Peer, msg, title);
            else
                errordlg(msg, title);
            end
        end

        function choice = showConfirmDlg(obj, title, msg, options)
            % showConfirmDlg Displays a confirmation dialog with specified options.
            %
            % The dialog displays a message with a given title and provides
            % multiple options for the user to choose from.

            choice = uiconfirm(obj.Peer, msg, title, 'Options', options);
        end
    end

    methods(Static)
        function out = createWidgetPeer(~)
            % create a peer object and return a handle to it
            out =  uifigure('Visible', 'on', 'ToolBar', 'none',...
                'MenuBar', 'none', 'NumberTitle', 'off', 'Units', 'pixels',...
                'HandleVisibility', 'off');
        end

        function onDeleteFcn(~, ~, windowObj)
            windowObj.delete();
        end
    end
end