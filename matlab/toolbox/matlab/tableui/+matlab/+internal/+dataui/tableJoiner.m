classdef (Hidden = true,Sealed = true) tableJoiner < matlab.task.LiveTask
    % Table Joiner embedded app for performing joining tables in a Live Script
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Widget layout
        UIFigure                            matlab.ui.Figure
        Accordion                           matlab.ui.container.internal.Accordion
        
        % Table input widgets
        TableADropDown                      matlab.ui.control.internal.model.WorkspaceDropDown
        TableBDropDown                      matlab.ui.control.internal.model.WorkspaceDropDown
        
        % Choosing Keys widgets
        LeftKeysDD                       	matlab.ui.control.DropDown
        RightKeysDD                    	    matlab.ui.control.DropDown
        AddButton                           matlab.ui.control.Image
        SubtractButton                      matlab.ui.control.Image
        
        % Join Type widgets
        JoinButtonGroup                     matlab.ui.container.ButtonGroup
        MergeKeysCheckBox                   matlab.ui.control.CheckBox
        SortByTimeCheckBox                  matlab.ui.control.CheckBox
        
        % Visualize Row
        OutputTableCheckbox                 matlab.ui.control.CheckBox
        InputTablesCheckbox                 matlab.ui.control.CheckBox
        
        % Helper properties
        NumKeyRows                          double
        MaxNumKeyRows                       double
        BVars                               cell
        ARowName                            char
        BRowName                            char
        IsTimetableA                        logical
        IsTimetableB                        logical
        ASortedByTime                       logical
        DefaultJoinButton                   double = NaN; % may be updated based on keyword; if so, preferred over horzcat and vertcat
    end
    
    properties (Constant, Transient, Hidden)
        AutoRunCutOff      = 1e6; % combined numel to trigger turning off AutoRun
        TextRowHeight      = 22;  % Same as App Designer default
        DropDownWidth      = 150; % for input data
        PossibleNumKeyRows = 5;   % limit number of keys to reasonable
        IconWidth          = 16;  % width of the +/- icons
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2019b)
        %       2: Add versioning, support table row labels as keys (R2020b)
        %       3: Use Base Class (R2022a)
        %       4: Add SortByTime checkbox (R2023b)
        %       5: Update join method based on keyword (R2024a)
        Version double = 5;
    end
    
    properties
        Workspace  = "base"
        State
        Summary
    end

    events
        % Event for data cleaner so rich editors can get updated without
        % running generated script and updating app document
        StateChangedFromRichEditor
    end
    
    % Write over constructor so we can keep this API with dataCleaner app
    methods (Access = public)
        function app = tableJoiner(fig,workspace)
            arguments
                fig = uifigure("Position",[200 200 700 500]);
                workspace = "base";
            end
            app@matlab.task.LiveTask("Parent",fig);
            app.UIFigure = fig;
            app.Workspace = workspace;
        end
    end

    % setup required by base class
    methods (Access = protected)
        function setup(app)
            % for standalone mode, make the figure large enough for testing
            createComponents(app);
            doUpdate(app);
        end
    end
    
    methods (Access = private)
        % internal app methods
        function createComponents(app)
            % Create the ui components and lay them out in the figure
            
            app.LayoutManager.RowHeight = {'fit'};
            app.LayoutManager.ColumnWidth = {'1x'};
            % the grid is split into accordion panels
            app.Accordion = matlab.ui.container.internal.Accordion('Parent',app.LayoutManager);
            createWidgets(app);
            setWidgetsToDefault(app);
        end
        
        function createWidgets(app)
            createInputDataSection(app);
            createJoinTypeSection(app);
            createVisualizationSection(app);
        end
        
        function G = createNewSection(app,textLabel,c,numRows)
            S = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            S.Title = textLabel;
            G = uigridlayout(S,'ColumnWidth',c,'RowHeight',repmat({'fit'},1,numRows));
        end
        
        function createInputDataSection(app)
            h = createNewSection(app,getMsgText('ChooseInputTables'),...
                {'fit',app.DropDownWidth,'fit',app.DropDownWidth,app.IconWidth,app.IconWidth},6);
            
            % Row 1 table inputs
            uilabel(h,'Text',getMsgText('FirstTable'));
            app.TableADropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            uilabel(h,'Text',getMsgText('SecondTable'));
            app.TableBDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);            
            app.TableADropDown.FilterVariablesFcn = @(t,tname)app.filterInputTable(t,'A',tname);
            app.TableADropDown.ValueChangedFcn = @app.doUpdate;
            app.TableADropDown.ShowNonExistentVariable = true;
            app.TableBDropDown.FilterVariablesFcn = @(t,tname)app.filterInputTable(t,'B',tname);
            app.TableBDropDown.ValueChangedFcn = @app.doUpdate;
            app.TableBDropDown.ShowNonExistentVariable = true;
            
            % Rows 2:6, key rows
            L = uilabel(h,'Text',getMsgText('Keys'));
            L.Layout.Column = 1;
            L.Layout.Row = 2;
            L = uilabel(h,'Text',getMsgText('Keys'));
            L.Layout.Column = 3;
            for k = 1:app.PossibleNumKeyRows
                app.LeftKeysDD(k) = uidropdown(h,'ValueChangedFcn',@app.doUpdate,...
                    'Tag','KeyDropDown','Tooltip',getMsgText('TooltipKeyVariables'));
                app.LeftKeysDD(k).Layout.Column = 2;
                app.LeftKeysDD(k).Layout.Row = k+1;
                
                app.RightKeysDD(k) = uidropdown(h,'ValueChangedFcn',@app.doUpdate,...
                    'Tag','KeyDropDown','Tooltip',getMsgText('TooltipKeyVariables'));
                app.RightKeysDD(k).Layout.Column = 4;
                app.RightKeysDD(k).Layout.Row = k+1;
                
                app.SubtractButton(k) = uiimage(h,'ScaleMethod','none',...
                    'ImageClickedFcn',@app.subtractKey,'Tag','KeyDropDown','UserData',k,...
                    'Tooltip',getMsgText('SubtractKeysTooltip'));
                matlab.ui.control.internal.specifyIconID(app.SubtractButton(k),'minusUI',...
                    app.IconWidth,app.IconWidth);
                app.SubtractButton(k).Layout.Row = k+1;
                app.SubtractButton(k).Layout.Column = 5;
                
                app.AddButton(k) = uiimage(h,'ScaleMethod','none',...
                    'ImageClickedFcn',@app.addKey,'Tag','KeyDropDown',...
                    'Tooltip',getMsgText('AddKeysTooltip'));
                matlab.ui.control.internal.specifyIconID(app.AddButton(k),'plusUI',...
                    app.IconWidth,app.IconWidth);
                app.AddButton(k).Layout.Row = k+1;
                app.AddButton(k).Layout.Column = 6;
            end
            % Helper properties
            app.NumKeyRows = 1;
            app.MaxNumKeyRows = app.PossibleNumKeyRows;
        end
        
        function isSupported = filterInputTable(app,t,type,tname)
            % all combinations of non-empty tables and timetables supported
            % except: A = table, B = timetable. So,
            % given B is a timetable, A must be a timetable
            % given A is a table, B must be a table
            % also, disallow A and B from being the same ws variable
            isSupported = isa(t,'tabular') && ~isempty(t);
            
            if isequal(type,'A')
                B = app.TableBDropDown.WorkspaceValue;
                if isempty(B) && ~strcmp(app.TableBDropDown.Value,'select variable')
                    % the table has been cleared from the workspace
                    app.TableBDropDown.Value = 'select variable';
                    setWidgetsToDefault(app);
                    app.doUpdate;
                elseif ~isempty(B) && isSupported
                    % B is a timetable, A must be a timetable
                    % and B and A must not be the same variable
                    Bname = app.TableBDropDown.Value;
                    isSupported = (~istimetable(B) || istimetable(t)) && ~isequal(Bname,tname);
                end
            else % type B
                A = app.TableADropDown.WorkspaceValue;
                if isempty(A) && ~strcmp(app.TableADropDown.Value,'select variable')
                    % the table has been cleared from the workspace
                    app.TableADropDown.Value = 'select variable';
                    setWidgetsToDefault(app);
                    app.doUpdate;
                elseif ~isempty(A) && isSupported
                    % A is a table, B must be a table
                    % and A and B must not be the same variable
                    Aname = app.TableADropDown.Value;
                    isSupported = (~istable(A) || istable(t)) && ~isequal(Aname,tname);
                end
            end
        end
        
        function createJoinTypeSection(app)
            S = createNewSection(app,getMsgText('ChooseJoinType'),{'fit'},2);
            
            w = 90;
            h = 80;
            g = uigridlayout(S,'ColumnWidth',{6*w},'RowHeight',{h},'Padding',0);
            
            app.JoinButtonGroup = uibuttongroup(g);
            app.JoinButtonGroup.Layout.Column = [1 2];
            app.JoinButtonGroup.BorderType = 'none';
            app.JoinButtonGroup.SelectionChangedFcn = @app.doUpdate;
            
            buttonTexts = {getMsgText('Fullouterjoin'),getMsgText('Leftouterjoin'),...
                getMsgText('Rightouterjoin'),getMsgText('Innerjoin'),...
                getMsgText('Join'),getMsgText('Horzcat')};
            buttonTags = {'outerjoin','outerjoin','outerjoin','innerjoin','join','horzcat'};
            buttonIcons = {'outerJoinPlot','leftOuterJoinPlot','rightOuterJoinPlot',...
                'innerJoinPlot','joinPlot','horzCatPlot'};
            buttonTooltips = {getMsgText('TooltipOuterjoin'),getMsgText('TooltipLeftOuterjoin'),...
                getMsgText('TooltipRightOuterjoin'),getMsgText('TooltipInnerjoin'),...
                getMsgText('TooltipJoin'),getMsgText('TooltipHorzcat')};
            for k = 1:6
                b = uitogglebutton(app.JoinButtonGroup,'Position',[(k-1)*w+1 1 w-2 h-2],...
                    'IconAlignment','top','UserData',k,...
                    'Text',buttonTexts{k},'Tag',buttonTags{k},...
                    'Tooltip',buttonTooltips{k});
                matlab.ui.control.internal.specifyIconID(b,buttonIcons{k},50,40);
            end
            
            g = uigridlayout(S,'ColumnWidth',["fit" "fit"],'RowHeight',"fit",'Padding',0);
            app.MergeKeysCheckBox = uicheckbox(g);
            app.MergeKeysCheckBox.ValueChangedFcn = @app.doUpdate;
            app.MergeKeysCheckBox.Text = getMsgText('MergeKeys');
            app.MergeKeysCheckBox.Tooltip = getMsgText('TooltipMergeKeys');

            app.SortByTimeCheckBox = uicheckbox(g);
            app.SortByTimeCheckBox.ValueChangedFcn = @app.doUpdate;
            app.SortByTimeCheckBox.Text = getMsgText('SortByTime');
        end
        
        function createVisualizationSection(app)
            h = createNewSection(app,getString(message('MATLAB:dataui:Visualizeresults')),...
                {'fit' 'fit'},1);
            
            app.InputTablesCheckbox = uicheckbox(h,...
                'Text', getMsgText('Inputtables'),...
                'ValueChangedFcn',@app.doUpdate);
		    app.OutputTableCheckbox = uicheckbox(h,...
                'Text', getMsgText('Outputtable'),...
                'ValueChangedFcn',@app.doUpdate);
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["outerjoin" "leftouterjoin" "rightouterjoin" "innerjoin"];

            % finds the element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            matchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(matchIdx)
                return;
            end

            app.DefaultJoinButton = matchIdx;
            app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(matchIdx);
            doUpdate(app);
        end

        function setWidgetsToDefault(app)
            defaultButton = app.DefaultJoinButton;
            % if no keyword was used, choose outerjoin
            if isnan(defaultButton)
                defaultButton = 1;
            end
            app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(defaultButton);
            % check istimetable, this works whether or not data has been
            % selected since WorkspaceValue for 'select' is [].
            app.IsTimetableA = istimetable(app.TableADropDown.WorkspaceValue);
            app.IsTimetableB = istimetable(app.TableBDropDown.WorkspaceValue);
            if hasInputData(app)
                populateFirstItemsWithVariables(app);
                selectDefaultLRKeys(app,1);
                updateKeyDropDownItems(app);
            else
                [app.LeftKeysDD.Items] = deal({});
                [app.RightKeysDD.Items] = deal({});
                app.BVars = {};
                app.ARowName = '';
                app.BRowName = '';
                app.ASortedByTime = false;
            end
            
            app.NumKeyRows = 1;
            app.MaxNumKeyRows = min([numel(app.LeftKeysDD(1).Items),numel(app.BVars),app.PossibleNumKeyRows]);
            app.MergeKeysCheckBox.Value = false;
            app.SortByTimeCheckBox.Value = true;
            % should we enable horzcat/vertcat? If so, make it the default
            if canDoHorzcat(app)
                app.JoinButtonGroup.Buttons(6).Visible = 'on';
                setButton6Properties(app,true);

                % only do this if there is not a keyword default
                if isnan(app.DefaultJoinButton)
                    app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(6);
                end
            elseif canDoVertcat(app)
                app.JoinButtonGroup.Buttons(6).Visible = 'on';
                setButton6Properties(app,false);

                % only do this if there is not a keyword default
                if isnan(app.DefaultJoinButton)
                    app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(6);
                end
            elseif hasInputData(app)
                % can't do either, let's hide it
                app.JoinButtonGroup.Buttons(6).Visible = 'off';
            else
                % default app state when no data selected: visible, horzcat
                setButton6Properties(app,true);
                app.JoinButtonGroup.Buttons(6).Visible = 'on';
            end
            
            app.OutputTableCheckbox.Value = isequal(app.Workspace,'base');
            app.InputTablesCheckbox.Value = false;
        end
               
        function populateFirstItemsWithVariables(app)
            A = app.TableADropDown.WorkspaceValue;
            B = app.TableBDropDown.WorkspaceValue;
            app.LeftKeysDD(1).Items = A.Properties.VariableNames;
            app.BVars = B.Properties.VariableNames;
            
            % populate LeftKeysDD1(Avars) and Bvars
            if app.IsTimetableA || ~isempty(A.Properties.RowNames)
                app.ARowName = A.Properties.DimensionNames{1};
                app.LeftKeysDD(1).Items = [{app.ARowName},app.LeftKeysDD(1).Items];
            else
                app.ARowName = '';
            end
            if app.IsTimetableB || ~isempty(B.Properties.RowNames)
                app.BRowName = B.Properties.DimensionNames{1};
                app.BVars = [{app.BRowName}, app.BVars];
            else
                app.BRowName = '';
            end
            app.ASortedByTime = app.IsTimetableA && issorted(A.Properties.RowTimes);
        end

        function selectDefaultLRKeys(app,n)
            % Choose from shared names or score pairs
            leftDD = app.LeftKeysDD(n);
            rightDD = app.RightKeysDD(n);
            leftItems = leftDD.Items;
            rightItems = app.BVars;
            if n ~= 1
                % remove values already chosen from the items list
                emptyValues = cellfun(@isempty,{app.RightKeysDD(1:n-1).Value});
                rightItems = setdiff(rightItems,{app.RightKeysDD(~emptyValues).Value},'stable');
            end

            % First check for row times/labels (even if they have different names)
            if strcmp(leftItems{1},app.ARowName) && strcmp(rightItems{1},app.BRowName) && ...
                    app.isValidKeyPair(app.ARowName,app.BRowName)
                leftDD.Value = app.ARowName;
                rightDD.Items = {app.BRowName};
                rightDD.Value = app.BRowName;
                return
            end

            % Next, check to see if there are any exact matches
            intersectVars = intersect(leftItems,rightItems,'stable');
            for k = 1:numel(intersectVars)
                if app.isValidKeyPair(intersectVars{k},intersectVars{k})
                    leftDD.Value = intersectVars{k};
                    rightDD.Items = intersectVars(k);
                    rightDD.Value = intersectVars{k};
                    return
                end
            end

            if n == 1
                % Finally, get default by calculating scores for each pair
                [leftKey,rightKey] = matlab.internal.dataui.selectJoinKeys(...
                    app.TableADropDown.WorkspaceValue,app.TableBDropDown.WorkspaceValue);
            else
                % Don't recalculate scores, for performance
                leftKey = '';
            end

            if ~isempty(leftKey)
                leftDD.Value = leftKey;
                rightDD.Items = {rightKey};
                rightDD.Value = rightKey;
            else
                % No good guess, choose first value in the dropdown
                leftDD.Value = leftItems{1};
            end
        end

        function updateKeyDropDownItems(app)
            for k = 2:app.PossibleNumKeyRows
                % populate items in left DDs
                app.LeftKeysDD(k).Items = setdiff(...
                    app.LeftKeysDD(k-1).Items,app.LeftKeysDD(k-1).Value,'stable');
            end
            
            for k = 1:app.NumKeyRows
                % populate items in right DDs based on values in left DDs
                keepItems = true(1,numel(app.BVars));
                for j = 1:numel(app.BVars)
                    keepItems(j) = app.isValidKeyPair(app.LeftKeysDD(k).Value,app.BVars{j});
                end
                items = app.BVars(keepItems);
                for j = 1:k-1
                    % remove values from previous dds
                    items = setdiff(items, app.RightKeysDD(j).Value,'stable');
                end
                app.RightKeysDD(k).Items = items;
            end
        end
        
        function TF = isValidKeyPair(app,LKey,RKey)
            % try outerjoin on the first row of the table
            A = head(app.TableADropDown.WorkspaceValue,3);
            B = head(app.TableBDropDown.WorkspaceValue,3);
            TF = false;
            try
                % try outerjoin both ways (in case concatenation only works in one direction)
                outerjoin(A,B,'Type','Left','LeftKeys',LKey,'RightKeys',RKey,'MergeKeys',true);
                outerjoin(A,B,'Type','Right','LeftKeys',LKey,'RightKeys',RKey,'MergeKeys',true);
                TF = true;
            catch                
            end
        end
        
        function setButton6Properties(app,isHorzcat)
            if isHorzcat
                app.JoinButtonGroup.Buttons(6).Text = getMsgText('Horzcat');
                app.JoinButtonGroup.Buttons(6).Tag = 'horzcat';
                app.JoinButtonGroup.Buttons(6).Tooltip = getMsgText('TooltipHorzcat');
                matlab.ui.control.internal.specifyIconID(app.JoinButtonGroup.Buttons(6),'horzCatPlot',50,40);
            else
                app.JoinButtonGroup.Buttons(6).Text = getMsgText('Vertcat');
                app.JoinButtonGroup.Buttons(6).Tag = 'vertcat';
                app.JoinButtonGroup.Buttons(6).Tooltip = getMsgText('TooltipVertcat');
                matlab.ui.control.internal.specifyIconID(app.JoinButtonGroup.Buttons(6),'vertCatPlot',50,40);
            end
        end
        
        function doUpdate(app,source,~,fromRichEditorChange)
            if nargin < 2
                source = [];
            else
                % from widget change, make sure variables are still there
                if isempty(app.TableADropDown.WorkspaceValue)
                    app.TableADropDown.Value = 'select variable';
                end
                if isempty(app.TableBDropDown.WorkspaceValue)
                    app.TableBDropDown.Value = 'select variable';
                end
                if ~hasInputData(app)
                    setWidgetsToDefault(app);
                end
            end
            % Update the entire task
            updateWidgets(app,source);
            % notify listeners that the task has been updated
            if nargin > 3 && fromRichEditorChange
                notify(app,'StateChangedFromRichEditor');
            else
                notify(app,'StateChanged');
            end
        end
        
        function updateWidgets(app,source)
            if isequal(source, app.TableADropDown) || isequal(source, app.TableBDropDown)
                % reset the app
                setWidgetsToDefault(app);
                % If data is too large, turn auto-run off.
                % Once triggered, user is in control, so no need to reset to
                % true for small data
                if hasInputData(app) && (numel(app.TableADropDown.WorkspaceValue) + numel(app.TableBDropDown.WorkspaceValue) > app.AutoRunCutOff)
                    app.AutoRun = false;
                end
            elseif ~isempty(source) && isequal(source.Tag,'KeyDropDown')
                updateKeyDropDownItems(app);
            end
            
            hasInput = hasInputData(app);
            
            % keys rows
            app.AddButton(1).Layout.Column = 5 + (app.NumKeyRows > 1);
            % toggle enable for all key row widgets
            [app.LeftKeysDD.Enable] = deal(hasInput);
            [app.RightKeysDD.Enable] = deal(hasInput);
            [app.AddButton.Enable] = deal(hasInput);
            [app.SubtractButton.Enable] = deal(hasInput);
            
            % show/hide key rows
            isConcatenation = app.JoinButtonGroup.SelectedObject.UserData == 6;
            showRow = (app.NumKeyRows >= 1:app.PossibleNumKeyRows) & ~isConcatenation;
            inputGrid = app.TableADropDown.Parent;
            inputGrid.RowHeight(1+(1:app.PossibleNumKeyRows)) = num2cell(app.TextRowHeight*showRow);
            showRowCell = num2cell(showRow);
            [app.LeftKeysDD.Visible] = deal(showRowCell{:});
            [app.RightKeysDD.Visible] = deal(showRowCell{:});
            [app.SubtractButton.Visible] = deal(showRowCell{:});
            showAddButtons = num2cell((app.NumKeyRows < app.MaxNumKeyRows) & showRow);
            [app.AddButton.Visible] = deal(showAddButtons{:});
            % only show 1st subtract button if more than one key
            app.SubtractButton(1).Visible = (app.NumKeyRows > 1) && ~isConcatenation;
            
            % set column width to aid in correct figure width
            if app.AddButton(1).Layout.Column == 6 && strcmp(app.AddButton(1).Visible,'on')
                inputGrid.ColumnWidth(5:6) = {app.IconWidth app.IconWidth};
            else
                inputGrid.ColumnWidth{6} = 0;
                if strcmp(app.AddButton(1).Visible,'on') || strcmp(app.SubtractButton(1).Visible,'on')
                    inputGrid.ColumnWidth{5} = app.IconWidth;
                else
                    inputGrid.ColumnWidth{5} = 0;
                end
            end
            
            % set tooltips for right key dds
            isemptyDD = cellfun(@(X)isempty(X) && hasInput,{app.RightKeysDD.Items});
            [app.RightKeysDD(isemptyDD).Tooltip] = deal(getMsgText('TooltipKeyVariablesEmpty'));
            [app.RightKeysDD(~isemptyDD).Tooltip] = deal(getMsgText('TooltipKeyVariables'));
            
            % join rows
            [app.JoinButtonGroup.Buttons.Enable] = deal(hasInput);
            if strcmp(app.JoinButtonGroup.Buttons(6).Visible,'on')
                app.JoinButtonGroup.Parent.ColumnWidth = {540};
            else
                app.JoinButtonGroup.Parent.ColumnWidth = {450};
            end
            app.MergeKeysCheckBox.Enable = hasInput;
            app.MergeKeysCheckBox.Visible = hasInput && isequal(app.JoinButtonGroup.SelectedObject.Tag,'outerjoin') && ~isKeyRowLabelsOnly(app);
            app.SortByTimeCheckBox.Enable = hasInput;
            % Don't show sort by time for concatenation or for "join" as
            % these provide results with expected sorting
            app.SortByTimeCheckBox.Visible = hasInput && app.ASortedByTime && ...
                app.JoinButtonGroup.SelectedObject.UserData < 5 && ...
                ~isequal(app.LeftKeysDD(1).Value,app.ARowName);
            matlab.internal.dataui.setParentForWidgets([app.MergeKeysCheckBox app.SortByTimeCheckBox],...
                app.Accordion.Children(2).Children.Children(2))            
            
            % visualization row
            app.OutputTableCheckbox.Enable = hasInput;
            app.InputTablesCheckbox.Enable = hasInput;
        end
        
        function TF = isKeyRowTimesOnly(app)
            % used to know whether or not we need to put Keys NV pair in script
            TF = app.NumKeyRows == 1 && app.IsTimetableA && app.IsTimetableB && ...
                isequal(app.LeftKeysDD(1).Value,app.ARowName) && isequal(app.RightKeysDD(1).Value,app.BRowName);
        end
        
        function TF = isKeyRowLabelsOnly(app)
            % used to determine if 'MergeKeys' will have no effect
            TF = app.NumKeyRows == 1 && ...
                ~isempty(app.LeftKeysDD(1).Value) && ~isempty(app.RightKeysDD(1).Value) && ...
                isequal(app.LeftKeysDD(1).Value,app.ARowName) && ...
                isequal(app.RightKeysDD(1).Value,app.BRowName);
        end
        
        function TF = keysAllMatching(app)
           leftVals = {app.LeftKeysDD(1:app.NumKeyRows).Value};
           rightVals = {app.RightKeysDD(1:app.NumKeyRows).Value};
           
           TF = all(strcmp(leftVals,rightVals) | cellfun(@isempty,rightVals));
        end
                
        function hasInput = hasInputData(app)
            hasInput = ~strcmp(app.TableADropDown.Value,'select variable') && ~strcmp(app.TableBDropDown.Value,'select variable');
        end
        
        function TF = canDoHorzcat(app)
            TF = true;
            if hasInputData(app)
                A = app.TableADropDown.WorkspaceValue;
                B = app.TableBDropDown.WorkspaceValue;
                if height(A) ~= height(B)
                    TF = false;
                elseif ~isempty(intersect(A.Properties.VariableNames,B.Properties.VariableNames))
                    TF = false;
                elseif app.IsTimetableA && app.IsTimetableB && ~isequal(sort(A.Properties.RowTimes),sort(B.Properties.RowTimes))
                    TF = false;
                elseif istable(A) && istable(B) && ...
                        ~isempty(A.Properties.RowNames) && ~isempty(B.Properties.RowNames) && ...
                        ~isequal(sort(A.Properties.RowNames),sort(B.Properties.RowNames))
                    TF = false;
                end
            else
                TF = false;
            end
        end
        
        function TF = canDoVertcat(app)
            TF = true;
            if hasInputData(app)
                A = app.TableADropDown.WorkspaceValue;
                B = app.TableBDropDown.WorkspaceValue;
                try
                   % concatenate the first row of each table to ensure the 
                   % datatypes are compatible and variable names match
                    t = [A(1,:);B(1,:)]; %#ok<NASGU>
                catch
                    TF = false;
                    return
                end
                if istable(A) && istable(B) &&...
                        ~isempty(intersect(A.Properties.RowNames,B.Properties.RowNames))
                    % additionally, no rownames can match
                    TF = false;
                    return
                end
            else
                TF = false;
            end
        end
        
        function addKey(app,src,~)
            % make sure variables are still there
            if isempty(app.TableADropDown.WorkspaceValue)
                app.TableADropDown.Value = 'select variable';
            end
            if isempty(app.TableBDropDown.WorkspaceValue)
                app.TableBDropDown.Value = 'select variable';
            end
            if ~hasInputData(app)
                setWidgetsToDefault(app);
                app.doUpdate;
            else
                app.NumKeyRows = min(app.NumKeyRows + 1, app.MaxNumKeyRows);
                updateDefaultOnAddKey(app);
                app.doUpdate(src);
            end
        end

        function updateDefaultOnAddKey(app)
            % Using row names in combination with other keys, are not supported
            % limitation for tables only, remove from dd list on adding key rows
            if istable(app.TableADropDown.WorkspaceValue) && ~isempty(app.ARowName) && isequal(app.LeftKeysDD(1).Items{1},app.ARowName)
                app.LeftKeysDD(1).Items(1) = [];
            end
            if istable(app.TableBDropDown.WorkspaceValue) && ~isempty(app.BRowName) && isequal(app.BVars{1},app.BRowName)
                app.BVars(1) = [];
            end
            selectDefaultLRKeys(app,app.NumKeyRows);
        end
        
        function subtractKey(app,src,~)
            app.NumKeyRows = max(app.NumKeyRows - 1, 1);
            % shift up everything visible below selected row so it appears that the row disappeared
            for k = src.UserData : app.NumKeyRows
                app.LeftKeysDD(k).Value =  app.LeftKeysDD(k+1).Value;
                app.RightKeysDD(k).Items =  app.RightKeysDD(k+1).Items;
                app.RightKeysDD(k).Value =  app.RightKeysDD(k+1).Value;
            end
            updateDefaultOnSubtractKey(app)
            app.doUpdate(src);
        end

        function updateDefaultOnSubtractKey(app)
            if app.NumKeyRows == 1
                % may need to add row labels back in for tables
                % using row names in combination with other keys are not supported
                if istable(app.TableADropDown.WorkspaceValue) && ~isempty(app.ARowName) && ~isequal(app.LeftKeysDD(1).Items{1},app.ARowName)
                    app.LeftKeysDD(1).Items = [{app.ARowName} app.LeftKeysDD(1).Items];
                end
                if istable(app.TableBDropDown.WorkspaceValue) && ~isempty(app.BRowName) && ~isequal(app.BVars{1},app.BRowName)
                    app.BVars = [{app.BRowName} app.BVars];
                end
            end
        end
                
        function code = addKeyParameter(app,code,type)
            nonEmptyKeys = ~cellfun(@isempty,{app.RightKeysDD(1:app.NumKeyRows).Value});
            if any(nonEmptyKeys)
                % at this point type can be ''
                code = matlab.internal.dataui.addCharToCode(code,[',' type 'Keys=']);
                if isempty(type)
                    % change to Left to use dropdown values
                    type = 'Left';
                end
                code = matlab.internal.dataui.addCellStrToCode(code,{app.([type 'KeysDD'])(nonEmptyKeys).Value});
            end
        end
    end
    
    % Methods required for embedding in a Live Script
    methods (Access = public)
        function reset(app)
            setWidgetsToDefault(app);
            doUpdate(app);
        end
        
        function [code, outputs] = generateScript(app,isForExport,overwriteInput)
            if nargin < 2
                % Second input is for "cleaned up" export code. E.g., don't
                % introduce temp vars for plotting.
                % No difference for this task.
                isForExport = false;
            end
            if nargin < 3
                % Third input is for whether or not we want to overwrite
                % the input with the output
                % In this case, we overwrite the left table
                overwriteInput = isForExport;
            end
            code = '';
            outputs = {};
            if (overwriteInput && ~isForExport) || ~hasInputData(app)
                % overwriting input is only supported for export script and
                % should not be used internally prior to plotting
                return
            end
            
            if overwriteInput
                outputs = {app.TableADropDown.Value};
            else
                outputs = {'joinedData'};
            end
            
            % setup function
            code = ['% ' getMsgText('MergeTables') newline];
            code = [code outputs{1} ' = '];

            if isequal(app.Workspace,'base')
                tick = '`';
            else
                tick = '';
            end
            inputAName = [tick app.TableADropDown.Value tick];
            inputBName = [tick app.TableBDropDown.Value tick];
            
            if app.JoinButtonGroup.SelectedObject.UserData == 6
                % horzcat or vertcat, use bracket notation for PRISM
                code = matlab.internal.dataui.addCharToCode(code,['[' inputAName]);
                if isequal(app.JoinButtonGroup.SelectedObject.Tag,'horzcat')
                     code = [code ', '];
                else %vertcat
                    code = [code '; '];
                end
                code = matlab.internal.dataui.addCharToCode(code,[inputBName ']']);
            else
                % sortrows wrapper
                doSortRows = app.SortByTimeCheckBox.Value && app.SortByTimeCheckBox.Visible;
                if doSortRows
                    code = matlab.internal.dataui.addCharToCode(code,'sortrows(');
                end

                % join function call
                code = matlab.internal.dataui.addCharToCode(code,[app.JoinButtonGroup.SelectedObject.Tag '(']);
                
                % inputs
                code = matlab.internal.dataui.addCharToCode(code,[inputAName ',']);
                code = matlab.internal.dataui.addCharToCode(code,inputBName);
                                
                % outerjoin type
                if app.JoinButtonGroup.SelectedObject.UserData == 2
                    code = matlab.internal.dataui.addCharToCode(code,',Type="left"');
                elseif app.JoinButtonGroup.SelectedObject.UserData == 3
                    code = matlab.internal.dataui.addCharToCode(code,',Type="right"');
                end
                
                % keys - note row times is default, so no code needed
                if keysAllMatching(app) && ~isKeyRowTimesOnly(app)
                    code = addKeyParameter(app,code,'');
                elseif ~isKeyRowTimesOnly(app)
                    code = addKeyParameter(app,code,'Left');
                    code = addKeyParameter(app,code,'Right');
                end
                
                % mergekeys (only need if true)
                if isequal(app.MergeKeysCheckBox.Visible,'on') && app.MergeKeysCheckBox.Value
                    code = matlab.internal.dataui.addCharToCode(code,',MergeKeys=true');
                end
                
                code = [code ')'];
                if doSortRows
                    code = [code ')'];
                end
            end
            
            if app.InputTablesCheckbox.Value || ~app.OutputTableCheckbox.Value
                code = [code ';'];
            end
        end
        
        function code = generateVisualizationScript(app)
            code = '';
            if app.InputTablesCheckbox.Value
                code = ['% ' getString(message('MATLAB:dataui:Visualizeresults'))];
                
                code = [code newline '`' app.TableADropDown.Value '`'];
                code = [code newline '`' app.TableBDropDown.Value '`'];
                if app.OutputTableCheckbox.Value
                    code = [code newline 'joinedData'];
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
            % Inputs - the names of the input tables. Only up to 2 are used
            % TableVariableNames - not used
            % Code - keyword used in editor to select task

            if ~isequal(NVpairs.Code,"")
                updateDefaultsFromKeyword(app,NVpairs.Code);
            end

            if ~isempty(NVpairs.Inputs)
                app.TableADropDown.populateVariables();
                if ismember(NVpairs.Inputs(1),app.TableADropDown.ItemsData)
                    app.TableADropDown.Value = NVpairs.Inputs(1);
                    doUpdate(app,app.TableADropDown,[]);
                end
                if numel(NVpairs.Inputs) > 1
                    app.TableBDropDown.populateVariables();
                    if ismember(NVpairs.Inputs(2),app.TableBDropDown.ItemsData)
                        app.TableBDropDown.Value = NVpairs.Inputs(2);
                        doUpdate(app,app.TableBDropDown,[]);
                    end
                end
            end
        end

        function setTaskState(app,state,widget)
            if nargin < 3
                widget = '';
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
                % set workspace dropdowns and checkboxes
                for k = ["TableADropDown" "TableBDropDown" ...
                        "MergeKeysCheckBox" "OutputTableCheckbox" ...
                        "InputTablesCheckbox" "SortByTimeCheckBox"]
                    if isfield(state,k + "Value")
                        app.(k).Value = state.(k + "Value");
                    end
                end
                % set items then values of each dropdown
                if isequal(widget,'JoinKeysControl') && isfield(state,'KeyStruct')
                    % App workflow, need to "press" add and/or subtract to
                    % mimic live task workflow and get the correct items
                    [app.LeftKeysDD.Items] = deal(state.KeyStruct.LeftKeysDDItems{:});
                    [app.LeftKeysDD.Value] = deal(state.KeyStruct.LeftKeysDDValues{:});
                    [app.RightKeysDD.Items] = deal(state.KeyStruct.RightKeysDDItems{:});
                    [app.RightKeysDD.Value] = deal(state.KeyStruct.RightKeysDDValues{:});
                    n_old = app.NumKeyRows;
                    app.NumKeyRows = state.KeyStruct.NumKeyRows;
                    if  app.NumKeyRows > n_old
                        % add button pressed in JoinKeysControl
                        updateDefaultOnAddKey(app);
                    elseif app.NumKeyRows < n_old
                        % subtract button pressed in JoinKeysControl
                        updateDefaultOnSubtractKey(app);
                    end
                else
                    for DD = ["LeftKeysDD" "RightKeysDD"]
                        for property = ["Items" "Value"]
                            for k = 1:app.PossibleNumKeyRows
                                fieldName = DD + k + property;
                                if isfield(state,fieldName)
                                    fieldValue = state.(fieldName);
                                    if isempty(fieldValue)
                                        % jsonencode/decode changes empty cell to empty double
                                        fieldValue = {};
                                    end
                                    app.(DD)(k).(property) = fieldValue;
                                end
                            end
                        end
                    end
                    if isfield(state,'NumKeyRows')
                        app.NumKeyRows = state.NumKeyRows;
                    end
                end
                % Helper properties
                for k = ["MaxNumKeyRows" "ARowName" "BRowName" "ASortedByTime"]
                    if isfield(state,k)
                        app.(k) = state.(k);
                    end
                end
                for k = ["IsTimetableA" "IsTimetableB"]
                    if isfield(state,k)
                        app.(k) = state.(k);
                    else
                        app.(k) = false;
                    end
                end
                if isfield(state,'BVars')
                    if isempty(state.BVars)
                        % jsonencode/decode changes empty cell to empty double
                        state.BVars = {};
                    end
                    app.BVars = state.BVars;
                end
                if isequal(widget,'JoinButtonGroup') && isfield(state,'JoinButtonAppValue')
                    app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(state.JoinButtonAppValue(1));
                elseif isfield(state,'JoinButtonGroup')
                    app.JoinButtonGroup.SelectedObject = app.JoinButtonGroup.Buttons(state.JoinButtonGroup);
                end
                if isfield(state,'DefaultJoinButton')
                    app.DefaultJoinButton = state.DefaultJoinButton;
                end
                if isfield(state,'isButton6Horzcat')
                    setButton6Properties(app,state.isButton6Horzcat);
                end
                if isfield(state,'isButton6Visible')
                    app.JoinButtonGroup.Buttons(6).Visible = state.isButton6Visible;
                end
                if isempty(widget)
                    doUpdate(app);
                elseif isequal(widget,'JoinKeysControl')
                    doUpdate(app,struct('Tag','KeyDropDown'),[],true);
                else
                    doUpdate(app,app.(widget));
                end
            end
        end

        function propTable = getPropertyInformation(app)
            % propTable is a list of all the controls visible in the Data
            % Cleaner app along with everything needed to map the
            % uifigure into the property inspector

            Name = ["TableADropDown";"TableBDropDown";...
                "JoinKeysControl";"JoinButtonGroup"; ...
                "MergeKeysCheckBox";"SortByTimeCheckBox"];
            Group = [repmat(string(getMsgText('ChooseInputTables')),3,1);...
                repmat(string(getMsgText('ChooseJoinType')),3,1)];
            DisplayName = string({getMsgText('FirstTable'); getMsgText('SecondTable');...
                getMsgText('Keys'); getMsgText('JoinType'); getMsgText('MergeKeys'); getMsgText('SortByTime')});
            StateName = ["TableADropDownValue"; "TableBDropDownValue";...
                "KeyStruct"; "JoinButtonAppValue"; "MergeKeysCheckBoxValue"; "SortByTimeCheckBoxValue"];
            Type = {class(app.TableADropDown); class(app.TableBDropDown);...
                'matlab.internal.dataui.richeditors.JoinKeysControl'; ...
                'matlab.internal.dataui.richeditors.JoinButtonControl';
                class(app.MergeKeysCheckBox); class(app.SortByTimeCheckBox)};
            app.TableADropDown.populateVariables();
            app.TableBDropDown.populateVariables();
            Items = {app.TableADropDown.Items; app.TableBDropDown.Items; []; []; []; []};
            ItemsData = {app.TableADropDown.ItemsData; app.TableBDropDown.ItemsData; []; []; []; []};
            Tooltip = {''; ''; app.LeftKeysDD(1).Tooltip; '';app.MergeKeysCheckBox.Tooltip; ''};

            N = numel(Name);
            Visible = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            Visible(3) = app.LeftKeysDD(1).Visible;
            Visible(5) = app.MergeKeysCheckBox.Visible;
            Visible(6) = app.SortByTimeCheckBox.Visible;
            Enable = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            Enable(3:end) = app.LeftKeysDD(1).Enable;
            SpinnerProperties = repmat({[]},N,1);
            InitializeFlag = zeros(N,1);
            InSubgroup = false(N,1);
            GroupExpanded = true(N,1);

            propTable = table(Name,Group,DisplayName,StateName,Type,Tooltip,Items,ItemsData,...
                Visible,Enable,InitializeFlag,InSubgroup,GroupExpanded,SpinnerProperties);
        end

        function msg = getInspectorDisplayMsg(~)
            % Used in data cleaner app to display when no valid variables,
            % but joining only requires non-empty tables or timetables, and
            % the app doesn't allow empties
            msg = '';
        end
    end
    
    methods
        function summary = get.Summary(app)
            
            if ~hasInputData(app)
                summary = string(message('MATLAB:tableui:Tool_tableJoiner_Description'));
            else
                switch app.JoinButtonGroup.SelectedObject.UserData
                    case 1
                        method = getMsgText('SummaryOuterjoin');
                    case 2
                        method = getMsgText('SummaryLeftouterjoin');
                    case 3
                        method = getMsgText('SummaryRightouterjoin');
                    case 4
                        method = getMsgText('SummaryInnerjoin');
                    case 5
                        method = getMsgText('SummaryJoin');
                    case 6
                        if strcmp(app.JoinButtonGroup.Buttons(6).Tag,'horzcat')
                            method = getMsgText('SummaryHorzcat');
                        else
                            method = getMsgText('SummaryVertcat');
                        end
                end
                summary = string(getMsgText('SummaryLine',...
                    ['`' app.TableADropDown.Value '`'],['`' app.TableBDropDown.Value '`'],method));
            end
        end
        
        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;
            
            % for these widgets, just save the value
            for k = ["TableADropDown" "TableBDropDown" "MergeKeysCheckBox"...
                    "SortByTimeCheckBox" "OutputTableCheckbox" "InputTablesCheckbox"]
                state.(k + "Value") = app.(k).Value;
            end
            % for these widgets, save the value and Items (since items are
            % also changed dynamically)
            for k = 1:app.PossibleNumKeyRows
                for DD = ["LeftKeysDD" "RightKeysDD"]
                    state.(DD + k + "Value") = app.(DD)(k).Value;
                    state.(DD + k + "Items") = app.(DD)(k).Items;
                end
            end
            % save the helper properties
            for k = ["NumKeyRows" "MaxNumKeyRows" "BVars" "ARowName" "BRowName" "ASortedByTime"]
                state.(k) = app.(k);
            end
            for k = ["IsTimetableA" "IsTimetableB"]
                % Minimize state by only saving non-default values
                if app.(k)
                    state.(k) = true;
                end
            end
            % other information that we need to set the state
            state.JoinButtonGroup = app.JoinButtonGroup.SelectedObject.UserData;
            state.isButton6Horzcat = strcmp(app.JoinButtonGroup.Buttons(6).Tag,'horzcat');
            state.isButton6Visible = logical(app.JoinButtonGroup.Buttons(6).Visible);
            state.DefaultJoinButton = app.DefaultJoinButton;
            % ButtonGroup in one state field for app control
            state.JoinButtonAppValue = [state.JoinButtonGroup state.isButton6Horzcat state.isButton6Visible];
            % Key information in one state field for app control
            state.KeyStruct = struct('NumKeyRows',app.NumKeyRows,...
                'MaxNumKeyRows',app.MaxNumKeyRows,...
                'LeftKeysDDItems',{{app.LeftKeysDD.Items}},...
                'RightKeysDDItems',{{app.RightKeysDD.Items}},...
                'LeftKeysDDValues',{{app.LeftKeysDD.Value}},...
                'RightKeysDDValues',{{app.RightKeysDD.Value}});
        end
        
        function set.State(app,state)
            setTaskState(app,state);
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            app.TableADropDown.Workspace = ws; %#ok<*MCSUP>
            app.TableBDropDown.Workspace = ws;
        end
    end 
end

function s = getMsgText(msgId,varargin)
s = getString(message(['MATLAB:tableui:tableJoiner' msgId],varargin{:}));
end
