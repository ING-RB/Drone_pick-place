classdef (Hidden = true,Sealed = true) tableUnstacker < ...
        matlab.internal.dataui.stackUnstackEmbedder
    % Table Unstacker live task for unstacking table variables in a Live Script
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = public, Hidden)
        IndicatorButtonGroup                matlab.ui.container.ButtonGroup
        DataButtonGroup                     matlab.ui.container.ButtonGroup
        GroupingDropdowns                   matlab.ui.control.DropDown
        AggFcnDropDown                      matlab.ui.control.DropDown
        CustomAggFcnSelector                matlab.internal.dataui.FunctionSelector
        VarType                             char
        InputIsTimetable                    logical
        HasTooManyElements                  logical
    end
    
    properties (Constant, Transient, Hidden)
        OutputName          char = 'unstackedTable';
        TimeColumnWidth     double = 165;
        ElementLimit        double = 1000;
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2020a)
        %       2: Add versioning (R2020b)
        %       3: Use Base Class (R2022a)
        %       4: Use FunctionSelector for custom aggregation function (R2024a)
        Version double = 4;
    end

    properties
        State
        Summary
    end
    
    methods (Access = protected)
        % Methods required by inherited class
        function createTableSection(app)
            % panel row
            app.NumTableVars = 3;
            S = createNewSection(app,getMsgText(app,'UnstackRowDelimiter'),{'fit'},2);
            
            app.PreviewGrid = uigridlayout(S,[4 2],...
                'RowHeight',{app.TextRowHeight app.TextRowHeight app.TableRowHeight app.TextRowHeight},...
                'ColumnSpacing',0,'RowSpacing',0,'Padding',0);
                        
            uilabel(app.PreviewGrid,'Text',getMsgText(app,'Indicator'));
            app.IndicatorButtonGroup = uibuttongroup(app.PreviewGrid,...
                'SelectionChangedFcn',@app.doUpdate,'Tag','IndicatorChange',...
                'AutoResizeChildren','off');
            uilabel(app.PreviewGrid,'Text',getMsgText(app,'Datatounstack'));
            app.DataButtonGroup = uibuttongroup(app.PreviewGrid,...
                'SelectionChangedFcn',@app.doUpdate,'Tag','DataChange',...
                'Tooltip',getMsgText(app,'DatatounstackTooltip'),...
                'AutoResizeChildren','off');
            if ~isAppWorkflow(app)
                % don't create preview table if in data cleaner app
                app.PreviewTable = uitable(app.PreviewGrid);
            end
            app.GroupingDropdowns = uidropdown(app.PreviewGrid);
            
            % agg row
            h = uigridlayout(S,'Padding',0,'RowHeight',{app.TextRowHeight},'ColumnWidth',{'fit' 'fit' 'fit'});
            
            uilabel(h,'Text',getMsgText(app,'Aggregationfunction'));
            app.AggFcnDropDown = uidropdown(h);
            app.AggFcnDropDown.ValueChangedFcn = @app.doUpdate;

            app.CustomAggFcnSelector = matlab.internal.dataui.FunctionSelector(h);
            app.CustomAggFcnSelector.ValueChangedFcn = @app.doUpdate;
            app.CustomAggFcnSelector.Tooltip = getMsgText(app,'CustomAggFcnTooltip');
            app.CustomAggFcnSelector.NewFcnName = 'customAggregator';
            app.CustomAggFcnSelector.NewFcnText = [newline ...
            'function y = customAggregator(x)' newline ...
            '% ' getString(message('MATLAB:tableui:pivotCustomFunctionCodeComment1','x')) newline ...
            '% ' char(getMsgText(app,'NewFcnTxtComment1',false,'y','x')) newline ...
            '% ' char(getMsgText(app,'NewFcnTxtComment2')) newline ...
            newline ...
            'if isempty(x)' newline ...
            '    % ' char(getMsgText(app,'NewFcnTxtComment3')) newline ...
            '    x = [x; missing];' newline ...
            'end' newline ...
            'y = x(end);' newline ...
            'end' newline];
        end
        
        function setWidgetsToDefault(app)
            resetPreviewGrid(app);
            setIndicatorAndDataDefault(app);
            setGroupingDropdownsToDefault(app);
            populateAggregationFunction(app);
            if ismember('@sum', app.AggFcnDropDown.ItemsData)
                app.AggFcnDropDown.Value = '@sum';
            elseif ismember('@(x)x(~isempty(x))', app.AggFcnDropDown.ItemsData)
                % use 'first'
                app.AggFcnDropDown.Value = '@(x)x(~isempty(x))';
            else
                app.AggFcnDropDown.Value = app.AggFcnDropDown.ItemsData{1};
            end

            if isAppWorkflow(app)
                app.CustomAggFcnSelector.FcnType = 'handle';
            else
                app.CustomAggFcnSelector.FcnType = 'local';
            end
            app.CustomAggFcnSelector.HandleValue = '@unique';
            app.CustomAggFcnSelector.LocalValue = 'select variable';

            app.OutputTableCheckbox.Value = ~isAppWorkflow(app);
            app.InputTableCheckbox.Value = false;
        end
        
        function doUpdate(app,src,evt)
            if nargin > 1
                % this comes from a callback to a widget
                checkForClearedVariables(app);
            end
            hasInput = hasInputData(app);
            if hasInput && nargin > 1
                if isequal(src.Tag,'DataChange')
                    % the data could have changed datatype
                    populateAggregationFunction(app);
                    repopulateGroupingDropdown(app,evt.OldValue.UserData)
                elseif isequal(src.Tag,'IndicatorChange')
                    repopulateGroupingDropdown(app,evt.OldValue.UserData);
                    ind = app.IndicatorButtonGroup.SelectedObject.UserData;
                    if ind == app.DataButtonGroup.SelectedObject.UserData
                        % move the dataVar to the next one
                        if ind == app.NumTableVars
                            app.DataButtonGroup.SelectedObject = app.DataButtonGroup.Buttons(1);
                        else
                            app.DataButtonGroup.SelectedObject = app.DataButtonGroup.Buttons(ind+1);
                        end
                        % the data could have changed datatype
                        populateAggregationFunction(app);
                        repopulateGroupingDropdown(app,app.DataButtonGroup.SelectedObject.UserData);
                    end
                end
            end
            
            [app.IndicatorButtonGroup.Buttons.Enable] = deal(hasInput);
            [app.IndicatorButtonGroup.Buttons(app.HasTooManyElements).Enable] = deal(false);
            hasIndicator = ~all(app.HasTooManyElements);
            if hasIndicator
                [app.IndicatorButtonGroup.Buttons(~app.HasTooManyElements).Tooltip] = deal(getMsgText(app,'IndicatorTooltip'));
                [app.IndicatorButtonGroup.Buttons(app.HasTooManyElements).Tooltip] = deal(getMsgText(app,'IndicatorTooltip2'));
            else
                [app.IndicatorButtonGroup.Buttons.Tooltip] = deal(getMsgText(app,'IndicatorTooltip3'));
            end
            
            
            [app.DataButtonGroup.Buttons.Enable] = deal(hasInput && hasIndicator);
            % indicator var can't also be the data var
            app.DataButtonGroup.Buttons(app.IndicatorButtonGroup.SelectedObject.UserData).Enable = 'off';

            if ~isAppWorkflow(app)
                drawnow;
                if hasInput && hasIndicator
                    app.PreviewTable.Enable = 'on';
                else
                    app.PreviewTable.Enable = 'off';
                end
            end
            [app.GroupingDropdowns.Enable] = deal(hasInput && hasIndicator);

            % disable dd for indicator var and data var, and show blank dd
            indButton = app.IndicatorButtonGroup.SelectedObject.UserData;
            dataButton = app.DataButtonGroup.SelectedObject.UserData;
            app.GroupingDropdowns(indButton).Enable = 'off';
            app.GroupingDropdowns(dataButton).Enable = 'off';
            app.GroupingDropdowns(indButton).Items = {};
            app.GroupingDropdowns(dataButton).Items = {};
            
            % set tooltips for dds based on current value
            app.GroupingDropdowns(indButton).Tooltip = '';
            app.GroupingDropdowns(dataButton).Tooltip = '';
            [app.GroupingDropdowns(strcmp({app.GroupingDropdowns.Value},'groupby')).Tooltip] = deal(getMsgText(app,'GroupTooltip'));
            [app.GroupingDropdowns(strcmp({app.GroupingDropdowns.Value},'constant')).Tooltip] = deal(getMsgText(app,'KeepconstantTooltip'));
            [app.GroupingDropdowns(strcmp({app.GroupingDropdowns.Value},'discard')).Tooltip] = deal(getMsgText(app,'DiscardTooltip'));

            app.CustomAggFcnSelector.Visible = isequal(app.AggFcnDropDown.Value,'custom');
            app.AggFcnDropDown.Enable = hasInput && hasIndicator;
            app.CustomAggFcnSelector.Enable = hasInput && hasIndicator;
            
            updateVisualizationSection(app);
            app.OutputTableCheckbox.Enable = hasInput && hasIndicator;
            app.InputTableCheckbox.Enable = hasInput && hasIndicator;
            
            notify(app,'StateChanged');
        end

        function resetPreviewGrid(app,isFromSetState)
            if nargin < 2
                isFromSetState = false;
            end
            if ~isFromSetState
                app.InputIsTimetable = hasInputData(app) && istimetable(app.TableDropDown.WorkspaceValue);
            end 
            
            % clear out existing buttons
            if ~isempty(app.IndicatorButtonGroup.Children)
                delete(app.IndicatorButtonGroup.Children);
                delete(app.DataButtonGroup.Children);
            end
            if ~isempty(app.GroupingDropdowns)
                delete(app.GroupingDropdowns);
                app.GroupingDropdowns(1:end) = [];
            end
            % make sure additional columns are empty so that setting
            % columnWidth works properly
            app.IndicatorButtonGroup.Layout.Column = 2;
            app.DataButtonGroup.Layout.Column = 2;
            resetCommonPreviewGridProperties(app,isFromSetState);
            
            % recreate Buttons/DDs
            app.IndicatorButtonGroup.Layout.Column = [2 app.NumTableVars+1];
            app.DataButtonGroup.Layout.Column = [2 app.NumTableVars+1];
            for k = 1 : app.NumTableVars
                pos = [app.TableColumnWidth*(k-0.5) 0 app.TextRowHeight app.TextRowHeight];
                uiradiobutton(app.IndicatorButtonGroup,'Position',pos,...
                    'Text','','UserData',k);
                uiradiobutton(app.DataButtonGroup,'Position',pos,...
                    'Text','','UserData',k);
                
                app.GroupingDropdowns(k) = uidropdown(app.PreviewGrid, ...
                    'Items',[getMsgText(app,'Groupby') getMsgText(app,'Keepconstant') getMsgText(app,'Discard')],...
                    'ItemsData',{'groupby' 'constant' 'discard'},...
                    'ValueChangedFcn',@app.doUpdate);
                app.GroupingDropdowns(k).Layout.Row = 4;
                app.GroupingDropdowns(k).Layout.Column = k+1;
            end
            if app.InputHasRowLabels
                app.GroupingDropdowns(app.NumTableVars + 1) = uidropdown(app.PreviewGrid, ...
                    'Items',[getMsgText(app,'Groupby') getMsgText(app,'Keepconstant')],...
                    'ItemsData',{'groupby' 'constant'},...
                    'ValueChangedFcn',@app.doUpdate);
                app.GroupingDropdowns(app.NumTableVars + 1).Layout.Row = 4;
                app.GroupingDropdowns(app.NumTableVars + 1).Layout.Column = 1;
            end
            resetTableFromInputData(app);
        end

        function localInitializeVariables(~,~)
            % unstack ignores input table variables because it is unclear
            % what they would be for (indicator? data? groupby?)
        end

        function workspaceChangedFcn(app)
            if ~isequal(app.Workspace,'base')
                % Local functions not supported
                app.CustomAggFcnSelector.FcnType = 'handle';
                % Update default value to one that usually won't throw error
                app.CustomAggFcnSelector.HandleValue = '@unique';
            end
        end
    end
    
    methods (Access = private)
        % Internal app methods
        function setIndicatorAndDataDefault(app)
            % set indicator smartly
            if hasInputData(app)
                T = app.TableDropDown.WorkspaceValue;
                % Restrict default to only variables with few enough unique elements
                numUniqueElements = varfun(@(x) numel(unique(x)),T,'OutputFormat','uniform');
                app.HasTooManyElements = numUniqueElements > app.ElementLimit;
                % First look through the categoricals
                cats = varfun(@iscategorical,T,'OutputFormat','uniform');
                cats = cats & (~app.HasTooManyElements);
                if any(cats)
                    % Ensure we will pick one of the cats
                    numUniqueElements(~cats) = inf;
                end
                % Pick the var with least num unique elements
                [~,ind] = min(numUniqueElements);
            else
                ind = 1;
                app.HasTooManyElements = false(1,3);
            end
            app.IndicatorButtonGroup.SelectedObject = app.IndicatorButtonGroup.Buttons(ind);
            
            if ind == app.NumTableVars
                app.DataButtonGroup.SelectedObject = app.DataButtonGroup.Buttons(1);
            else
                app.DataButtonGroup.SelectedObject = app.DataButtonGroup.Buttons(ind+1);
            end
        end
        
        function setGroupingDropdownsToDefault(app)
            if app.InputIsTimetable && isAppWorkflow(app)
                % no discard in app, so match as close as we can
                [app.GroupingDropdowns(1:app.NumTableVars).Value] = deal('constant');
                app.GroupingDropdowns(app.NumTableVars+1).Value = 'groupby';
            elseif app.InputIsTimetable
                [app.GroupingDropdowns(1:app.NumTableVars).Value] = deal('discard');
                app.GroupingDropdowns(app.NumTableVars+1).Value = 'groupby';
            else
                [app.GroupingDropdowns(1:app.NumTableVars).Value] = deal('groupby');
                if app.InputHasRowLabels
                    app.GroupingDropdowns(app.NumTableVars+1).Value = 'constant';
                end
            end
        end

        function repopulateGroupingDropdown(app,k)
            % reset items that were emptied
            app.GroupingDropdowns(k).Items = [getMsgText(app,'Groupby') ...
                getMsgText(app,'Keepconstant') getMsgText(app,'Discard')];
            if app.InputIsTimetable
                % reset to default
                if isAppWorkflow(app)
                    app.GroupingDropdowns(k).Value = 'constant';
                else
                    app.GroupingDropdowns(k).Value ='discard';
                end
                % note, if not timetable, default is already correctly set by items{1}
            end
        end
        
        function populateAggregationFunction(app)
            T = app.TableDropDown.WorkspaceValue;
            if ~isempty(T)
                var = T{1,app.DataButtonGroup.SelectedObject.UserData};
            else
                var = 0;
            end
            app.VarType = class(var);
            if isnumeric(var)
                app.VarType = 'numeric';
            elseif iscellstr(var)
                app.VarType = 'cellstr';
            end
            
            % here is the full list - for numeric only
            app.AggFcnDropDown.Items = [getMsgText(app,'AggSum') getMsgText(app,'AggMean') ...
                getMsgText(app,'AggMedian') getMsgText(app,'AggMode') getMsgText(app,'AggMax') getMsgText(app,'AggMin')...
                 getMsgText(app,'AggFirst') getMsgText(app,'AggUnique') getMsgText(app,'AggCount') getMsgText(app,'AggCustom')];
            app.AggFcnDropDown.ItemsData = {'@sum' '@mean' '@median' '@mode' '@max' '@min' '@(x)x(~isempty(x))' '@unique' '@(x)size(x,1)' 'custom'};
            % remove items based on datatype
            % note, it is important to set ItemsData first so a users
            % choice does not get overwritten
            if isduration(var)
                % remove count
                app.AggFcnDropDown.ItemsData(9) = [];
                app.AggFcnDropDown.Items(9) = [];
            elseif islogical(var)
                % remove mean and count
                app.AggFcnDropDown.ItemsData([2 9]) = [];
                app.AggFcnDropDown.Items([2 9]) = [];
            elseif isdatetime(var)
                % remove sum and count
                app.AggFcnDropDown.ItemsData([1 9]) = [];
                app.AggFcnDropDown.Items([1 9]) = [];
            elseif iscategorical(var) && isordinal(var)
                % remove sum, mean, and count
                app.AggFcnDropDown.ItemsData([1 2 9]) = [];
                app.AggFcnDropDown.Items([1 2 9]) = [];
            elseif iscategorical(var)
                % leave only mode, unique, first, and custom
                app.AggFcnDropDown.ItemsData([1 2 3 5 6 9]) = [];
                app.AggFcnDropDown.Items([1 2 3 5 6 9]) = [];
            elseif iscellstr(var) || isstring(var) || iscalendarduration(var)
                % leave only unique, first, and custom
                app.AggFcnDropDown.ItemsData([1:6 9]) = [];
                app.AggFcnDropDown.Items([1:6 9]) = [];
            elseif ~isnumeric(var)
                % leave only custom
                app.AggFcnDropDown.ItemsData(1:9) = [];
                app.AggFcnDropDown.Items(1:9) = [];
            end
        end
        
        function aggFcn = generateAggregationFunction(app)
            aggFcn = app.AggFcnDropDown.Value;
            % mean, median, and mode return missing for empties, so no
            % special case needed
            
            switch app.AggFcnDropDown.Value
                case '@sum'
                    if strcmp(app.VarType,'numeric')||strcmp(app.VarType,'logical')
                        % this is default, so don't need to generate
                        aggFcn = '';
                    end
                case 'custom'
                    aggFcn = app.CustomAggFcnSelector.Value;
            end
        end
    end
        
    methods (Access = public)
        % Required for embedding in the live editor
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
            code = '';
            outputs = {};
            if overwriteInput && ~isForExport
                % overwriting input is only supported for export script
                return
            end
            if ~hasInputData(app) || all(app.HasTooManyElements)
                return
            end

            if isequal(app.AggFcnDropDown.Value,'custom') && isempty(app.CustomAggFcnSelector.Value)
                code = ['disp("' char(getMsgText(app,'fcnSelectorDispMessage',true)) '")'];
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

            code = ['% ' char(getMsgText(app,'Unstackvariables')) newline];
            code = [code outputs{1} ' = unstack('];
            
            % S
            code = matlab.internal.dataui.addCharToCode(code,input);
            
            % var
            varname = app.TableVarNames{app.DataButtonGroup.SelectedObject.UserData};
            code = matlab.internal.dataui.addCharToCode(code, [',' matlab.internal.dataui.cleanVarName(varname)]);
            
            % ivar
            ivarname = app.TableVarNames{app.IndicatorButtonGroup.SelectedObject.UserData};
            code = matlab.internal.dataui.addCharToCode(code, [',' matlab.internal.dataui.cleanVarName(ivarname)]);
            
            % GroupingVariables
            groupingVars = app.TableVarNames(strcmp({app.GroupingDropdowns.Value},'groupby'));
            if app.InputIsTimetable
                defaultGroupingVars = app.TableVarNames(end);
            else
                defaultGroupingVars = setdiff(app.TableVarNames,{varname,ivarname},'stable');
                if app.InputHasRowLabels
                    defaultGroupingVars = setdiff(defaultGroupingVars,app.TableVarNames(end),'stable');
                end
            end
            if ~isequal(defaultGroupingVars,groupingVars)
                code = matlab.internal.dataui.addCharToCode(code,',GroupingVariables=');
                code = matlab.internal.dataui.addCellStrToCode(code,groupingVars);
            end
            
            % ConstantVariables
            constantVars = app.TableVarNames(strcmp({app.GroupingDropdowns.Value},'constant'));
            if app.InputIsTimetable
                defaultConstantVars = cell.empty(1,0);
            else
                defaultConstantVars = setdiff(app.TableVarNames,[defaultGroupingVars {varname,ivarname}],'stable');
            end
            if ~isequal(defaultConstantVars,constantVars)
                code = matlab.internal.dataui.addCharToCode(code,',ConstantVariables=');
                code = matlab.internal.dataui.addCellStrToCode(code,constantVars);
            end
            
            % AggregationFunction
            aggFcn = generateAggregationFunction(app);
            if ~isempty(aggFcn)
                code = matlab.internal.dataui.addCharToCode(code,[',AggregationFunction=' aggFcn]);
            end
            
            % VariableNamingRule (always set to 'preserve')
            code = matlab.internal.dataui.addCharToCode(code,',VariableNamingRule="preserve")');
            
            if app.InputTableCheckbox.Value || ~app.OutputTableCheckbox.Value
                code = [code ';'];
            end
        end

        function setTaskState(app,state,updatedWidget)
            % With nargin == 2, setState is used by live editor and App for
            % save/load, undo/redo
            % With nargin == 3, setState is used by the App to change the
            % value of a control from the property inspector
            
            if nargin < 3
                updatedWidget = '';
            end
            if ~isfield(state,'VersionSavedFrom')
                state.VersionSavedFrom = 1;
                state.MinCompatibleVersion = 1;
            end
            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version
                % do not set any properties
                doUpdate(app);
            else
                if ~isempty(updatedWidget)
                    % save current values to pass correct Tag and OldValue into doUpdate
                    src = struct('Tag','');
                    evt = struct();
                    if isequal(updatedWidget,'IndicatorDropdown')
                        src.Tag = 'IndicatorChange';
                        evt.OldValue.UserData = app.IndicatorButtonGroup.SelectedObject.UserData;
                    elseif isequal(updatedWidget,'DataDropdown')
                        src.Tag = 'DataChange';
                        evt.OldValue.UserData = app.DataButtonGroup.SelectedObject.UserData;
                    elseif isequal(updatedWidget,'CustomAggFcnSelector')
                        evt.PreviousValue = app.CustomAggFcnSelector.HandleValue;
                    end
                end

                setCommonStateProperties(app,state);
                if isfield(state,'AggFcnDropDownItems')
                    app.AggFcnDropDown.Items = state.AggFcnDropDownItems;
                    if isfield(state,'AggFcnDropDownItemsData')
                        app.AggFcnDropDown.ItemsData = state.AggFcnDropDownItemsData;
                    end
                    if isfield(state,'AggFcnDropDownValue')
                        app.AggFcnDropDown.Value = state.AggFcnDropDownValue;
                    end
                end
                for k = {'VarType' 'InputIsTimetable'}
                    if isfield(state,k{1})
                        app.(k{1}) = state.(k{1});
                    end
                end
                if isfield(state,'CustomAggFcnSelectorState')
                    if isequal(updatedWidget,'CustomAggFcnSelector')
                        app.CustomAggFcnSelector.HandleValue = state.AggFcnEditFieldValue;
                    else
                        app.CustomAggFcnSelector.State = state.CustomAggFcnSelectorState;
                    end
                elseif isfield(state,'AggFcnEditFieldValue')
                     % Comes from an older version
                     app.CustomAggFcnSelector.FcnType = 'handle';
                     app.CustomAggFcnSelector.HandleValue = state.AggFcnEditFieldValue;
                end
                    
                for k = {'Indicator' 'Data'}
                    if isequal(updatedWidget,[k{1} 'Dropdown']) && isfield(state,[k{1} 'Var'])
                        % comes from property inspector view in app
                        % need to map dropdown back to radiobutton index
                        ind = find(strcmp(app.TableVarNames,state.([k{1} 'Var'])));
                        app.([k{1} 'ButtonGroup']).SelectedObject = app.([k{1} 'ButtonGroup']).Buttons(ind);
                    elseif isfield(state,k{1})
                        app.([k{1} 'ButtonGroup']).SelectedObject = app.([k{1} 'ButtonGroup']).Buttons(state.(k{1}));
                    end
                end
                
                if isequal(updatedWidget,'GroupingMultiselectDropdown') && isfield(state,'GroupingVars')
                    % Comes from property inspector view in app: map
                    % MultiselectDropdown to GroupingDropdowns
                    [~,groupInd] = ismember(state.GroupingVars,app.TableVarNames);
                    [app.GroupingDropdowns(groupInd).Value] = deal('groupby');
                    [app.GroupingDropdowns(setdiff(1:numel(app.TableVarNames),groupInd)).Value] = deal('constant');
                elseif isfield(state,'GroupingDropdownsValues')
                    % we don't need to set empties as they are set in doUpdate
                    emptyVals = cellfun(@isempty,state.GroupingDropdownsValues);
                    [app.GroupingDropdowns(~emptyVals).Value] = deal(state.GroupingDropdownsValues{~emptyVals});
                end
                if isfield(state,'HasTooManyElements')
                    app.HasTooManyElements = state.HasTooManyElements;
                else
                    app.HasTooManyElements = false(1,numel(app.IndicatorButtonGroup.Buttons));
                end

                if isequal(updatedWidget,'CustomAggFcnSelector')
                    app.CustomAggFcnSelector.validateFcnHandle(app.CustomAggFcnSelector.HandleEditField,evt);
                    doUpdate(app,app.CustomAggFcnSelector,evt);
                elseif ~isempty(updatedWidget)
                    doUpdate(app,src,evt);
                else
                    doUpdate(app);
                end
            end
        end

        function propTable = getPropertyInformation(app)
            % propTable is a list of all the controls visible in the Data
            % Cleaner app along with everything needed to map the
            % uifigure into the property inspector

            % We rearrange this task as follows:
            % Input section: Input table dropdown
            % Input section: Indicator dropdown (maps to radiobutton)
            % Input section: Data dropdown (maps to radiobutton)
            % Grouping section: Grouping variable multiselect dropdown
            %     (maps to GroupingDropdowns, but no 'discard' option)
            % Grouping section: Aggregator dropdown
            % Grouping section: Custom function selector

            Name = ["TableDropDown";"IndicatorDropdown";"DataDropdown";...
                "GroupingMultiselectDropdown";"AggFcnDropDown";"CustomAggFcnSelector"];
            Group = [repmat(getMsgText(app,'DataDelimiter',true),3,1);...
                repmat(getMsgText(app,'MethodAndParametersDelimiter',true),3,1)];
            DisplayName = [getMsgText(app,'InputTable'); getMsgText(app,'Indicator'); getMsgText(app,'Datatounstack');...
                getMsgText(app,'Groupby'); getMsgText(app,'Aggregationfunction'); getMsgText(app,'AggCustom')];
            StateName = ["TableDropDownValue";"IndicatorVar";"DataVar";...
                "GroupingVars";"AggFcnDropDownValue";"AggFcnEditFieldValue"];
            Type = {'matlab.ui.control.internal.model.WorkspaceDropDown';
                'matlab.ui.control.DropDown'; 'matlab.ui.control.DropDown';
                'MultiselectDropDown';'matlab.ui.control.DropDown';'matlab.ui.control.EditField'};
            Tooltip = {''; app.IndicatorButtonGroup.SelectedObject.Tooltip; app.DataButtonGroup.Tooltip;
                char(getMsgText(app,'GroupTooltip')); app.AggFcnDropDown.Tooltip; ''};

            on = matlab.lang.OnOffSwitchState.on;
            app.TableDropDown.populateVariables();
            Visible = [numel(app.TableDropDown.Items) > 2; on; on; any([app.GroupingDropdowns.Enable]); on; app.CustomAggFcnSelector.Visible];
            Enable = [on; app.IndicatorButtonGroup.SelectedObject.Enable; app.DataButtonGroup.SelectedObject.Enable;...
                app.DataButtonGroup.SelectedObject.Enable; app.AggFcnDropDown.Enable; app.CustomAggFcnSelector.Enable];
            InitializeFlag = [1; 0; 0; 0; 0; 0];
            InSubgroup = false(6,1);
            GroupExpanded = true(6,1);
            SpinnerProperties = repmat({[]},6,1);

            % get Items/ItemsData
            varList = app.TableVarNames;
            if isempty(varList)
                % input hasn't been selected yet
                varList = {'Var1' 'Var2' 'Var3'};
            end
            indList = varList;
            dataList = varList;
            groupList = varList;
            indList(app.HasTooManyElements) = [];
            dataList(app.IndicatorButtonGroup.SelectedObject.UserData) = [];
            groupList([app.IndicatorButtonGroup.SelectedObject.UserData,app.DataButtonGroup.SelectedObject.UserData]) = [];
            if app.InputHasRowLabels
                % don't list time or row labels
                indList(end) = [];
                dataList(end) = [];
                % list Time first
                groupList = [groupList(end) groupList(1:end-1)];
            end
            % dataCleaner API expects Items for a multiselect dropdown to
            % start with the label of the multiselect dropdown (e.g.
            % 'select')
            groupList = [cellstr(DisplayName(4)) groupList];
            Items = {app.TableDropDown.Items; indList; dataList;...
                groupList; app.AggFcnDropDown.Items; {}};
            ItemsData = {app.TableDropDown.ItemsData; indList; dataList;...
                groupList; app.AggFcnDropDown.ItemsData; {}};

            propTable = table(Name,Group,DisplayName,StateName,Type,Tooltip,...
                Items,ItemsData,Visible,Enable,InitializeFlag,InSubgroup,GroupExpanded,SpinnerProperties);
        end

        function msg = getInspectorDisplayMsg(app)
            % used in data cleaner app only
            msg = '';
            if all(app.HasTooManyElements)
                msg = getMsgText(app,'IndicatorTooltip3');
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputData(app)
                summary = string(message('MATLAB:tableui:Tool_tableUnstacker_Description'));
            else
                summary = getMsgText(app,'UnstackSummary',false,...
                    ['`' app.TableVarNames{app.DataButtonGroup.SelectedObject.UserData} '`'],['`' app.TableDropDown.Value '`']);
            end
        end
                
        function state = get.State(app)
            state = struct('VersionSavedFrom',app.Version,...
                'MinCompatibleVersion',1,...
                'TableDropDownValue',app.TableDropDown.Value,...
                'OutputTableCheckboxValue',app.OutputTableCheckbox.Value,...
                'InputTableCheckboxValue',app.InputTableCheckbox.Value,...
                'AggFcnDropDownValue',app.AggFcnDropDown.Value,...
                'AggFcnDropDownItems',{app.AggFcnDropDown.Items},...
                'AggFcnDropDownItemsData',{app.AggFcnDropDown.ItemsData},...
                'AggFcnEditFieldValue',app.CustomAggFcnSelector.HandleValue,...
                'CustomAggFcnSelectorState',app.CustomAggFcnSelector.State,...
                'VarType',app.VarType,...
                'NumTableVars',app.NumTableVars,...
                'TableVarNames',{app.TableVarNames},...
                'InputHasRowLabels',app.InputHasRowLabels,...
                'InputIsTimetable',app.InputIsTimetable,...
                'Indicator',app.IndicatorButtonGroup.SelectedObject.UserData,...
                'Data',app.DataButtonGroup.SelectedObject.UserData,...
                'GroupingDropdownsValues',{{app.GroupingDropdowns.Value}},...
                'HasTooManyElements',app.HasTooManyElements);

            % additional fields for property inspector view
            if hasInputData(app)
                varList = app.TableVarNames;
            else
                varList = {'Var1' 'Var2' 'Var3'};
            end

            state.IndicatorVar = varList(state.Indicator);
            state.DataVar = varList(state.Data);
            state.GroupingVars = varList(strcmp(state.GroupingDropdownsValues,'groupby'));
        end
        
        function set.State(app,state)
            setTaskState(app,state);
        end
    end
end