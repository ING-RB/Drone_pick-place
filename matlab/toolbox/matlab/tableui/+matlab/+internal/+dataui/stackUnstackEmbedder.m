classdef (Hidden = true, AllowedSubclasses = ...
        {?matlab.internal.dataui.tableUnstacker ...
        ?matlab.internal.dataui.tableStacker}) ...
        stackUnstackEmbedder < matlab.task.LiveTask
    % Helper for stack and unstack live tasks
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        UIFigure                            matlab.ui.Figure
        Accordion                           matlab.ui.container.internal.Accordion
        TableDropDown                       matlab.ui.control.internal.model.WorkspaceDropDown
        PreviewTable                        matlab.ui.control.Table
        PreviewGrid                         matlab.ui.container.GridLayout
        OutputTableCheckbox                 matlab.ui.control.CheckBox
        InputTableCheckbox                  matlab.ui.control.CheckBox
        NumTableVars                        double
        TableVarNames                       cell
        InputHasRowLabels                   logical
    end
    
    properties (Constant, Transient, Hidden)
        TextRowHeight    = 22;
        TableRowHeight   = 95;
        TableColumnWidth = 120;
        ScrollBarWidth   = 19;
        NumRowsToPreview = 50;
        AutoRunCutOff    = 1e6; % numel to trigger turning off AutoRun
    end

    properties
        Workspace = "base"
    end
    
    % Write over constructor so we can keep this API with dataCleaner app
    methods (Access = public)
        function app = stackUnstackEmbedder(fig,workspace)
            arguments
                fig = uifigure("Position",[200 200 600 500]);
                workspace = "base";
            end
            app@matlab.task.LiveTask("Parent",fig);
            app.UIFigure = fig;
            % set workspace before creating components so we know whether
            % to create the table preview
            app.Workspace = workspace;
            createComponents(app);
            doUpdate(app);
        end
    end

    % setup required by base class
    methods (Access = protected)
        function setup(~)
        end
    end
    
    methods (Access = public, Abstract)
        [code,outputs] = generateScript(app)
    end
    
    % Required for embedding in a Live Script
    methods (Access = public)
        function reset(app,~,~)
            if ~checkForClearedVariables(app)
                setWidgetsToDefault(app);
            end

            if nargin > 1
                % Called as callback from input dropdown.
                % If data is too large, turn auto-run off.
                % Once triggered, user is in control, so no need to reset to
                % true for small data
                if numel(app.TableDropDown.WorkspaceValue) > app.AutoRunCutOff
                    app.AutoRun = false;
                end
            end
            doUpdate(app);
        end

        function code = generateVisualizationScript(app)
            code = '';
            if app.InputTableCheckbox.Value
                code = ['% ' char(getMsgText(app,'Visualizeresults',true)) newline];
                code = [code '`' app.TableDropDown.Value '`'];
                if app.OutputTableCheckbox.Value
                    code = [code newline app.OutputName];
                end
            end
        end

        function [code,outputs] = generateCode(app)
			[code,outputs] = generateScript(app);
			vcode = generateVisualizationScript(app);
			if ~isempty(vcode)
				code = [code newline newline vcode];
			end
		end
        
        function initialize(app,NVpairs)
            % Executed by container after creation of task
            % This method programmatically sets widget values and runs the
            % appropriate callbacks
            arguments
                app
                NVpairs.Inputs  string = "";
                NVpairs.TableVariableNames string = "";
                NVpairs.Code string = "";
            end
            % Inputs - the names of the input timetable. Only the first
            %          element is used
            % TableVariableNames - stack: stacking variables
            %                    - unstack: unused
            
            if ~isempty(NVpairs.Inputs)
                app.TableDropDown.populateVariables();
                if ismember(NVpairs.Inputs(1),app.TableDropDown.ItemsData)
                    app.TableDropDown.Value = NVpairs.Inputs(1);
                    setWidgetsToDefault(app);
                end
                if ~isequal(NVpairs.TableVariableNames,"") && ~isempty(NVpairs.TableVariableNames)
                    localInitializeVariables(app,NVpairs.TableVariableNames)
                end
                if numel(app.TableDropDown.WorkspaceValue) > app.AutoRunCutOff
                    app.AutoRun = false;
                end
                doUpdate(app);
            end
        end
    end
    
    methods (Access = protected)
        % Internal app methods
        function createComponents(app)
            % The entire app uses a uigridlayout
            app.LayoutManager.RowHeight = {'fit'};
            app.LayoutManager.ColumnWidth = {'1x'};
            % the grid is split into accordion panels
            app.Accordion = matlab.ui.container.internal.Accordion('Parent',app.LayoutManager);
            % create widget rows
            createInputDataSection(app);
            createTableSection(app);
            createVisualizationSection(app);
            % set task to default state
            setInputDataAndWidgetsToDefault(app);
        end
        
        function G = createNewSection(app,textLabel,c,numRows)
            S = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            S.Title = textLabel;
            G = uigridlayout(S,'ColumnWidth',c,'RowHeight',repmat({'fit'},1,numRows));
        end
        
        function createInputDataSection(app)
            h = createNewSection(app,getMsgText(app,'Selecttable'),{'fit',app.TableColumnWidth},1);
            
            uilabel(h,'Text',getMsgText(app,'InputTable'));
            app.TableDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            app.TableDropDown.Workspace = app.Workspace;
            
            % Properties
            app.TableDropDown.ValueChangedFcn = @app.reset;
            app.TableDropDown.FilterVariablesFcn = @(A)isa(A,'tabular') && ~isempty(A) && size(A,2)>1;
            app.TableDropDown.ShowNonExistentVariable = true;
        end
                
        function createVisualizationSection(app)
            h = createNewSection(app,getMsgText(app,'Visualizeresults',true),{'fit' 'fit'},1);
            
            app.InputTableCheckbox = uicheckbox(h,...
                'Text', getMsgText(app,'InputTable'),...
                'ValueChangedFcn',@app.doUpdate);
            
            app.OutputTableCheckbox = uicheckbox(h,...
                'Text', getMsgText(app,'Outputtable',true),...
                'ValueChangedFcn',@app.doUpdate);
        end
        
        function setInputDataAndWidgetsToDefault(app)
            app.TableDropDown.Value = 'select variable';
            setWidgetsToDefault(app);
        end
        
        function hasInput = hasInputData(app)
            hasInput = ~strcmp(app.TableDropDown.Value,'select variable');
        end
        
        function resetCommonPreviewGridProperties(app,isFromSetState)
            if ~isFromSetState
                if hasInputData(app)
                    T = app.TableDropDown.WorkspaceValue;
                    app.NumTableVars = width(T);
                    app.InputHasRowLabels = istimetable(T) || ~isempty(T.Properties.RowNames);
                else
                    app.NumTableVars = 3;
                    app.InputHasRowLabels = false;
                end
            end
            if ~isAppWorkflow(app)
                % reset width - first need to get the table out of extra columns
                app.PreviewTable.Layout.Column = 2;
            end
            app.PreviewGrid.ColumnWidth = repmat({app.TableColumnWidth},1,app.NumTableVars+1);
            % add room for the table vertical scroll bar
            app.PreviewGrid.ColumnWidth(end+1) = {app.ScrollBarWidth};
        end
        
        function resetTableFromInputData(app)
            if hasInputData(app)
                T = app.TableDropDown.WorkspaceValue;
                if ~isempty(T)
                    app.TableVarNames = T.Properties.VariableNames;
                    varNames = app.TableVarNames;
                    if app.InputHasRowLabels
                        dimName = T.Properties.DimensionNames(1);
                        app.TableVarNames(end+1) = dimName;
                        varNames = [dimName varNames];
                        if istimetable(T)
                            % move rowtimes into a variable
                            T = timetable2table(T);
                        else
                            % move rownames into a variable
                            T = addvars(T,T.Properties.RowNames,'Before',1);
                            T.Properties.RowNames = {};
                        end
                    end
                else
                    % this is from SetState AND table is not in workspace.
                    % but we do have the variable names
                    varNames = app.TableVarNames;
                    if app.InputHasRowLabels
                        % the rows are at the end so that button indexing
                        % works, move them to the front for display
                        varNames = [varNames(end) varNames(1:end-1)];
                    end
                    T = array2table(zeros(4,numel(varNames)),'VariableNames',varNames);
                end
            else
                T = array2table(zeros(4,app.NumTableVars));
                app.TableVarNames = {};
                varNames = T.Properties.VariableNames;
            end
            if isAppWorkflow(app)
                % no preview table to update
                return
            end

            doRowColor = false;
            if height(T) > app.NumRowsToPreview
                % Cut the preview short for performance
                T(app.NumRowsToPreview+1:end,:) = [];
                doRowColor = true;
            end
            
            app.PreviewTable.Data = T;
            app.PreviewTable.ColumnName = varNames;
            app.PreviewTable.ColumnWidth = repmat({app.TableColumnWidth},1,width(T));
            if ~app.InputHasRowLabels
                app.PreviewTable.Layout.Column = [2 app.NumTableVars+2];
                app.PreviewGrid.ColumnWidth{1} = 'fit';
            else
                app.PreviewTable.Layout.Column = [1 app.NumTableVars+2];
                app.PreviewGrid.ColumnWidth{1} = app.TimeColumnWidth;
                app.PreviewTable.ColumnWidth{1} = app.TimeColumnWidth;
            end
            % Setting the last column to '1x' allows the last column to
            % fill in the space regardless of the size of the scrollbar
            app.PreviewTable.ColumnWidth{end} = '1x';
            
            if doRowColor
                % Color last row gray to indicate data has been truncated
                app.PreviewTable.Tooltip = app.getMsgText('UITableTooltip');
                s = matlab.ui.style.internal.SemanticStyle('BackgroundColor','mw-backgroundColor-primary');                
                app.PreviewTable.addStyle(s,'row', app.NumRowsToPreview);
            else
                app.PreviewTable.Tooltip = '';
            end
            app.PreviewTable.RowStriping = 'off';
        end
        
        function didReset = checkForClearedVariables(app)
            didReset = false;
            if isempty(app.TableDropDown.WorkspaceValue) && ~strcmp(app.TableDropDown.Value,'select variable')
                % the input variable has been cleared - reset the app
                setInputDataAndWidgetsToDefault(app);
                didReset = true;
            end
        end
        
        function setCommonStateProperties(app,state)
            for k = ["TableDropDown" "OutputTableCheckbox" "InputTableCheckbox"]
                if isfield(state,k + "Value")
                    app.(k).Value = state.(k + "Value");
                end
            end
            for k = ["NumTableVars" "TableVarNames" "InputHasRowLabels"]
                if isfield(state,k)
                    val = state.(k);
                    if ~isrow(val)
                       % force TableVarNames to be row vector
                       % jsonencoding/decoding changes row vectors to column vectors
                       val = val';
                    end
                    if isempty(val)
                        % if we get here, then TableVarNames is empty
                        % double, but we need empty cell
                        val = {};
                    end
                    app.(k) = val;
                end
            end
            resetPreviewGrid(app,true);
        end
        
        function updateVisualizationSection(app)
            app.OutputTableCheckbox.Enable = hasInputData(app);
            app.InputTableCheckbox.Enable = hasInputData(app);
        end

        function tf = isAppWorkflow(app)
            % indicates whether this instance is in dataCleaner app
            tf = ~isequal(app.Workspace,'base');
        end

        function txt = getMsgText(~,id,usedataui,varargin)
            if nargin < 3
                usedataui = false;
            end
            if usedataui
                txt = string(message(['MATLAB:dataui:' id],varargin{:}));
            else
                txt = string(message(['MATLAB:tableui:tableUnstacker' id],varargin{:}));
            end
        end
    end

    methods
        function set.Workspace(app,ws)
            app.Workspace = ws;
            if ~isempty(app.TableDropDown) %#ok<*MCSUP> 
                app.TableDropDown.Workspace = ws;
                workspaceChangedFcn(app);
            end
        end
    end
    
    methods (Abstract,Access = protected)
        % Required by above methods
        createTableSection(app)
        setWidgetsToDefault(app)
        doUpdate(app)
        resetPreviewGrid(app,isFromSetState)
        localInitializeVariables(app,varNames)
        workspaceChangedFcn(app)
    end
end



