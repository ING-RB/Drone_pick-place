classdef (Hidden = true) FindTrendsTask < matlab.task.LiveTask
    % FindTrendsTask - Find polynomial or seasonal trends
    %
    %   H = FindTrendsTask constructs a Live Script tool for choosing
    %   between Remove Trends and Find Seasonal Trends sub tasks
    %
    %   See also TRENDDECOMP DETREND

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(Hidden,Transient)
        UIFigure                  matlab.ui.Figure
        InitialGrid               matlab.ui.container.GridLayout
        RemoveTrendsButton        matlab.ui.control.Button
        RemoveTrendsSubTask       matlab.internal.dataui.trendRemover
        FindSeasonalTrendsButton  matlab.ui.control.Button
        FindSeasonalTrendsSubTask matlab.internal.dataui.FindSeasonalTrendsTask
        SelectedTask              char ='';
        InitializeInputs          cell
        Workspace
    end

    properties(Dependent)
        State
        Summary
    end

    methods(Access = public)
        function app = FindTrendsTask(fig,workspace)
            arguments
                fig = uifigure("Position",[50 50 1000 1000]);
                workspace = "base";
            end
            app@matlab.task.LiveTask("Parent",fig);
            app.UIFigure = fig;
            app.Workspace = workspace;
            % Note: this task doesn't support changing Workspace after a
            % subtask is launched
        end
    end

    methods(Access = protected)
        function setup(app)
            getStr = @(str,varargin) getString(message(['MATLAB:dataui:' str],varargin{:}));
            app.InitialGrid = uigridlayout(app.LayoutManager,...
                'RowHeight',{'fit' 'fit'},'ColumnWidth',{'fit'},'Padding',0);
            uilabel(app.InitialGrid,'Text',getStr('FindTrendsSelectTrendType'),...
                'FontWeight','bold');
            buttonGrid = uigridlayout(app.InitialGrid,'Padding',[10 0 0 0],...
                'RowHeight',{'fit'},'ColumnWidth',{300 300});
            bullet = [newline char(8226) ' '];
            app.RemoveTrendsButton = uibutton(buttonGrid,...
                'IconAlignment','left','HorizontalAlignment','left',...
                'Tag','trendRemover',...
                'Text',[getStr('FindTrendsPolynomial') newline ...
                    bullet getStr('FindTrendsPolynomialBullet1')...
                    bullet getStr('FindTrendsPolynomialBullet2')...
                    bullet getStr('FindTrendsPolynomialBullet3')],...
                'Tooltip',getStr('FindTrendsPolynomialTooltip','detrend'),...
                'ButtonPushedFcn',@app.startSubTask);
            matlab.ui.control.internal.specifyIconID(app.RemoveTrendsButton,...
                'findPolynomialTrendPlot',50,40);

            app.FindSeasonalTrendsButton = uibutton(buttonGrid,...
                'IconAlignment','left','HorizontalAlignment','left',...
                'Tag','FindSeasonalTrendsTask',...
                'Text',[getStr('FindTrendsSeasonal') newline ...
                    bullet getStr('FindTrendsSeasonalBullet1')...
                    bullet getStr('FindTrendsSeasonalBullet2')...
                    bullet getStr('FindTrendsSeasonalBullet3')],...
                'Tooltip',getStr('FindTrendsSeasonalTooltip','trenddecomp'),...
                'ButtonPushedFcn',@app.startSubTask);
            matlab.ui.control.internal.specifyIconID(app.FindSeasonalTrendsButton,...
                'findSeasonalTrendPlot',50,40);
        end
    end

    methods(Access = private)
        function startSubTask(app,src,~)
            doInitialize = false;
            if isequal(src.Tag,'trendRemover')
                if isempty(app.RemoveTrendsSubTask)
                    app.RemoveTrendsSubTask = matlab.internal.dataui.trendRemover(app.UIFigure,app.Workspace);
                    doInitialize = true;
                end
                task = app.RemoveTrendsSubTask;
                nonselectedTask = app.FindSeasonalTrendsSubTask;
            else
                if isempty(app.FindSeasonalTrendsSubTask)
                    app.FindSeasonalTrendsSubTask = matlab.internal.dataui.FindSeasonalTrendsTask(app.UIFigure,app.Workspace);
                    doInitialize = true;                    
                end
                task = app.FindSeasonalTrendsSubTask;
                nonselectedTask = app.RemoveTrendsSubTask;
            end
            if doInitialize
                % one-time steps to startup a sub-task

                % when subtask throws StateChanged, uber task should too
                addlistener(task,'StateChanged',@app.notifyStateChanged);
                % subtask home button should reset uber task
                addlistener(task,'HomeClicked',@app.resetToLandingPage);
                if nargin == 3
                    % Comes from button push instead of set.State. Push any
                    % original initialize inputs to the uber task's
                    % initialize into the subtask
                    inputs = app.InitializeInputs;
                    if ~isempty(nonselectedTask)
                        % When swapping from one task to the other for the
                        % first time, attempt to keep user choice of input
                        % from the other task
                        st = nonselectedTask.State;
                        inputs = [inputs {'Inputs' st.InputDataDropDownValue}];
                        if st.InputDataTableVarDropDownVisible
                            % also attempt to keep user choice of table
                            % variables
                            vals = st.InputDataTableVarDropDownValues;
                            if ~isempty(vals)
                                vals = strip(vals,'left','.');
                                inputs = [inputs {'TableVariableNames' vals}];
                            end
                        end
                    end
                    task.initialize(inputs{:});
                end
                task.LayoutManager.Padding = 0;
            end

            app.InitialGrid.Parent = [];
            if ~isempty(nonselectedTask)
                nonselectedTask.LayoutManager.Parent = [];
            end
            task.LayoutManager.Parent = app.LayoutManager;
            
            app.SelectedTask = src.Tag;
            notifyStateChanged(app);
        end

        function notifyStateChanged(app,~,~)
            if ~isempty(app.SelectedTask)
                % in case the AutoRun of the subtask has been updated,
                % update it for the uber task here
                if isequal(app.SelectedTask,'trendRemover')
                    task = app.RemoveTrendsSubTask;
                else
                    task = app.FindSeasonalTrendsSubTask;
                end
                app.AutoRun = task.AutoRun;
            end
            notify(app,'StateChanged');
        end

        function resetToLandingPage(app,~,~)
            % unparent any existing subtask, and reparent startup grid
            if ~isempty(app.RemoveTrendsSubTask)
                app.RemoveTrendsSubTask.LayoutManager.Parent = [];
            end
            if ~isempty(app.FindSeasonalTrendsSubTask)
                app.FindSeasonalTrendsSubTask.LayoutManager.Parent = [];
            end
            app.InitialGrid.Parent = app.LayoutManager;
            app.SelectedTask = '';
            if nargin > 1
                % comes from clicking home button rather than set.State
                notify(app,'StateChanged')
            end
        end
    end

    methods
        function [code,outputs] = generateCode(app)
            if isempty(app.SelectedTask)
                code = '';
                outputs = {};
            elseif isequal(app.SelectedTask,'trendRemover')
                [code, outputs] = app.RemoveTrendsSubTask.generateCode;
            else
                [code, outputs] = app.FindSeasonalTrendsSubTask.generateCode;
            end
        end

        function summary = get.Summary(app)
            if isempty(app.SelectedTask)
                summary = getString(message('MATLAB:dataui:Tool_FindTrendsTask_Description'));
            elseif isequal(app.SelectedTask,'trendRemover')
                summary = app.RemoveTrendsSubTask.Summary;
            else
                summary = app.FindSeasonalTrendsSubTask.Summary;
            end
        end

        function state = get.State(app)
            if isempty(app.SelectedTask)
                state = struct();
            elseif isequal(app.SelectedTask,'trendRemover')
                state = app.RemoveTrendsSubTask.State;
            else
                state = app.FindSeasonalTrendsSubTask.State;
            end
            state.SelectedTask = app.SelectedTask;
        end

        function set.State(app,state)
            if isfield(state,'SelectedTask')
                app.SelectedTask = '';
                if ismember(state.SelectedTask,{'FindSeasonalTrendsTask','trendRemover'})
                    app.SelectedTask = state.SelectedTask;
                end
            else
                % comes from a version before seasonal trends
                app.SelectedTask = 'trendRemover';
            end
            if isequal(app.SelectedTask,'FindSeasonalTrendsTask')                
                % create or get find seasonal trends task and set its state
                startSubTask(app,app.FindSeasonalTrendsButton);
                app.FindSeasonalTrendsSubTask.State = state;
            elseif isequal(app.SelectedTask,'trendRemover')
                % create or get remove trends task and set its state
                startSubTask(app,app.RemoveTrendsButton);
                app.RemoveTrendsSubTask.State = state;
            else
                resetToLandingPage(app);
            end
        end

        function reset(app)
            if isequal(app.SelectedTask,'trendRemover')
                app.RemoveTrendsSubTask.reset();
            elseif isequal(app.SelectedTask,'FindSeasonalTrendsTask')
                app.FindSeasonalTrendsSubTask.reset();
            end
        end

        function initialize(app,varargin)
            % save inputs to push them to the subtask when it is created
            app.InitializeInputs = varargin;
        end
    end
end