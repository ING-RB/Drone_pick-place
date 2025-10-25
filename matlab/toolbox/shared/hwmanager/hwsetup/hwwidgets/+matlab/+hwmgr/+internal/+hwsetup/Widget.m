classdef(Abstract) Widget < matlab.hwmgr.internal.hwsetup.WidgetBase
    %matlab.hwmgr.internal.hwsetup.Widget is an Abstract interface to a HW
    %   Setup Widget.
    %   It defines a common set of properties and methods required to
    %   define a HW Setup Widget.

    %   Copyright 2016-2021 The MathWorks, Inc.
    properties(Access = public, Dependent)
        %Inherited Properties
        %Visible
        %Tag
        %Position
    end

    properties(SetAccess = immutable)
        % Properties that cannot be changed after the widget is constructed

        % Parent - Container for the widget specified as an object of type
        %    matlab.hwmgr.internal.hwsetup.Window or
        %    matlab.hwmgr.internal.hwsetup.Panel
        Parent
    end

    properties(SetAccess = protected, GetAccess = protected)
        % Inherited Properties
        % Peer
    end

    properties(SetAccess = protected, GetAccess = private)
        % DeleteFcn - Function invoked before the object gets deleted
        %    specified as a function handle. The delete function should
        %    take a single argument which is the HW Setup widget object. To
        %    override the default functionality you can set the deleteFcn
        %    to a function handle in the constructor for the widget
        %   obj.DeleteFcn = @mydeleteFcn
        DeleteFcn
    end

    %% Public Methods
    methods
        function obj = Widget(parent, varargin)
            % Constructor
            p = inputParser;
            p.addRequired('parent', @matlab.hwmgr.internal.hwsetup.Widget.isValidParent);
            p.parse(parent);

            % Create Widget Peer object and parent it to the Peer
            obj.Peer = obj.createWidgetPeer(parent.Peer);
            % Parent the HW Setup widget object
            obj.Parent = parent;
            parent.Children{end+1} = obj;
        end

        function show(obj)
            %SHOW - Display the HW Setup widget
            %   show(obj) displays the widget, if the parent for the widget
            %   is not visible, the parent's visibility is set to 'on' as
            %   well (This is done recursively till the window containing
            %   the widget is set to visible 'on')
            obj.Visible = 'on';
        end

        function [w, h] = getParentSize(obj)
            %[W, H] = GETPARENTSIZE(OBJ) - returns the width and the height
            %   of the parent widget (Window or a panel)

            pos = obj.Parent.Position;
            w = pos(3);
            h = pos(4);
        end

        function shiftHorizontally(obj, offset)
            validateattributes(offset, {'numeric'},{'nonempty'});
            obj.Position(1) = obj.Position(1) + offset;
        end

        function shiftVertically(obj, offset)
            validateattributes(offset, {'numeric'},{'nonempty'});
            obj.Position(2) = obj.Position(2) + offset;
        end

        function addWidth(obj, offset)
            validateattributes(offset, {'numeric'},{'nonempty'});
            obj.Position(3) = obj.Position(3) + offset;
        end

        function addHeight(obj, offset)
            validateattributes(offset, {'numeric'},{'nonempty'});
            obj.Position(4) = obj.Position(4) + offset;
        end

    end

    methods (Access = protected)
        function hide(obj)
            obj.Parent.Visible = 'off';
            if isprop(obj.Parent, 'Parent')
                obj.Parent.hide();
            end
        end

        function safeCallbackInvoke(obj, callbackFcn, evt)
            % safeInvokeCallback invokes the widget callback as specified by 
            % callbackFcn

            if ~isempty(callbackFcn)
                obj.executeWidgetCallback(obj, callbackFcn, evt);
            end
        end
    end

    methods(Access = protected, Static)
        function validateStringInput(str)
            if(~isempty(str))
                validateattributes(str, {'char', 'string'}, {'scalartext'});
            else
                validateattributes(str, {'char', 'string'}, {});
            end
        end
    end

    methods
        function set.DeleteFcn(obj, deleteFcn)
            validateattributes(deleteFcn, {'function_handle'}, {'nonempty'});
            set(obj.Peer, 'DeleteFcn', {deleteFcn, obj});
        end
    end

    methods(Static)
        function ret = isValidParent(parentObj)
            %RET = ISVALIDPARENT(PARENTOBJ) returns true if the parentObj
            %   is an object of object of type matlab.hwmgr.internal.hwsetup.Window
            %   or matlab.hwmgr.internal.hwsetup.Panel else returns false

            ret = isa(parentObj, 'matlab.hwmgr.internal.hwsetup.Window') ||...
                isa(parentObj, 'matlab.hwmgr.internal.hwsetup.Panel') || ...
                isa(parentObj, 'matlab.hwmgr.internal.hwsetup.RadioGroup') ||...
                isa(parentObj, 'matlab.hwmgr.internal.hwsetup.Grid') ||...
                isa(parentObj, 'matlab.hwmgr.internal.hwsetup.AccordionPanel');
        end

        function widgetObj = createWidgetInstance(parent, widgetName)
            %WIDGETOBJ = CREATEWIDGETINSTANCE(PARENT, WIDGETNAME) accepts
            %   the parent which can be an object of type
            %   matlab.hwmgr.internal.hwsetup.Window or
            %   matlab.hwmgr.internal.hwsetup.Panel
            %   and name of the widget as input arguments and returns
            %   the instantiated widget object


            validateattributes(widgetName, {'char'} , {'nonempty'});

            className = [ 'matlab.hwmgr.internal.hwsetup.'...
                matlab.hwmgr.internal.hwsetup.util.WidgetTechnology.getTechnology(),...
                '.', widgetName];
            if isequal(exist(className, 'class'), 8)
                widgetObj = feval(className, parent);
                % Validate the widget instance is of type matlab.hwmgr.internal.hwsetup.Widget
                validateattributes(widgetObj, {'matlab.hwmgr.internal.hwsetup.Widget'}, {'nonempty', 'scalar'});
            else
                error(message('hwsetup:widget:WidgetClassDoesNotExist', className, widgetName));
            end
        end

        function executeWidgetCallback(obj, callbackFcn, evt)
            % executeWidgetCallback invokes the widget callback specified by
            % by callbackFcn. evt is the event information passed to the callback
            
            validateattributes(callbackFcn, {'function_handle', 'cell'}, {});
            try
                if isa(callbackFcn, 'function_handle')
                    fcnHandle = callbackFcn;
                    feval(fcnHandle, obj, evt);
                else
                    fcnHandle = callbackFcn{1};
                    feval(fcnHandle, obj, evt, callbackFcn{2:end});
                end
            catch ex
                title = message('hwsetup:widget:HWSetupError').getString;

                window = matlab.hwmgr.internal.hwsetup.util.findWindowAncestor(obj);

                if strcmp(ex.message, 'Invalid or deleted object.')
                    % If user closes the HW Setup screen during callback
                    % execution, throwing errors mentioning about object is not
                    % user friendly, so only on those cases, we rethrow a
                    % proper error.

                    msg = message('hwsetup:widget:HWSetupTerminated').getString;
                else
                    msg = ex.message;
                end

                window.showErrorDlg(title, msg);
            end
        end

        function close(~, ~, widgetObj)
            widgetObj.delete();
        end
    end

    %% Abstract Methods
    methods(Abstract, Static)
        %OBJ = GETINSTANCE(PARENT) gets a technology specific instance of
        %   the widget
        obj = getInstance(parent);
    end
end