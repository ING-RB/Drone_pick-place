classdef (ConstructOnLoad=true) Popout < ...
        matlab.ui.container.internal.model.LayoutContainer & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent
    %
    
    % Do not remove above white space
    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        Target
        Placement               (1,1) string {mustBeMember(Placement, ["right", "left", "top", "bottom", "auto"])} = "auto";
        Trigger                 (1,1) string {mustBeMember(Trigger, ["click", "hover", "manual"])} = "manual";
    end
    
    properties(NonCopyable, Dependent, AbortSet)
        PopoutOpeningFcn        matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        PopoutClosingFcn        matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivatePopoutOpeningFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        PrivatePopoutClosingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?matlab.ui.control.internal.controller.ComponentController,?appdesservices.internal.interfaces.model.AbstractModel})
        PopoutOpening;
        PopoutClosing;
    end

    properties (Dependent=true)
        TargetID
    end

    properties (SetAccess={?matlab.ui.container.internal.PopoutController})
        IsOpen  (1,1) logical = false
    end

    methods
        function obj = Popout(varargin)
            parsePVPairs(obj,  varargin{:});
            obj.attachCallbackToEvent('PopoutOpening', 'PrivatePopoutOpeningFcn');
            obj.attachCallbackToEvent('PopoutClosing', 'PrivatePopoutClosingFcn');

            if ~isempty(obj.Target)
                obj.markPropertiesDirty({'TargetID'});
            end
        end

        function open(obj)
            if ~obj.IsOpen
                obj.Controller.open();
            end
        end

        function close(obj)
            if obj.IsOpen
                obj.Controller.close();
            end
        end

        function set.Target(obj, t)
            obj.Target = t;
            if ~isempty(obj.Target)
                obj.Parent = ancestor(obj.Target, 'figure');
            end
            obj.markPropertiesDirty({'TargetID'});
        end

        function tid = get.TargetID(obj)
            tid = '';
            if ~isempty(obj.Target)
                try
                    % Need a way to get the ID of the target to be able to
                    % find and match it on the client side.  Since there is
                    % no public way of doing this, we need to cast the
                    % target to a struct in order to reach in and the the
                    % ID from its controller.
                    w = warning('off');
                    s = struct(obj.Target);
                    warning(w);
                    tid = s.Controller.getId();
                catch
                    warning('Can''t get target ID');
                end
            end
        end

        function set.Placement(obj, pos)
            arguments
                obj
                pos (1,1) string {mustBeMember(pos, ["right", "left", "top", "bottom", "auto"])}
            end

            obj.Placement = pos;
            obj.markPropertiesDirty({'Placement'});
        end

        function set.Trigger(obj, val)
            arguments
                obj
                val (1,1) string {mustBeMember(val, ["click", "hover", "manual"])}
            end

            obj.Trigger = val;
            obj.markPropertiesDirty({'Trigger'});
        end

        function set.PopoutOpeningFcn(obj, newValue)
            % Property Setting
            obj.PrivatePopoutOpeningFcn = newValue; 
            
            obj.markPropertiesDirty({'PopoutOpeningFcn'});
        end
        
        function value = get.PopoutOpeningFcn(obj)
            value = obj.PrivatePopoutOpeningFcn;
        end

        function set.PopoutClosingFcn(obj, newValue)
            % Property Setting
            obj.PrivatePopoutClosingFcn = newValue; 
            
            obj.markPropertiesDirty({'PopoutClosingFcn'});
        end
        
        function value = get.PopoutClosingFcn(obj)
            value = obj.PrivatePopoutClosingFcn;
        end
    end

    methods(Static, ...
        Access = {?matlab.ui.internal.mixin.ComponentLayoutable, ...
        ?matlab.ui.container.internal.model.LayoutContainer})

        function layoutOptionsClass = getValidLayoutOptionsClassId()
            layoutOptionsClass = 'matlab.ui.control.internal.PopoutLayoutOptions';
        end
    end
end

