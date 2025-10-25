classdef (Hidden = true,Sealed = true) tableStacker < ...
        matlab.internal.dataui.stackUnstackEmbedder
    % Table Stacker live task for stacking table variables in a Live Script
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2019-2024 The MathWorks, Inc.

    properties (Access = public, Hidden)
        VariableDropdowns
    end

    properties (Constant, Transient, Hidden)
        OutputName char = 'stackedTable';
        TimeColumnWidth double = 120;
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2020a)
        %       2: Add versioning (R2020b)
        %       3: Use Base Class (R2022a)
        Version double = 3;
    end

    properties
        State
        Summary
    end

    methods (Access = protected)
        % Required by inherited class
        function createTableSection(app)
            app.PreviewGrid = createNewSection(app,getMsgText(app,'StackRowDelimiter'),{'fit'},2);
            app.PreviewGrid.RowHeight{2} = app.TableRowHeight;
            app.PreviewGrid.ColumnSpacing = 0;
            app.PreviewGrid.RowSpacing = 0;
            % column width is set dynamically
            app.VariableDropdowns = uidropdown(app.PreviewGrid);
            if ~isAppWorkflow(app)
                % don't generate preview table in dataCleaner app
                app.PreviewTable = uitable(app.PreviewGrid);
            end
            app.NumTableVars = 3;
        end

        function setWidgetsToDefault(app)
            resetPreviewGrid(app);
            app.OutputTableCheckbox.Value = ~isAppWorkflow(app);
            app.InputTableCheckbox.Value = false;
        end

        function doUpdate(app,~,~)
            if nargin > 1
                % this comes from a callback to a widget
                checkForClearedVariables(app);
            end

            hasInput = hasInputData(app);

            [app.VariableDropdowns.Enable] = deal(hasInput);
            
            if ~isAppWorkflow(app)
                drawnow;
                if hasInput
                    app.PreviewTable.Enable = 'on';
                else
                    app.PreviewTable.Enable = 'off';
                end
            end
            [app.VariableDropdowns(strcmp({app.VariableDropdowns.Value},'stack')).Tooltip] = ...
                deal(getMsgText(app,'StackTooltip'));
            [app.VariableDropdowns(strcmp({app.VariableDropdowns.Value},'constant')).Tooltip] = ...
                deal(getMsgText(app,'ConstantTooltip'));
            [app.VariableDropdowns(strcmp({app.VariableDropdowns.Value},'discard')).Tooltip] = ...
                deal(getMsgText(app,'DiscardTooltip'));

            updateVisualizationSection(app);

            % 'StateChanged' needed when widgets are dynamically added
            notify(app,'StateChanged')
        end

        function resetPreviewGrid(app,isFromSetState)
            if nargin < 2
                isFromSetState = false;
            end
            % clear out existing checkboxes
            if ~isempty(app.VariableDropdowns)
                delete(app.VariableDropdowns);
                app.VariableDropdowns(1:end) = [];
            end
            resetCommonPreviewGridProperties(app,isFromSetState);

            for k = 1 : app.NumTableVars
                app.VariableDropdowns(k) = uidropdown(app.PreviewGrid, ...
                    'Items',[getMsgText(app,'Stack') getMsgText(app,'Constant') getMsgText(app,'Discard')],...
                    'ItemsData',{'stack' 'constant' 'discard'},...
                    'ValueChangedFcn',@app.doUpdate,'Value','constant');
                app.VariableDropdowns(k).Layout.Row = 1;
                app.VariableDropdowns(k).Layout.Column = k+1;
            end

            resetTableFromInputData(app);
        end

        function localInitializeVariables(app,varNames)
            % set selected variables to be the stacking variables
            allVars = app.TableVarNames(1:end-app.InputHasRowLabels);            
            [~,stackInd] = ismember(varNames,allVars);
            % get indices for members only, remove non-members
            stackInd = setdiff(stackInd,0);
            [app.VariableDropdowns(stackInd).Value] = deal('stack');
            [app.VariableDropdowns(setdiff(1:numel(allVars),stackInd)).Value] = deal('constant');
        end

        function workspaceChangedFcn(~)
            % not used by this subclass, since all widget values work in
            % both the base and other workspaces
        end
    end

    methods (Access = public)
        function [code,outputs] = generateScript(app,isForExport,overwriteInput)
            if nargin < 2
                % Second input is for "cleaned up" export code. E.g., don't
                % introduce temp vars for plotting.
                isForExport = false;
            end
            if nargin < 3
                % Third input is for whether or not we want to overwrite
                % the input with the output
                overwriteInput = isForExport;
            end
            outputs = {};
            code = '';
            if overwriteInput && ~isForExport
                % overwriting input is only supported for export script
                return
            end
            if ~hasInputData(app) || ...
                    (isForExport && ~any(strcmp({app.VariableDropdowns.Value},'stack')))
                % Don't generate no-op code
                return
            end
            
            input = app.TableDropDown.Value;
            if ~isAppWorkflow(app)
                % add ticks for live editor workflow, but not app workflow
                input = ['`' input '`'];
            end            
            if overwriteInput
                outputs = {input};
            else
                outputs = {app.OutputName};
            end

            code = ['% ' char(getMsgText(app,'Stackvariables')) newline];

            if ~any(strcmp({app.VariableDropdowns.Value},'stack'))
                % no stacking - output is input
                code = [code outputs{1} ' = ' input];
                if any(strcmp({app.VariableDropdowns.Value},'discard'))
                    % discard appropriate vars
                    discardVars = app.TableVarNames(strcmp({app.VariableDropdowns.Value},'discard'));
                    code = [code ';' newline];
                    code = [code outputs{1} '(:,'];
                    code = matlab.internal.dataui.addCellStrToCode(code,discardVars);
                    code = [code ') = []'];
                end
            else
                code = [code outputs{1} ' = stack('];
                % U
                code = matlab.internal.dataui.addCharToCode(code,[input ',']);

                % Vars
                dataVars = app.TableVarNames(strcmp({app.VariableDropdowns.Value},'stack'));
                code = matlab.internal.dataui.addCellStrToCode(code,dataVars);

                % ConstantVariables
                constantVars = app.TableVarNames(strcmp({app.VariableDropdowns.Value},'constant'));

                if (numel(constantVars) + numel(dataVars)) < app.NumTableVars
                    % if all non dataVars are constantVars, this is default
                    code = matlab.internal.dataui.addCharToCode(code,',ConstantVariables=');
                    code = matlab.internal.dataui.addCellStrToCode(code,constantVars);
                end
                code = [code ')'];
            end
            if app.InputTableCheckbox.Value || ~app.OutputTableCheckbox.Value
                code = [code ';'];
            end
        end

        function setTaskState(app,state,~)
            % third input is name of control in dataCleaner app case, but
            % this is unchanged here since doUpdate does not rely on src
            if ~isfield(state,'VersionSavedFrom')
                state.VersionSavedFrom = 1;
                state.MinCompatibleVersion = 1;
            end
            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version
                % do not set any properties
                doUpdate(app);
            else
                setCommonStateProperties(app,state);
                if isfield(state,'VariableDropdowns')
                    [app.VariableDropdowns.Value] = deal(state.VariableDropdowns{:});
                end
                doUpdate(app);
            end
        end

        function propTable = getPropertyInformation(app)
            % propTable is a list of all the controls visible in the Data
            % Cleaner app along with everything needed to map the
            % uifigure into the property inspector

            % We boil this task down to two controls: Input table, and
            % Stacking variables (a multi-select dropdown). 

            Name = ["TableDropDown";"StackingVariables"];
            Group = repmat(getMsgText(app,'DataDelimiter',true),2,1);
            DisplayName = [getMsgText(app,'InputTable'); getMsgText(app,'Stackvariables')];
            StateName = ["TableDropDownValue"; "StackingVariables"];
            
            Type = {'matlab.ui.control.internal.model.WorkspaceDropDown'; 'MultiselectDropDown'};
            Tooltip = {''; ''};
            varList = app.TableVarNames;
            if app.InputHasRowLabels
                % don't list time or row labels
                varList(end) = [];
            end
            % dataCleaner API expects Items for a multiselect dropdown to
            % start with a throwaway item like 'select'
            varList = [{''} varList];
            app.TableDropDown.populateVariables();
            Items = {app.TableDropDown.Items; varList};
            ItemsData = {app.TableDropDown.ItemsData; varList};
            on = matlab.lang.OnOffSwitchState.on;
            Visible = [numel(app.TableDropDown.Items) > 2; on]; % input shown only when more than one table in the app
            Enable = [on; on]; % should always be enabled since input always selected
            InitializeFlag = [1; 2];
            InSubgroup = [false; false];
            GroupExpanded = [true; true];
            SpinnerProperties = {[]; []};

            propTable = table(Name,Group,DisplayName,StateName,Type,Tooltip,...
                Items,ItemsData,Visible,Enable,InitializeFlag,InSubgroup,GroupExpanded,SpinnerProperties);
        end

        function msg = getInspectorDisplayMsg(~)
            % used in data cleaner app to display when no valid variables,
            % but stack only requires table to have at least 2 variables,
            % no requirements on the vars themselves
            msg = '';
        end
    end

    methods
        % Required for embedding in the live editor
        function summary = get.Summary(app)
            if ~hasInputData(app)
                summary = string(message('MATLAB:tableui:Tool_tableStacker_Description'));
            else
                varNames = app.TableVarNames(strcmp({app.VariableDropdowns.Value},'stack'));
                tableName = ['`' app.TableDropDown.Value '`'];
                switch numel(varNames)
                    case 2
                        summary = getMsgText(app,'StackSummary2',false,...
                            ['`' varNames{1} '`'],['`' varNames{2} '`'],tableName);
                    case 3
                        summary = getMsgText(app,'StackSummary3',false,...
                            ['`' varNames{1} '`'],['`' varNames{2} '`'],['`' varNames{3} '`'],tableName);
                    otherwise
                        summary = getMsgText(app,'StackSummary1',false,tableName);
                end
            end
        end

        function state = get.State(app)
            state = struct('VersionSavedFrom',app.Version,...
                'MinCompatibleVersion',1,...
                'TableDropDownValue',app.TableDropDown.Value,...
                'OutputTableCheckboxValue',app.OutputTableCheckbox.Value,...
                'InputTableCheckboxValue',app.InputTableCheckbox.Value,...
                'NumTableVars',app.NumTableVars,...
                'TableVarNames',{app.TableVarNames},...
                'InputHasRowLabels',app.InputHasRowLabels,...
                'VariableDropdowns',{{app.VariableDropdowns.Value}});

            % save stacking variables for prop inspector
            % these are set with initialize instead of setState
            state.StackingVariables = app.TableVarNames(strcmp({app.VariableDropdowns.Value},'stack'));
        end

        function set.State(app,state)
            setTaskState(app,state);
        end
    end

end
