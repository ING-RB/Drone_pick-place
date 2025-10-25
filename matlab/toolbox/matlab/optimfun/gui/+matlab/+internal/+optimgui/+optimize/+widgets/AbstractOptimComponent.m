classdef (Abstract) AbstractOptimComponent < matlab.ui.componentcontainer.ComponentContainer
    % The AbstractOptimComponent class defines common properties and
    % methods for Optimization GUI custom components
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties(Abstract, Access = public)

        % Subclasses set a default value in the property block. The size
        % and type depends on subclass
        Value % (1, :) char or (1, 1) struct or ...
    end

    properties(Access = public)

        % This class provides a default implementation for Enable related
        % updates that subclasses can override as necessary, see update()
        % and updateEnable()
        Enable (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState(true);
    end

    events (HasCallbackProperty, NotifyAccess = protected)

        % ValueChangedFcn will be the generated callback property
        ValueChanged
    end

    properties (Hidden, Access = public, Transient, NonCopyable)

        % Main grid to hold underlying graphics objects of the component
        Grid (1, 1) matlab.ui.container.GridLayout
    end

    methods (Access = protected)

        function setup(this)

            % Grid
            this.Grid = uigridlayout(this);
            this.Grid.Padding = [0, 0, 0, 0];
            this.Grid.ColumnWidth = {'fit'};
            this.Grid.RowHeight = {'fit'};
        end

        function update(this)

            % This method executes when one or more public property
            % values change. It implements how the component needs to
            % change its appearance in response to the property values.
            % Use the template pattern for flexibility on how the properties
            % influence the appearance.

            % Updates related to the Value property
            this.updateValue();

            % Updates related to Enable property
            this.updateEnable();
        end

        function updateEnable(this)

            % Find all the properties in Grid that support the Enable
            % property and set their value accordingly
            set(findall(this.Grid, '-property', 'Enable'), 'Enable', this.Enable);
        end
    end

    methods (Abstract, Access = protected)

        % Updates related to the Value property. See update()
        updateValue(this);
    end
end
