classdef AbstractOptimizeApproach < matlab.task.LiveTask
    % Define a common interface for Optimize LET approach classes:
    % landing page, problem-based, and solver-based.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Abstract, GetAccess = public, SetAccess = protected)

        % Task back-end model
        Model % Class varies by task

        % Row height for the parent container UberTaskGrid to make this
        % approach visible and hide all other panels
        ParentContainerRowHeight (1, :) cell

        % Default auto run behavior
        DefaultAutoRun (1, 1) logical
    end

    properties (GetAccess = public, SetAccess = protected)

        % Listeners
        lhTaskChanged event.listener
        lhInputError event.listener
        lhHelpClicked event.listener
    end

    % Required dependent properties by LiveTask base class
    properties (Dependent)

        % Task state
        State

        % Task summary
        Summary
    end

    methods (Access = public)

        function this = AbstractOptimizeApproach(parent)

            % If not passed a parent uifigure, create one
            if nargin == 0
                parent = uifigure;
                parent.Position = [100, 100, 710, 400];
            end

            % Call superclass constructor
            this@matlab.task.LiveTask('Parent', parent);
        end
    end

    methods (Access = protected)

        function taskChanged(this, ~, ~)

            % Listener callback for user interaction with the live task

            % Notify listeners of the task change
            this.notify('StateChanged');
        end

        function inputError(this, ~, event, iconType)

            % Listener callback for creating uialert

            % If not passed an icon type, use 'error' (default)
            if nargin < 4
                iconType = 'error';
            end

            % Create alert based on event data
            uialert(matlab.internal.editor.LiveTaskUtilities.getFigure(this), ...
                event.Data{:}, 'Icon', iconType);
        end

        function goToDocLink(~, ~, event)

            % Listener callback for clicking context sensitive help

            % Pull doc link from catalog and go to page
            link = matlab.internal.optimgui.optimize.utils.getMessage('DocLinks', event.Data);
            cellLink = strsplit(link, ',');
            helpview(cellLink{:});
        end
    end

    % Required methods by LiveTask base class
    methods

        function state = get.State(this)

            % Convert OptimizeState object to a structure
            % Use built-in function, but need to turn warning off/on
            origWarnState = warning('off', 'MATLAB:structOnObject');
            state = struct(this.Model.State);
            warning(origWarnState);
        end

        function set.State(this, state)

            % Call protected method so sub-classes can override set method.
            % LiveTask superclass already has a method called setState, so
            % protected method is called setStateFromStruct
            this.setStateFromStruct(state);
        end

        function summary = get.Summary(this)

            % Return summary from model
            summary = this.Model.generateSummary();
        end

        function [code, outputs] = generateCode(this)

            % This method should only be called internally or by the live task infrastructure

            % Return code from model
            [code, outputs] = this.Model.generateCode();
        end
    end

    methods (Abstract, Access = protected)

        % Sub-classes implement how state is set
        setStateFromStruct(this, state);
    end
end
