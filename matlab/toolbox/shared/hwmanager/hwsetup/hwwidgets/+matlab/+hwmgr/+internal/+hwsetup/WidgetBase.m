classdef (Abstract) WidgetBase < matlab.hwmgr.internal.hwsetup.WidgetPeer &...
        matlab.mixin.CustomDisplay
    % matlab.hwmgr.internal.hwsetup.WidgetBase Abstract interface for
    % defining properties common to all widgets

    % Copyright 2016-2022 The MathWorks, Inc.

    properties(Access = public, Dependent)
        %Visible - Widget visibility specified as 'on' or 'off'
        Visible
        %Position - Widget location and size specified as a vector -
        %[left bottom width height]. All measurements specified as
        %pixels.
        Position
        %Tag - Widget identifier specified as a string. The tag value
        %should be unique.
        Tag
        %Row- row in parent grid in which this widget is placed
        Row
        %Column- column in parent grid which widget is placed.
        Column
    end

    %----------------------------------------------------------------------
    % Property setter methods
    %----------------------------------------------------------------------
    methods
        function set.Position(obj, position)
            %set.Position - set Position property on the Widget

            validateattributes(position, {'numeric'},...
                {'size', [1, 4], '>=', 1});

            obj.setPosition(position);
        end

        function set.Visible(obj, visible)
            %set.Visible - set Visible property of Peer. Currently, accepts
            %on, off strings

            validVisible = validatestring(visible, {'on','off'});
            obj.setVisible(validVisible);
        end

        function set.Tag(obj, tag)
            %set.Tag - A tag can be either a character vector of letters, digits and
            %underscores with length <= namelengthmax, the first character
            %a letter, and the name is not a keyword or an empty string.

            if ~ischar(tag) || (~isempty(regexp(tag, '\W', 'once')) && ~isempty(tag))
                error(message('hwsetup:widget:InvalidTag'));
            end
            obj.setTag(tag)
        end

        function set.Row(obj, row)
            obj.setRow(row)
        end

        function set.Column(obj, column)
            obj.setColumn(column);
        end
    end

    %----------------------------------------------------------------------
    % Property getter methods
    %----------------------------------------------------------------------
    methods
        function position = get.Position(obj)
            if isa(obj.Peer.Parent, 'matlab.hwmgr.internal.hwsetup.Grid')
                %no action. When parented to grid, Position property
                %becomes invalid.
                position = [];
            else
                position = obj.getPosition();
            end
        end

        function visible = get.Visible(obj)
            visible = obj.getVisible();
        end

        function tag = get.Tag(obj)
            tag = obj.getTag();
        end

        function row = get.Row(obj)
            row = obj.getRow();
       end

       function column = get.Column(obj)
            column = obj.getColumn();
        end
    end

    %----------------------------------------------------------------------
    % Helper setter methods
    %----------------------------------------------------------------------
    methods
        function setPosition(obj, position)
            if ~obj.isWidgetParentGrid()
                %apply the position
                if isprop(obj.Peer, 'Units')
                    set(obj.Peer, 'Units', matlab.hwmgr.internal.hwsetup.util.Layout.Units);
                end
                set(obj.Peer, 'Position', position);
            end
        end

        function setVisible(obj, visible)
            validatestring(visible, {'on','off'});
            set(obj.Peer, 'Visible', visible);
        end

        function setTag(obj, tag)
            set(obj.Peer, 'Tag', tag);
        end

        function setRow(obj, row)
            if isprop(obj.Peer, 'Layout') && ~isempty(obj.Peer.Layout)
                obj.Peer.Layout.Row = row;
            end
        end

        function setColumn(obj, column)
            if isprop(obj.Peer, 'Layout') && ~isempty(obj.Peer.Layout)
                obj.Peer.Layout.Column = column;
            end
        end
    end

    %----------------------------------------------------------------------
    % Helper getter methods
    %----------------------------------------------------------------------
    methods
        function position = getPosition(obj)
            position = get(obj.Peer, 'Position');
        end

        function visible = getVisible(obj)
            visible = get(obj.Peer, 'Visible');
        end

        function tag = getTag(obj)
            tag = get(obj.Peer, 'Tag');
        end

        function row = getRow(obj)
            row = [];
            if isprop(obj.Peer, 'Layout') && ~isempty(obj.Peer.Layout)
                row = obj.Peer.Layout.Row;
            end
        end

        function column = getColumn(obj)
            column = [];
            if isprop(obj.Peer, 'Layout') && ~isempty(obj.Peer.Layout)
                column = obj.Peer.Layout.Column;
            end
        end
    end

    %----------------------------------------------------------------------
    % Utility methods
    %----------------------------------------------------------------------
    methods
        function h = getHeight(obj)
            %getHeight - get height of widget. This is 4-th element of
            %Position property.

            pos = obj.Position;
            h = pos(4);
        end

        function w = getWidth(obj)
            %getWidth - get width of widget. This is 3rd element of
            %Position property.

            pos = obj.Position;
            w = pos(3);
        end

        function setWidth(obj, w)
            %setWidth - set width of widget. This is 3rd element of
            %Position property.

            validateattributes(w, {'numeric'}, {'nonempty'});
            if ~obj.isWidgetParentGrid()
                obj.Position = obj.Position + [0 0 w 0];
            end
        end

        function setHeight(obj, h)
            %setHeight - set height of widget. This is 4-th element of
            %Position property.

            validateattributes(h, {'numeric'}, {'nonempty'});
            if ~obj.isWidgetParentGrid()
                obj.Position = obj.Position + [0 0 0 h];
            end
        end
    end
    %----------------------------------------------------------------------
    % CustomDisplay methods
    %----------------------------------------------------------------------
    methods(Access = 'protected')
        function props = getPropertyGroups(obj)
            % GETPROPERTYGROUPS inherited from CustomDisplay to remove
            % display for Grid specific properties.
            props = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            propList = props.PropertyList;
            % if the widget does not use Grid as the parent, we remove Row
            % and Column properties from the display
            if ~obj.isWidgetParentGrid()
                propList = rmfield(propList, 'Row');
                propList = rmfield(propList, 'Column');
            elseif isfield(propList, 'Position')
                propList = rmfield(propList, 'Position');
            end
            props = matlab.mixin.util.PropertyGroup(propList);
        end
    end

    methods(Access = private)
        function out = isWidgetParentGrid(obj)
            % Position property can be changed only if parent is not Grid
            out = ismember(class(obj.Peer.Parent),...
                {'matlab.hwmgr.internal.hwsetup.appdesigner.Grid',...
                'matlab.ui.container.GridLayout'});
        end
    end


end

% LocalWords:  hwmgr hwsetup hwmgr hwsetup
