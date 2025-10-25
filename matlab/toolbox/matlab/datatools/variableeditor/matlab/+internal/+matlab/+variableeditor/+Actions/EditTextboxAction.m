classdef EditTextboxAction < internal.matlab.variableeditor.VEAction
    %EditCheckboxAction

    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'EditTextboxAction'
    end

    methods
        function this = EditTextboxAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.EditTextboxAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.EditTextbox;
        end
        
        function EditTextbox(this, editInfo)
            idx = arrayfun(@(x) isequal(x.DocID, editInfo.docID), this.veManager.Documents);
            sh = this.veManager.Documents(idx).ViewModel.ActionStateHandler;
            
            channel = strcat('/VE/filter',editInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            % Refresh all filter views on the filterManager.
            internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshViews(mgr);
            colIndex = editInfo.actionInfo.index + 1;
            [colName, columnDataIndex] = sh.ViewModel.getHeaderInfoFromIndex(colIndex);
            
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            % tws = TabularVariableFilteringWorkspace
            tws = mgr.Workspaces('filterWorkspace');
            
            % g1796604: If table is empty, return early since interaction
            % via checkboxes and plot interaction is disabled.
            if ~isempty(tws.(colName))
                % Taking only the first row since information is repeated
                tableVar = tws.(colName)(1,:);
            else
                return;
            end
            
            % g1778901: Integers cannot have missing values so setting the
            % includeMissing flag to false
            if isinteger(tws.OriginalTable.(colName))
                includeMissing = false;
            else
                includeMissing = tableVar.IncludeMissing;
            end
            
            % Get the current min and max from the workspace
            % g1778886: Convert to full since sprintf function does not
            % work for sparse values.
            currentMin = full(tableVar.SelectedRangeMin);
            currentMax = full(tableVar.SelectedRangeMax);
            
            % Check if action is a no-op and return early
            if (currentMin == tableVar.OriginalMin && currentMax == tableVar.OriginalMax && (tableVar.IncludeMissing) ...
                    && (isempty(sh.CommandArray) || ~ismember(colIndex, [sh.CommandArray(1:end).Index])))
                return;
            end
            
            [mCode, executionCode] = this.getNumericFilterCode(sh, colName, currentMin, currentMax, tableVar, includeMissing);
            
            % Update the DataModel with the filtered table
            sh.DataModel.Data = tws.FilteredTable;
            sh.IsUserInteraction = true;
            
            isFiltered = true;
            % If the Min and Max have not changed and missing is included,
            % set the isFiltered flag to false.
            if ((currentMin == tableVar.OriginalMin || (ismissing(currentMin) && ismissing(tableVar.OriginalMin))) && ...
                (currentMax == tableVar.OriginalMax || (ismissing(currentMin) && ismissing(tableVar.OriginalMin))) && ...
                includeMissing)
                isFiltered = false;
            end
            
            sh.ViewModel.setColumnModelProperty(colIndex, 'IsFiltered', isFiltered);
            
            % Update the client with the filtered view 
            sh.updateClientView();
                        
            % commandArray contains a list of all the interactive sortand filter commands issued for a output
            sh.CommandArray = [sh.CommandArray, struct('Command', "Filter", 'Index', colIndex, 'commandInfo', ...
                struct('minVal', currentMin, 'maxVal', currentMax, 'missingFlag', includeMissing), 'generatedCode', {mCode}, 'executionCode', {executionCode})];
                
            sh.getCodegenCommands(colIndex, "Filter");
            sh.IsUserInteraction = true;
            sh.publishCode(colIndex);
            
            % Execute all sort commands
            sh.executeSortCommands();

            % Publish to any MATLAB listeners on the View since this action
            % is use by both the LE and VE.
            eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
            eventdata.UserAction = 'Filter';
            eventdata.Index = colIndex;
            % When tables have nested tables/grouped columns, data index is different from column Index.
            eventdata.DataIndex = columnDataIndex;
            eventdata.Code = mCode;
            sh.ViewModel.notify('UserDataInteraction', eventdata);
        end
        
        function [filtCode, executionCode] = getNumericFilterCode(~, sh, cName, minV, maxV, wsVar, includeMissing)
            vName = sh.Name;
            DM = 'tempDM';
            if (includeMissing)
                if isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                    % Codegen for case: Reset
                    filtCode = {[';']};
                    executionCode = {sprintf('tempDM = this.OrigData;')};
                elseif isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.SelectedRangeMaxFullPrecision)
                    % Codegen for case: Min = Max
                    if ~isdatetime(minV)
                        if isduration(minV)
                            minV = [char(39) char(minV) char(39)];
                        else
                            minV = num2str(minV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' minV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s == %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' minV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s == %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName)};
                    end
                elseif isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && ~isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                    % Codegen for case: Max Val Changed
                    if ~isdatetime(maxV)
                        if isduration(maxV)
                            maxV = [char(39) char(maxV) char(39)];
                        else
                            maxV = num2str(maxV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' <= ' maxV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s <= %s | ismissing(%s.%s),:);', DM,DM,DM,cName,maxV,DM,cName)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(maxV.Format);
                        maxV.Format = fmt;
                        maxV = dateshift(maxV, 'end', internal.matlab.variableeditor.peer.PeerDataUtils.getDatetimePrecisionFromFormat(maxV.Format));
                        maxV = [char(39) char(maxV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' < ' maxV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s < %s | ismissing(%s.%s),:);', DM,DM,DM,cName,maxV,DM,cName)};
                    end
                elseif ~isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                    % Codegen for case: Min Val Changed
                    if ~isdatetime(minV)
                        if isduration(minV)
                            minV = [char(39) char(minV) char(39)];
                        else
                            minV = num2str(minV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName)};
                    end
                else
                    % Codegen for case: Min and Max Val Changed
                    if (~isdatetime(minV) && ~isdatetime(maxV))
                        if isduration(minV) || isduration(maxV)
                            minV = [char(39) char(minV) char(39)];
                            maxV = [char(39) char(maxV) char(39)];
                        else
                            minV = num2str(minV);
                            maxV = num2str(maxV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' & ' vName '.' cName ' <= ' maxV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s & %s.%s <= %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName,maxV,DM,cName)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        maxV.Format = fmt;
                        maxV = dateshift(maxV, 'end', internal.matlab.variableeditor.peer.PeerDataUtils.getDatetimePrecisionFromFormat(maxV.Format));
                        maxV = [char(39) char(maxV) char(39)];
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' & ' vName '.' cName ' < ' maxV ' | ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s & %s.%s < %s | ismissing(%s.%s),:);', DM,DM,DM,cName,minV,DM,cName,maxV,DM,cName)};
                    end
                end
            else
                if isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                    if isinteger(wsVar.Values)
                        % g1778901: Do not generated ~isMissing code for intergers since they have no missing.
                        filtCode = {[';']};
                        executionCode = {sprintf('tempDM = this.OrigData;')};
                    else
                         % Codegen for case: Exclude Missing Only
                        filtCode = {[vName ' = ' vName '(~ismissing(' vName '.' cName '),:);']};
                        executionCode = {sprintf('%s = %s(~ismissing(%s.%s),:);', DM,DM,DM,cName)};
                    end
                elseif isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.SelectedRangeMaxFullPrecision)
                    % Codegen for case: Min = Max and Exclude Missing
                    if ~isdatetime(minV)
                        if isduration(minV)
                            minV = [char(39) char(minV) char(39)];
                        else
                            minV = num2str(minV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' minV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s == %s,:);', DM,DM,DM,cName,minV)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' == ' minV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s == %s,:);', DM,DM,DM,cName,minV)};
                    end
                elseif isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && ~isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                     % Codegen for case: Max Val Changed and Exclude Missing
                    if ~isdatetime(maxV)
                        if isduration(maxV)
                            maxV = [char(39) char(maxV) char(39)];
                        else
                            maxV = num2str(maxV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' <= ' maxV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s <= %s,:);', DM,DM,DM,cName,maxV)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(maxV.Format);
                        maxV.Format = fmt;
                        maxV = dateshift(maxV, 'end', internal.matlab.variableeditor.peer.PeerDataUtils.getDatetimePrecisionFromFormat(maxV.Format));
                        maxV = [char(39) char(maxV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' < ' maxV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s < %s,:);', DM,DM,DM,cName,maxV)};
                    end
                elseif ~isequal(wsVar.SelectedRangeMinFullPrecision, wsVar.OriginalMinFullPrecision) && isequal(wsVar.SelectedRangeMaxFullPrecision, wsVar.OriginalMaxFullPrecision)
                     % Codegen for case: Min Val Changed and Exclude Missing
                    if ~isdatetime(minV)
                        if isduration(minV)
                            minV = [char(39) char(minV) char(39)];
                        else
                            minV = num2str(minV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s,:);', DM,DM,DM,cName,minV)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s,:);', DM,DM,DM,cName,minV)};
                    end
                else
                    % Codegen for case: Min and Max Val Changed and Exclude Missing
                    if (~isdatetime(minV) && ~isdatetime(maxV))
                        if isduration(minV) || isduration(maxV)
                            minV = [char(39) char(minV) char(39)];
                            maxV = [char(39) char(maxV) char(39)];
                        else
                            minV = num2str(minV);
                            maxV = num2str(maxV);
                        end
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' & ' vName '.' cName ' <= ' maxV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s & %s.%s <= %s,:);', DM,DM,DM,cName,minV,DM,cName,maxV)};
                    else
                        fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(minV.Format);
                        minV.Format = fmt;
                        maxV.Format = fmt;
                        maxV = dateshift(maxV, 'end', internal.matlab.variableeditor.peer.PeerDataUtils.getDatetimePrecisionFromFormat(maxV.Format));
                        maxV = [char(39) char(maxV) char(39)];
                        minV = [char(39) char(minV) char(39)];
                        filtCode = {[vName ' = ' vName '(' vName '.' cName ' >= ' minV ' & ' vName '.' cName ' < ' maxV ',:);']};
                        executionCode = {sprintf('%s = %s(%s.%s >= %s & %s.%s < %s,:);', DM,DM,DM,cName,minV,DM,cName,maxV)};
                    end
                end
            end
        end
        
        function UpdateActionState(this)
            this.Enabled = true;
        end
    end
end

