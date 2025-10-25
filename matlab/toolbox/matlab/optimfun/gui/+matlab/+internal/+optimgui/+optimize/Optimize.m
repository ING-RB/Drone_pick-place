classdef Optimize < matlab.task.LiveTask
    % Optimize live task
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Set whether user has a valid optim license. The task help link
        % depends on license status
        HasOptim (1, 1) logical
        HelpLink (1, 1) string
        
        % Active Optimize approach
        Approach (1, :) char
        
        % Approach classes
        LandingPage % optim.internal.gui.optimize.landingpage.Optimize
        ProblemBased % optim.internal.gui.optimize.problembased.Optimize
        SolverBased % matlab.internal.optimgui.optimize.solverbased.Optimize

        % Listeners
        lhTaskChanged event.listener
        lhSetApproach event.listener
    end

    properties (Dependent)

        % Required dependent properties by base class
        Summary
        State
    end

    methods (Access = public)

        function this = Optimize()

            % Call superclass constructor
            this@matlab.task.LiveTask();

            % If optim license is available, launch landing page.
            % Else, launch the solver-based approach
            this.HasOptim  = optim.internal.utils.hasOptimizationToolbox;
            if this.HasOptim
                this.HelpLink = "'optim', 'optimizelet'";
                this.createApproach('LandingPage');

                wrefThis = matlab.lang.WeakReference(this);
                this.lhSetApproach = listener(this.LandingPage.SelectApproach, ...
                    'ValueChangedEvent', @(s,e)approachSelected(wrefThis.Handle,s,e));
            else
                this.HelpLink = "'matlab', 'optimize-let'";
                this.createApproach('SolverBased');
            end
        end

        function reset(this)

            % Call approach specific method
            this.(this.Approach).reset();
        end

        function postExecutionUpdate(this, data)

            % Call the Approach's implementation if it exists
            if ismethod(this.(this.Approach), 'postExecutionUpdate')
                this.(this.Approach).postExecutionUpdate(data);
            end
        end

        function helpLink = getHelpLink(this)
            helpLink = this.HelpLink;
        end
    end

    methods (Access = protected)

        function setup(this)

            % LayoutManager (property defined in base class)
            this.LayoutManager.ColumnWidth = {'1x'};
            this.LayoutManager.RowHeight = {'fit', 'fit', 'fit'};
            this.LayoutManager.Tag = 'UberTaskGrid';
        end

        function approachSelected(this, ~, event)

            % Listener callback for the StateChanged event of the LandingPage class

            % If the approach has NOT been created previously, show dialog since
            % creating the approach takes a few seconds
            if isempty(this.(event.Data))
                dlgTitle = getString(message(['optim_gui:ProblemBasedLET:', ...
                    event.Data, 'Dialog']));
                d = uiprogressdlg(matlab.internal.editor.LiveTaskUtilities.getFigure(this), ...
                    'Title', dlgTitle, 'Indeterminate', 'on');
                c = onCleanup(@()close(d));

                % Create selected approach
                this.createApproach(event.Data);
            else

                % Approach has already been created so just make it visible
                this.setApproach(event.Data);
            end
        end

        function createApproach(this, value)

            % Create approach
            h = matlab.internal.editor.LiveTaskUtilities.getFigure(this);
            this.LayoutManager.Parent = h;
            if strcmp(value, 'LandingPage')
                this.LandingPage = optim.internal.gui.optimize.landingpage.Optimize(h);
            elseif strcmp(value, 'ProblemBased')
                this.ProblemBased = optim.internal.gui.optimize.problembased.Optimize(h);
            else % SolverBased
                this.SolverBased = matlab.internal.optimgui.optimize.solverbased.Optimize(h);
            end

            % Make sure approach is visible
            this.setApproach(value);
            drawnow nocallbacks

            % Listen for updates to the task
            wrefThis = matlab.lang.WeakReference(this);
            this.lhTaskChanged = listener(this.(value), 'StateChanged', @(s,e)TaskChanged(wrefThis.Handle,s,e));
        end

        function setApproach(this, value)

            % Set Approach value and some associated properties
            this.Approach = value;
            this.LayoutManager.RowHeight = this.(this.Approach).ParentContainerRowHeight;
            this.AutoRun = this.(this.Approach).DefaultAutoRun;
        end

        function TaskChanged(this, ~, ~)

            % Listener callback for updates to the task

            % Notify listeners of the task change
            this.notify('StateChanged');
        end
    end

    % Additional required methods for embedding in a Live Script.
    methods

        function state = get.State(this)

            % Get approach specific value
            state = this.(this.Approach).State();
        end

        function set.State(this, state)

            % If there is no Approach field in the State struct, the state
            % must be a solver-based struct.
            if ~isfield(state, 'Approach')
                approach = 'SolverBased';
            else
                approach = state.Approach;
            end

            % If there is no optim license and the approach is NOT solver-based,
            % throw an error
            if ~this.HasOptim && ~strcmp(approach, 'SolverBased')
                error('matlab:internal:optimfun:optimgui:optimize:ProblemBasedUnsupported', ...
                    matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'ProblemBasedUnsupported'));
            end

            % Handle case if approach has not been created yet. This would
            % happen if the task was being re-opened
            if isempty(this.(approach))
                this.createApproach(approach);
            else
                % Approach has already been created so just make it visible
                this.setApproach(approach);
            end

            % Update Approach state
            this.(this.Approach).State = state;
        end

        function summary = get.Summary(this)

            % Get approach specific value
            summary  = this.(this.Approach).Summary();
        end

        function [code, outputs] = generateCode(this)

            % Get approach specific values
            [code, outputs]  = this.(this.Approach).generateCode();
        end
    end
end
