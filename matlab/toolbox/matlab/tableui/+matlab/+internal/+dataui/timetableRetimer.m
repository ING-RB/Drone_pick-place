classdef (Hidden = true,Sealed = true) timetableRetimer < ...
        matlab.internal.dataui.retimeSynchEmbedder
    % Retime Timetable live editor task
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Constant, Transient, Hidden)
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2020a)
        %       2: Add versioning (R2020b)
        %       3: Accordions, Merge method dropdowns (R2021a)
        %       4: Use Base Class and add dedupe method (R2022a)
        %       5: Update new time method based on keyword (R2024a)
        %       6: Use FunctionSelector for custom aggregation function (R2024b) 
        Version double = 6;
    end

    properties
        Summary
    end
    
    methods (Access = protected)
        function createInputDataSection(app)
            h = createNewSection(app,getCommonMsg(app,'DataDelimiter'),...
                {'fit',app.DropDownWidth},1);
            
            % Layout
            uilabel(h,'Text',getLocalMsg(app,'Inputtimetable'));
            app.TableDropDowns = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h,...
                'Tag','Input change','ValueChangedFcn',@app.doUpdate,'ShowNonExistentVariable',true);
            app.TableDropDowns.FilterVariablesFcn = @app.filterInputTable;
            app.NumInputTables = 1;
        end
        
        function isSupported = filterInputTable(app,t)
            % reset app if a variable has been cleared
            if checkForClearedVariables(app)
                doUpdate(app);
            end
            
            % Support all non-empty timetables
            isSupported = istimetable(t) && ~isempty(t);
        end
        
        function setOverrideGridColumnWidth(app)
            app.OverrideGrid.ColumnWidth = {app.DropDownWidth ...
                app.DropDownWidth app.IconColumnWidth app.IconColumnWidth};
        end
        
        function name = inputDataName(app)
            name = getLocalMsg(app,'Inputtimetable');
        end
        
        function resetOverrides(app)
            if ~isempty(app.OverrideDropdownsVar)
                delete(app.OverrideDropdownsVar(1:end));
                app.OverrideDropdownsVar(1:end) = [];
                delete(app.OverrideDropdownsMethods(1:end));
                app.OverrideDropdownsMethods(1:end) = [];
                delete(app.OverrideSubtractButtons(1:end));
                app.OverrideSubtractButtons(1:end) = [];
                delete(app.OverrideAddButtons(1:end));
                app.OverrideAddButtons(1:end) = [];
            end
            app.NumOverrides = 0;
            updateOverrideLocations(app);
        end
        
        function populateOverrideDropdownsVar(app)
            allVarNames = app.TableDropDowns.WorkspaceValue.Properties.VariableNames;
            
            for k = 1:app.NumOverrides
                % get full list of options
                varNames = allVarNames;
                % get current value to see if it changes
                val = app.OverrideDropdownsVar(k).Value;
                
                % take out any previously chosen variables
                prevVarNames = {app.OverrideDropdownsVar(1:k-1).Value};
                varNames = setdiff(varNames,prevVarNames,'stable');
                
                % set the items to what is left
                app.OverrideDropdownsVar(k).Items = varNames;
                
                if ~isequal(val,app.OverrideDropdownsVar(k).Value)
                    % value changed, so populate the method dd too
                    populateOverrideDropdownsMethod(app,k);
                end
            end
        end
        
        function neededOverride = localAutoPopulateOverrides(app,filterFcn,checkOnly)
            % If checkOnly, then we won't actually populate, just check to
            % see if we would need exceptions with the currently selected
            % general method
            neededOverride = false;
            TT = app.TableDropDowns.WorkspaceValue;
            for k = 1:width(TT)
                if ~filterFcn(TT{1,k})
                    neededOverride = true;
                    if checkOnly
                        % stop now before we actually populate anything
                        return
                    end
                    varName = TT.Properties.VariableNames{k};
                    % check to see if it is already an override
                    isOverride = app.NumOverrides > 0 &&...
                        any(strcmp({app.OverrideDropdownsVar.Value},varName));
                    if ~isOverride
                        % add a new override row and set the value
                        app.addOverrideRow([],[],true);
                        populateOverrideDropdownsVar(app);
                        app.OverrideDropdownsVar(app.NumOverrides).Value = varName;
                        populateOverrideDropdownsMethod(app,app.NumOverrides)
                        app.OverrideDropdownsMethods(app.NumOverrides).Value = app.OverrideDropdownsMethods(app.NumOverrides).ItemsData{1};
                    end
                end
            end
        end

        function updateOverrideLocations(app)
            locs = [];
            if app.NumOverrides > 0
                overrideVars = {app.OverrideDropdownsVar.Value};
                allVars = app.TableDropDowns.WorkspaceValue.Properties.VariableNames;
                [~,locs] = ismember(overrideVars,allVars);
            end
            app.OverrideLocations = locs;
        end
        
        function hasInput = hasInputData(app)
            hasInput = ~strcmp(app.TableDropDowns.Value,app.SelectVariable);
        end

        function setAutoRun(app)
            % If data is too large, turn auto-run off.
            % Once triggered, user is in control, so no need to reset to
            % true for small data
            if hasInputData(app) && numel(app.TableDropDowns.WorkspaceValue) > app.AutoRunCutOff
                app.AutoRun = false;
            end
        end
    end
    
    methods (Access = protected)
        function [code,outputs,input] = generateScriptSetupAndInputs(app,overwriteInput)
            
            % start with the global retime command
            code = ['% ' getLocalMsg(app,'Retimetimetables') newline];
            
            % define input/output name
            hasOverrides = app.NumOverrides > 0;
            input = app.TableDropDowns.Value;
            if isequal(app.Workspace,'base')
                % add ticks for live editor workflow, but not app workflow
                input = ['`' input '`'];
            end
            
            if overwriteInput
                outputs = {input};
                if hasOverrides
                    % need to copy input table to a temp table
                    code = [code 'tempTT = ' input ';' newline];
                    % now use the tempTT as the input so it is safe to
                    % write the output onto the input and still have the
                    % temp input available to do overrides
                    input = 'tempTT';
                end
            else
                outputs = {'newTimetable'};
            end
            
            code = [code outputs{1} ' = retime('];
            
            % add inputs            
            code = matlab.internal.dataui.addCharToCode(code,input);
            if hasOverrides
                % keep only the indices of the non-overrides for the
                % initial input
                indNonOverrideVars = setdiff(1:numel(app.OverrideDropdownsVar(1).Items),app.OverrideLocations);
                code = [code '(:,' mat2str(indNonOverrideVars) ')'];
            end
            code = [code ','];
        end

        function code = generateOverrideScript(app,code,outputs,doClear,input)
            code = [code ';' newline newline];
            code = [code '% ' getLocalMsg(app,'CommentOverrides') newline];

            % sort override locations to be used in script
            [overrideLocations,perm] = sort(app.OverrideLocations);

            % get cellstrs for code and permute them to match locations
            overrideVars = {app.OverrideDropdownsVar.Value};
            overrideVars = overrideVars(perm);
            overrideMethods = {app.OverrideDropdownsMethods.Value};
            overrideMethods = overrideMethods(perm);

            if app.NumOverrides == 1
                % special case, no for loop needed
                % add retime call
                code = [code 'TT = retime(' input '(:,' matlab.internal.dataui.cleanVarName(overrideVars{1}) '),'];
                code = matlab.internal.dataui.addCharToCode(code,[outputs{1} '.Properties.RowTimes,']);
                code = matlab.internal.dataui.addCharToCode(code,['"' overrideMethods{1} '");']);
                % add new variable to the output
                code = [code newline outputs{1} ' = addvars(' outputs{1} ','];
                code = matlab.internal.dataui.addCharToCode(code,'TT.(1),');
                % note: in addvars chars are read as parameter names and
                % strings are read as variable names, therefore addvars
                % does not support Name=Value syntax
                code = matlab.internal.dataui.addCharToCode(code,['''Before'',' num2str(overrideLocations(1)) ',']);
                code = matlab.internal.dataui.addCharToCode(code,['''NewVariableNames'',' matlab.internal.dataui.cleanVarName(overrideVars{1}) ');']);
                % clear temp variable (unless app does it for us)
                if doClear
                    code = [code newline 'clear TT'];
                end
            else
                % add cellstrs to code
                code = [code 'temp.Vars = '];
                code = matlab.internal.dataui.addCellStrToCode(code,overrideVars);
                code = [code ';' newline 'temp.Methods = '];
                code = matlab.internal.dataui.addCellStrToCode(code,overrideMethods);
                code = [code ';' newline 'temp.Locations = '];
                code = [code mat2str(overrideLocations)];
                code = [code ';' newline];

                % start for loop
                code = [code 'for k = 1:' num2str(app.NumOverrides) newline '    '];

                % add retime call
                code = [code 'TT = retime(' input '(:,temp.Vars(k)),'];
                code = matlab.internal.dataui.addCharToCode(code,[outputs{1} '.Properties.RowTimes,'],true);
                code = matlab.internal.dataui.addCharToCode(code,'temp.Methods(k));',true);

                % add this new variable to the output
                code = [code newline '    ' outputs{1} ' = addvars(' outputs{1} ','];
                code = matlab.internal.dataui.addCharToCode(code,'TT.(1),',true);
                code = matlab.internal.dataui.addCharToCode(code,'''Before'',temp.Locations(k),',true);
                code = matlab.internal.dataui.addCharToCode(code,'''NewVariableNames'',temp.Vars(k));',true);

                % end for loop
                code = [code newline 'end' newline];

                % clear temporary variables (unless app does it for us)
                if doClear
                    code = [code 'clear temp k TT'];
                end
            end
        end
    end

    methods (Access = public)
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
            % TableVariableNames - table variables currently selected in app - not used
            % Code - keyword used in editor to select task

            if ~isequal(NVpairs.Code,"")
                updateDefaultsFromKeyword(app,NVpairs.Code);
            end

            if ~isempty(NVpairs.Inputs)
                app.TableDropDowns.populateVariables();
                if ismember(NVpairs.Inputs(1),app.TableDropDowns.ItemsData)
                    app.TableDropDowns.Value = NVpairs.Inputs(1);
                    doUpdate(app,app.TableDropDowns,[]);
                end
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputData(app)
                summary = getString(message('MATLAB:tableui:Tool_timetableRetimer_Description'));
            else
                method = getMethodForSummary(app);
                summary = getLocalMsg(app,'Summary1',['`' app.TableDropDowns.Value '`'],method);
            end
            summary = string(summary);
        end
    end
end