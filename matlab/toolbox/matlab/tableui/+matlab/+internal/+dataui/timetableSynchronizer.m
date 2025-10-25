classdef (Hidden = true,Sealed = true) timetableSynchronizer < ...
        matlab.internal.dataui.retimeSynchEmbedder
    % Synchronize Timetables live editor task
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Table input widgets
        InputGrid                           matlab.ui.container.GridLayout
        AddButtons                          matlab.ui.control.Image
        SubtractButtons                     matlab.ui.control.Image
        
        % override widgets
        OverrideDropdownsTT                 matlab.ui.control.DropDown

        % Helpers
        DedupedOverrideNames % deduped names of Override variables for output timetable
        InputIndexingCode    % used for generating code for synchronize call
    end
    
    properties (Constant, Transient, Hidden)
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2020a)
        %       2: Add versioning (R2020b)
        %       3: Accordions, Merge method dropdowns (R2021a)
        %       4: Unlimited inputs (R2021b)
        %       5: Use Base Class (R2022a)
        %       6: Update new time method based on keyword (R2024a)
        %       7: Use FunctionSelector for custom aggregation function (R2024b)
        Version = 7;
    end

    properties
        Summary
    end
    
    methods (Access = protected)
        function createInputDataSection(app)
            app.InputGrid = createNewSection(app,getCommonMsg(app,'DataDelimiter'),...
                {'fit',app.DropDownWidth,app.IconColumnWidth,app.IconColumnWidth},2);
            
            uilabel(app.InputGrid,'Text',getLocalMsg(app,'Inputtimetables'));
            
            createInputRow(app,1);
            createInputRow(app,2);
            app.NumInputTables = 2;
        end
        
        function setOverrideGridColumnWidth(app)
            app.OverrideGrid.ColumnWidth = {app.DropDownWidth app.DropDownWidth ...
                app.DropDownWidth app.IconColumnWidth app.IconColumnWidth};
        end
        
        function name = inputDataName(app)
            name = getLocalMsg(app,'Inputtimetables');
        end
        
        function resetOverrides(app)
            if ~isempty(app.OverrideDropdownsTT)
                delete(app.OverrideDropdownsTT);
                app.OverrideDropdownsTT(:) = [];
                delete(app.OverrideDropdownsVar);
                app.OverrideDropdownsVar(:) = [];
                delete(app.OverrideDropdownsMethods);
                app.OverrideDropdownsMethods(:) = [];
                delete(app.OverrideSubtractButtons);
                app.OverrideSubtractButtons(:) = [];
                delete(app.OverrideAddButtons);
                app.OverrideAddButtons(:) = [];
            end
            app.NumOverrides = 0;
            updateOverrideLocations(app);
        end
        
        function neededOverride = localAutoPopulateOverrides(app,filterFcn,checkOnly)
            % third input is not used here, only in timetableRetimer
            neededOverride = false;
            for kk = 1:app.NumInputTables
                TT = app.TableDropDowns(kk).WorkspaceValue;
                if ~isempty(TT)
                    tableName = app.TableDropDowns(kk).Value;
                    for jj = 1:width(TT)
                        if ~filterFcn(TT{1,jj})
                            neededOverride = true;
                            if checkOnly
                                % stop now before we actually populate anything
                                return
                            end
                            varName = TT.Properties.VariableNames{jj};
                            % check to see if it is already an override
                            isOverride = app.NumOverrides > 0 &&...
                                any(strcmp({app.OverrideDropdownsTT.Value},tableName) & ...
                                strcmp({app.OverrideDropdownsVar.Value},varName));
                            if ~isOverride
                                % add a new override row and set the value
                                app.addOverrideRow([],[],true);
                                app.OverrideDropdownsTT(app.NumOverrides).Value = tableName;
                                populateOverrideDropdownsVar(app);
                                app.OverrideDropdownsVar(app.NumOverrides).Value = varName;
                                populateOverrideDropdownsMethod(app,app.NumOverrides)
                                app.OverrideDropdownsMethods(app.NumOverrides).Value = ...
                                    app.OverrideDropdownsMethods(app.NumOverrides).ItemsData{1};
                            end
                        end
                    end
                end
            end
        end
        
        function populateOverrideDropdownsVar(app)
            for k = 1:app.NumOverrides
                % get current value to see if it changes
                val = app.OverrideDropdownsVar(k).Value;
                % get all the tt variables
                T = evalin(app.Workspace,app.OverrideDropdownsTT(k).Value);
                varNames = T.Properties.VariableNames;
                % take out any previously chosen variables
                ind = strcmp({app.OverrideDropdownsTT(1:k-1).Value},app.OverrideDropdownsTT(k).Value);
                varNames = setdiff(varNames,{app.OverrideDropdownsVar(ind).Value},'stable');
                % set the items to what is left
                app.OverrideDropdownsVar(k).Items = varNames;
                if ~isempty(varNames) && ~isequal(val,app.OverrideDropdownsVar(k).Value)
                    populateOverrideDropdownsMethod(app,k);
                end
            end
        end

        function updateOverrideLocations(app)
            % Update props to be used by generated script:
            % - InputIndexingCode
            % - OverrideLocations
            % - DedupedOverrideNames
            
            ind = ~strcmp({app.TableDropDowns.Value},app.SelectVariable);
            inputs = {app.TableDropDowns(ind).Value};
            app.InputIndexingCode = repmat({''},numel(inputs),1);
            if app.NumOverrides == 0
                app.OverrideLocations = [];
                app.DedupedOverrideNames = {};
                return
            end

            % For each timetable, save the char needed to index into it for
            % generating the synchronize call. Example:  '(:,[1 3])' if
            % Var2 is an override in that timetable or '' if that timetable
            % has no overrides.
            for k = 1:numel(inputs)                
                rowsforinputk = strcmp({app.OverrideDropdownsTT.Value},inputs{k});
                if any(rowsforinputk)
                    % index into the table appropriately
                    overrideVars = {app.OverrideDropdownsVar(rowsforinputk).Value};
                    allVars = evalin(app.Workspace,[inputs{k} '.Properties.VariableNames']);
                    [~,indOverrideVars] = ismember(overrideVars,allVars);
                    indNonOverrideVars = setdiff(1:numel(allVars),indOverrideVars);
                    app.InputIndexingCode{k} = ['(:,' mat2str(indNonOverrideVars) ')'];
                end
            end
            
            % Get the locations of the overrides in the output timetable
            TableWidths = cellfun(@width,{app.TableDropDowns(ind).WorkspaceValue});
            % get all table/variable names in one cell array
            TableNames = repelem(inputs,TableWidths);
            VarNames = cellfun(@(x) x.Properties.VariableNames,...
                {app.TableDropDowns(ind).WorkspaceValue}, 'UniformOutput', false);
            VarNames = [VarNames{:}];
            % use these to locate the selected overrides
            [~,app.OverrideLocations] = ismember(strcat({app.OverrideDropdownsTT.Value},...
                {app.OverrideDropdownsVar.Value}),strcat(TableNames,VarNames));

            % Compute desired (deduped) output names for variables
            finalVarNames = VarNames;
            checkAgain = false;
            % if its a duplicate, then append the table name
            for k = 1:length(VarNames)
                if nnz(strcmp(VarNames,VarNames{k})) > 1
                    finalVarNames{k} = [VarNames{k} '_' TableNames{k}];
                    checkAgain = true;
                end
            end
            if checkAgain
                % double-check that the names we just created aren't also in the list
                
                % sort finalVarNames so non-overrides are first since they will be generated first
                NonOverrideLocations = setdiff(1:numel(finalVarNames),app.OverrideLocations);
                finalVarNames = [finalVarNames(NonOverrideLocations) finalVarNames(app.OverrideLocations)];
                
                % dedupe the names
                finalVarNames = matlab.internal.tabular.makeValidVariableNames(finalVarNames,'silent');
                app.DedupedOverrideNames = finalVarNames(end-app.NumOverrides+1:end);
            else
                app.DedupedOverrideNames = VarNames(app.OverrideLocations);
            end
        end
        
        function hasInput = hasInputData(app)
            hasInput = nnz(~strcmp({app.TableDropDowns(1:app.NumInputTables).Value},app.SelectVariable)) >= 2;
        end

        function setAutoRun(app)
            % If data is too large, turn auto-run off.
            % Once triggered, user is in control, so no need to reset to
            % true for small data
            numelPerInput = cellfun(@numel,{app.TableDropDowns.WorkspaceValue});
            if nnz(numelPerInput) > 1 && sum(numelPerInput) > app.AutoRunCutOff
                app.AutoRun = false;
            end
        end
    end

    methods (Access = ?matlab.internal.dataui.retimeSynchEmbedder)
        function createInputRow(app,k)
            app.TableDropDowns(k) = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.InputGrid,...
                'Tag','Input change','ValueChangedFcn',@app.doUpdate,'ShowNonExistentVariable',true);
            app.TableDropDowns(k).Workspace = app.Workspace;
            app.TableDropDowns(k).FilterVariablesFcn = @(t,tName)app.filterInputTable(t,tName,k);
            app.TableDropDowns(k).Layout.Column = 2;
            app.TableDropDowns(k).Layout.Row = k;

            app.SubtractButtons(k) = uiimage(app.InputGrid,'ScaleMethod','none',...
                'ImageClickedFcn',{@app.subtractInputTable,k},'Tag','Input change',...
                'Tooltip',getLocalMsg(app,'SubtractInputTooltip'));
            matlab.ui.control.internal.specifyIconID(app.SubtractButtons(k),...
                'minusUI',app.IconColumnWidth,app.IconColumnWidth);
            app.SubtractButtons(k).Layout.Column = 3;
            app.SubtractButtons(k).Layout.Row = k;

            app.AddButtons(k) = uiimage(app.InputGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.addInputTable,...
                'Tooltip',getLocalMsg(app,'AddInputTooltip'));
            matlab.ui.control.internal.specifyIconID(app.AddButtons(k),...
                'plusUI',app.IconColumnWidth,app.IconColumnWidth);
            app.AddButtons(k).Layout.Column = 4;
            app.AddButtons(k).Layout.Row = k;
        end
        
        function isSupported = filterInputTable(app,t,tName,k)
            % reset app if a variable has been cleared
            if checkForClearedVariables(app)
                setWidgetsToDefault(app);
                doUpdate(app);
            end
            
            % Support all non-empty timetables except when class of time
            % vector does not match (i.e. can't do duration with datetime)
            isSupported = istimetable(t) && ~isempty(t);
            isAppWorkflow = ~isequal(app.Workspace,'base');
            if isAppWorkflow && k == 1
                % In app, we force users to pick first timetable before
                % others. So need to allow all tts, regardless of what has
                % been chosen in other tts.
                return
            end
            
            if isSupported
                timeClass = class(t.Properties.RowTimes);
                if isAppWorkflow
                    % Make sure class of time vector matches that of the tt
                    % in the first dd.
                    % Also make sure multiselect doesn't include tt chosen
                    % in first dd.
                    DDsToCheckAgainst = 1;
                else
                    % Make sure class of time vector matches all the others
                    % in the task already.
                    % Also, we want to make sure we don't allow selecting
                    % a given tt more than once.
                    DDsToCheckAgainst = setdiff(1:app.NumInputTables,k);
                end
                for j = DDsToCheckAgainst
                    doCheck =  ~isempty(app.TableDropDowns(j).WorkspaceValue);
                    if doCheck
                        isSupported = strcmp(timeClass,class(app.TableDropDowns(j).WorkspaceValue.Properties.RowTimes)) &&...
                            ~isequal(tName,app.TableDropDowns(j).Value);
                    end
                    if ~isSupported
                        break
                    end
                end
            end
        end
        
        function addOverrideDropdownTT(app)
            app.OverrideDropdownsTT(app.NumOverrides) = uidropdown(app.OverrideGrid,...
                'ValueChangedFcn',@app.doUpdate,'Tag','OverrideTTChange',...
                'Tooltip',getLocalMsg(app,'OverrideTTTooltip'),'UserData',app.NumOverrides);
            app.OverrideDropdownsTT(app.NumOverrides).Layout.Row = app.NumOverrides;
            app.OverrideDropdownsTT(app.NumOverrides).Layout.Column = 1;
            populateOverrideDropdownsTT(app);
        end
        
        function addInputTable(app,src,event)
            if checkForClearedVariables(app)
                setWidgetsToDefault(app);
            end
            app.NumInputTables = app.NumInputTables + 1;
            createInputRow(app,app.NumInputTables)
            app.IsSortedTimes(app.NumInputTables) = true;
            doUpdate(app,src,event);
        end
        
        function subtractInputTable(app,src,~,k)
            if app.NumInputTables == 2
                % can only get here if user clicks '-' buttons too fast
                return
            end
            tag = src.Tag;
            app.NumInputTables = app.NumInputTables - 1;
            deleteInputRow(app,k);
            
            checkForClearedVariables(app);
            % in case source was just deleted, send in struct with 'Tag'
            doUpdate(app,struct('Tag',tag),[]);
        end
        
        function deleteInputRow(app,k)
            % shift up everything visible below selected row so we can
            % remove the last one
            for j = k:numel(app.TableDropDowns)-1
                app.TableDropDowns(j).Items = app.TableDropDowns(j+1).Items;
                app.TableDropDowns(j).ItemsData = app.TableDropDowns(j+1).ItemsData;
                app.TableDropDowns(j).Value = app.TableDropDowns(j+1).Value;
            end
            % delete the last dd and buttons and their handles
            delete(app.TableDropDowns(end))
            app.TableDropDowns(end) = [];
            delete(app.SubtractButtons(end))
            app.SubtractButtons(end) = [];
            delete(app.AddButtons(end))
            app.AddButtons(end) = [];
        end
        
        function populateOverrideDropdownsTT(app)
            ind = find(~strcmp({app.TableDropDowns(1:app.NumInputTables).Value},app.SelectVariable));
            items = {app.TableDropDowns(ind).Value};
            numVarsPerTable = cellfun(@width,{app.TableDropDowns(ind).WorkspaceValue});
            
            % set first dd to full list
            app.OverrideDropdownsTT(1).Items = items;
            
            % check to see if we need fewer items in the rest
            for k = 2:app.NumOverrides
                for jj = 1:numel(ind)
                    numTimesTTAlreadyChosen = nnz(strcmp({app.OverrideDropdownsTT(1:k-1).Value},app.TableDropDowns(ind(jj)).Value));
                    if numTimesTTAlreadyChosen >= numVarsPerTable(jj)
                        % we already selected all possible vars for this TT
                        items = setdiff(items,app.TableDropDowns(ind(jj)).Value,'stable');
                    end
                end
                app.OverrideDropdownsTT(k).Items = items;
            end
        end
    
        function updateInputSection(app,hasInput)
            % hide subtract buttons if we have the minimum number of inputs
            showSubtractButtons = app.NumInputTables > 2;
            [app.SubtractButtons.Visible] = deal(showSubtractButtons);
            % add buttons are always visible (no max) but disable if we
            % don't have at least 2 inputs to start
            [app.AddButtons.Enable] = deal(hasInput);
            % subtract buttons will always be enabled
            
            % if can't subtract, then scoot add buttons over
            app.AddButtons(1).Layout.Column = 3 + (showSubtractButtons);
            app.AddButtons(2).Layout.Column = 3 + (showSubtractButtons);
            
            app.InputGrid.RowHeight = repmat({app.TextRowHeight},1,app.NumInputTables);
        end
    end
    
    methods (Access = protected)
        function [code,outputs,overwriteInput] = generateScriptSetupAndInputs(app,overwriteInput) 
            % get input names, remove 'select' dds and add `` so the
            % generated script will know not to change the name in editor
            inputs = {app.TableDropDowns(1:app.NumInputTables).Value};
            inputs = setdiff(inputs,app.SelectVariable,'stable');
            inputsWithTicks = inputs;
            if isequal(app.Workspace,'base')
                inputsWithTicks = strcat('`',inputsWithTicks,'`');
            end
            
            % start with the global synchronize command
            code = ['% ' getLocalMsg(app,'Synchronizetimetables') newline];

            hasOverrides = app.NumOverrides > 0;
            if overwriteInput
                % overwrite the leftmost table
                outputs = inputsWithTicks(1);
                if hasOverrides
                    % use the tempTT as the input so it is safe to
                    % write the output onto the input and still have the
                    % temp input available to do overrides
                    code = [code 'tempTT = ' inputsWithTicks{1} ';' newline];
                    inputsWithTicks{1} = 'tempTT';
                end
            else
                outputs = {'newTimetable'};
            end
            code = [code outputs{1} ' = synchronize('];
            
            % add inputs
            for k = 1:numel(inputs)
                code = matlab.internal.dataui.addCharToCode(code,[inputsWithTicks{k} app.InputIndexingCode{k} ',']);
            end
        end

        function code = generateOverrideScript(app,code,outputs,doClear,overwriteInput)
            code = [code ';' newline newline];
            code = [code '% ' getLocalMsg(app,'CommentOverrides') newline];

            % sort and keep permutation so we can sort the others too
            [overrideLocations,perm] = sort(app.OverrideLocations);

            % get cellstrs for code
            overrideTTs = {app.OverrideDropdownsTT.Value};
            if overwriteInput
                % swap out first tt for "tempTT" since the first tt has
                % already been overwritten at this point
                overrideTTs{strcmp(overrideTTs,app.TableDropDowns(1).Value)} = 'tempTT';
            elseif isequal(app.Workspace,'base')
                overrideTTs = strcat('`',overrideTTs,'`');
            end
            overrideTTs = overrideTTs(perm);
            overrideVars = {app.OverrideDropdownsVar.Value};
            overrideVars = overrideVars(perm);
            overrideMethods = {app.OverrideDropdownsMethods.Value};
            overrideMethods = overrideMethods(perm);
            overrideNames = app.DedupedOverrideNames(perm);

            if app.NumOverrides == 1
                % special case, no for loop needed
                % add retime call
                code = [code 'TT = retime(' overrideTTs{1} '(:,' matlab.internal.dataui.cleanVarName(overrideVars{1}) '),'];
                code = matlab.internal.dataui.addCharToCode(code,[outputs{1} '.Properties.RowTimes,']);
                code = matlab.internal.dataui.addCharToCode(code,['"' overrideMethods{1} '");']);
                % add new variable to the output
                code = [code newline outputs{1} ' = addvars(' outputs{1} ','];
                code = matlab.internal.dataui.addCharToCode(code,'TT.(1),');
                % note: in addvars chars are read as parameter names and
                % strings are read as variable names, therefore addvars
                % does not support Name=Value syntax
                code = matlab.internal.dataui.addCharToCode(code,['''Before'',' num2str(overrideLocations(1)) ',']);
                code = matlab.internal.dataui.addCharToCode(code,['''NewVariableNames'',' matlab.internal.dataui.cleanVarName(overrideNames{1}) ');']);
                if doClear
                    % clear temp variable
                    code = [code newline 'clear TT'];
                end
            else
                % add cell array of timetables to code
                code = [code 'temp.TTs = '];
                code = matlab.internal.dataui.addCharToCode(code,['{' overrideTTs{1} ',']);
                for idx = 2:app.NumOverrides
                    % add timetable values into cell array
                    code = matlab.internal.dataui.addCharToCode(code,[overrideTTs{idx} ',']);
                end
                % remove final comma and close cell array
                code = [code(1:end-1) '}'];

                % add cellstrs to code
                code = [code ';' newline 'temp.Vars = '];
                code = matlab.internal.dataui.addCellStrToCode(code,overrideVars);
                code = [code ';' newline 'temp.Methods = '];
                code = matlab.internal.dataui.addCellStrToCode(code,overrideMethods);
                code = [code ';' newline 'temp.Locations = '];
                code = [code mat2str(overrideLocations)];
                if ~isequal(overrideNames,overrideVars)
                    code = [code ';' newline 'temp.Names = '];
                    code = matlab.internal.dataui.addCellStrToCode(code,overrideNames);
                end
                code = [code ';' newline];

                % start for loop
                code = [code 'for k = 1:' num2str(app.NumOverrides) newline '    '];

                % add retime call
                code = [code 'TT = retime(temp.TTs{k}(:,temp.Vars(k)),'];
                code = matlab.internal.dataui.addCharToCode(code,[outputs{1} '.Properties.RowTimes,'],true);
                code = matlab.internal.dataui.addCharToCode(code,'temp.Methods(k));',true);

                % add this new variable to the output
                code = [code newline '    ' outputs{1} ' = addvars(' outputs{1} ','];
                code = matlab.internal.dataui.addCharToCode(code,'TT.(1),',true);
                code = matlab.internal.dataui.addCharToCode(code,'''Before'',temp.Locations(k),',true);
                if ~isequal(overrideNames,overrideVars)
                    code = matlab.internal.dataui.addCharToCode(code,'''NewVariableNames'',temp.Names(k));',true);
                else
                    code = matlab.internal.dataui.addCharToCode(code,'''NewVariableNames'',temp.Vars(k));',true);
                end

                % end for loop
                code = [code newline 'end' newline];

                if doClear
                    % clear temporary variables
                    code = [code 'clear temp k TT'];
                end
            end
        end
    end

    methods(Access = public)
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
            % Inputs - the names of the input timetables
            % TableVariableNames - table variables currently selected in app - not used
            % Code - keyword used in editor to select task

            if ~isequal(NVpairs.Code,"")
                updateDefaultsFromKeyword(app,NVpairs.Code);
            end

            if ~isempty(NVpairs.Inputs)
                [app.TableDropDowns.Value] = deal(app.SelectVariable);
                for k = 1 : numel(NVpairs.Inputs)
                    if app.NumInputTables < k
                        app.NumInputTables = app.NumInputTables + 1;
                        createInputRow(app,app.NumInputTables)
                        app.IsSortedTimes(app.NumInputTables) = true;
                    end
                    app.TableDropDowns(k).populateVariables();
                    if ismember(NVpairs.Inputs(k),app.TableDropDowns(k).ItemsData)
                        app.TableDropDowns(k).Value = NVpairs.Inputs(k);
                    end
                end
                doUpdate(app,app.TableDropDowns(1),[]);
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputData(app)
                summary = getString(message('MATLAB:tableui:Tool_timetableSynchronizer_Description'));
            else
                method = getMethodForSummary(app);
                ind = ~strcmp({app.TableDropDowns.Value},app.SelectVariable);
                if nnz(ind) <= 5
                    tableNames = strcat('`',{app.TableDropDowns(ind).Value},'`');
                    firstNminusOneTables = strcat(tableNames(1:end-1), {', '});
                    firstNminusOneTables = [firstNminusOneTables{:}];
                    summary = getLocalMsg(app,'Summary2',firstNminusOneTables(1:end-2),tableNames{end},method);
                else
                    summary = getLocalMsg(app,'Summary3',method);
                end
            end
            summary = string(summary);
        end
    end
end
