classdef (Abstract) AbstractTaskView < handle & matlab.mixin.Heterogeneous
    % Define a common interface for Optimize LET view classes
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % The view's parent container
        ParentContainer % GridLayout or AccordionPanel

        % Identifier for the view class
        Tag (1, :) char

        % Row in parent container
        % When parent is AccordionPanel, Row is not needed and will remain empty
        Row (1, 1) double

        % The view's model
        Model % (1, 1) Class type varies

        % Reference row height for Grid when not 'fit'
        RowHeight (1, 1) double = matlab.internal.optimgui.optimize.OptimizeConstants.RowHeight;
    end

    events

        % Notify listeners when the view has a new user interaction
        ValueChangedEvent

        % Notify listeners of invalid user input
        InputErrorEvent
    end

    methods (Access = public)

        function this = AbstractTaskView(parentContainer, tag, row)

            % Check for input arguments
            if nargin > 0

                % Set ParentContainer and Tag property from input args
                this.ParentContainer = parentContainer;
                this.Tag = tag;

                % Set Row property if passed
                if nargin > 2
                    this.Row = row;
                end

                % Create "empty" components
                this.createComponents();
            end
        end
    end

    methods (Access = protected)

        function valueChanged(this, ~, ~)

            % Listener callback for the ValueChangedEvent

            % Notify listeners of a value change
            this.notify('ValueChangedEvent')
        end

        function inputError(this, ~, event)

            % Listener callback for the InputErrorEvent

            % Notify listeners of an input error
            this.notify('InputErrorEvent', event)
        end
    end

    methods (Abstract, Access = public)

        % Sets view to the current state of the Model
        updateView(model);
    end

    methods (Abstract, Access = protected)

        % Creates the widgets for the view class
        createComponents(this, parentContainer)
    end
end
