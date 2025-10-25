classdef DerivedWidget < handle
    % DerivedWidget - Base class that defines the interface for a Derived
    % Widget. A derived widget is a customized form of a Base Widget. The
    % base widget is always of type matlab.hwmgr.internal.hwsetup.Widget.
    % The DerivedWidget Class helps builds widgets geared for a specific
    % purpose e.g. a Table to display device information etc.
    
    %   Copyright 2016-2023 The MathWorks, Inc.
    
    properties(SetAccess = immutable, GetAccess = protected)
        % Properties that cannot be changed after the widget is constructed
        
        % Parent - Container for the widget specified as an object of type
        %    matlab.hwmgr.internal.hwsetup.Window or
        %    matlab.hwmgr.internal.hwsetup.Panel
        Parent
    end
    
    properties(SetAccess = protected, GetAccess = protected, Abstract)
        % Inherited Properties
        BaseWidget
    end
    
    properties(Access = public, Dependent)
        %Visible - Widget visibility specified as 'on' or 'off'
        Visible
        %Position - Widget location and size specified as a vector -
        %   [left bottom width height]. All measurements specified as
        %   pixels.
        Position
        %Tag - Widget identifier specified as a string. The tag value
        %   should be unique.
        Tag
        %Enable - Operational control of the widget indicating if the
        %   user can interact with it or not specified as 'on' or 'off'
        Enable
        %Row- row in parent grid in which this widget is placed
        Row
        %Column- column in parent grid which widget is placed.
        Column
    end
    
    methods(Abstract)
        show(obj)
    end
    
    methods(Static, Abstract)
        obj = getInstance(parent)
    end
    
    methods
        function obj = DerivedWidget(parent, varargin)
            p = inputParser;
            p.addRequired('parent', @matlab.hwmgr.internal.hwsetup.Widget.isValidParent);
            %p.addOptional('log', @matlab.hwmgr.internal.hwsetup.Logger.isValid);
            p.parse(parent);
            obj.Parent = parent;
            addlistener(obj.Parent, 'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
        
        % delete destructor
        function delete(obj)
            %DELETE(OBJ) deletes the MCOS widget object
            obj.delete();
        end
        
        function parentDeleteCallback(obj, varargin)
            if isvalid(obj)
                delete(obj) % call destructor
            end
        end
        
        function set.Enable(obj, enable)
            obj.BaseWidget.Enable = enable;
        end
        
        function enable = get.Enable(obj)
            enable = obj.BaseWidget.Enable;
        end
        
        function pos = get.Position(obj)
            pos = obj.BaseWidget.Position;
        end
        
        function set.Position(obj, pos)
            obj.BaseWidget.Position = pos;
        end
        
        function vis = get.Visible(obj)
            vis = obj.BaseWidget.Visible;
        end
        
        function set.Visible(obj, vis)
            obj.BaseWidget.Visible = vis;
        end

        function row = get.Row(obj)
            row = obj.BaseWidget.Row;
        end

        function set.Row(obj, row)
            obj.BaseWidget.Row = row;
        end

        function col = get.Column(obj)
            col = obj.BaseWidget.Column;
        end

        function set.Column(obj, col)
            obj.BaseWidget.Column = col;
        end
        
        function tag = get.Tag(obj)
            tag = obj.BaseWidget.Tag;
        end
        
        function set.Tag(obj, tag)
            obj.BaseWidget.Tag = tag;
        end
        
        function safeCallbackInvoke(obj, callbackFcn, evt)
            % safeCallbackInvoke invokes the widget callback specified by
            % by callbackFcn. evt is the event information passed to the callback

            if ~isempty(callbackFcn)
                matlab.hwmgr.internal.hwsetup.Widget.executeWidgetCallback(obj, callbackFcn, evt);
            end
        end
        
    end
end