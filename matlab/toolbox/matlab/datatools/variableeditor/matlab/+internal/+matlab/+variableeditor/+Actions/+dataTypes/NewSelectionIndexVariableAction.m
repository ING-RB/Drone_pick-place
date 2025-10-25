classdef NewSelectionIndexVariableAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles creation of a new logical variable from the
    % selected indices
    % Copyright 2022-2023 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'NewSelectionIndexVariable'
        NewVariableName = "matchedIndices"
    end
    
    methods
        function this = NewSelectionIndexVariableAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.NewSelectionIndexVariableAction.ActionName;           
            props.Enabled = true; 
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end

        function toggleEnabledState(this, isEnabled)
            if isEnabled
                focusedDoc = this.Manager.FocusedDocument;
                isEnabled = ~islogical(focusedDoc.DataModel.Data);
            end
            this.Enabled = isEnabled;
        end
    end
    
    methods(Access='protected')
        % Generates command for generating new variables from the current
        % selection. For SeperateWorkspaceVariable, we need to loop into
        % current column selection range to generate individual column
        % variables.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            focusedView = focusedDoc.ViewModel;
            % use getSelectionIndices to fetch selection. For
            % timetables/tables, this returns offset indices
            selection = focusedView.getSelectionIndices();

            executionCmd = '';
            sz = focusedView.getTabularDataSize();
            if istabular(focusedView.DataModel.Data)
                % For tabular types, getTabularDataSize returns the flattened size. For row vetcor with selection indices, we
                % want unflattened size so that this logical vector can be used for logical indexing within the table.
                sz = size(focusedView.DataModel.getCloneData);
            end
            [rowRange, colRange] = this.getNumericSelectionRange(selection, sz);
            cmd = '';
            varnames = evalin('debug', 'who');
            if strcmp(actionInfo.menuID, 'SeparateMatrixVariable')
                newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(this.NewVariableName,  varnames);
                cmd = sprintf('%s = false(%d,%d); %s(%s,%s) = true;', newVarName, sz(1), sz(2),newVarName,rowRange,colRange);
                executionCmd = sprintf('openvar("%s"); ', newVarName);
            elseif strcmp(actionInfo.menuID, 'NewLogicalRow')
                newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(this.NewVariableName,  varnames);
                cmd = sprintf('%s = false(%d,1);', newVarName, sz(1));
                if ~isempty(rowRange)
                    % We don't have any current use cases where rowRange
                    % can be empty, but just in case we'll guard against it
                    cmd = sprintf('%s %s(%s) = true;', cmd, newVarName, rowRange);
                end
                executionCmd = sprintf('openvar("%s"); ', newVarName);
            elseif strcmp(actionInfo.menuID, 'NewLogicalColumn')
                newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(this.NewVariableName,  varnames);
                cmd = sprintf('%s = false(1,%d);', newVarName, sz(2));
                if ~isempty(colRange)
                    % Empty rnge can happen in a TimeTable if only the time
                    % column is selected g3553210
                    cmd = sprintf('%s %s(%s) = true;', cmd, newVarName, colRange);
                end
                executionCmd = sprintf('openvar("%s"); ', newVarName);
            elseif strcmp(actionInfo.menuID, 'NewColumnVariable')
                if isa(focusedView.DataModel.Data, 'dataset')
                    varnames = focusedView.DataModel.Data.Properties.VarNames;
                else
                    varnames = focusedView.DataModel.Data.Properties.VariableNames;
                end
                newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(this.NewVariableName,  varnames);
                if isa(focusedView.DataModel.Data, 'dataset')
                    cmd = sprintf('%s.%s = false(%d,1); %s.%s(%s) = true', focusedDoc.Name, newVarName, sz(1), focusedDoc.Name, newVarName, rowRange);
                else
                    cmd = sprintf('%s.%s(%s) = true;', focusedDoc.Name,newVarName, rowRange);
                end
            end            
        end     
    end
end


