classdef SelectAllAction < internal.matlab.variableeditor.VEAction 
    % SELECTALLACTION Selects the entire view for the current variable.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'VariableEditor.select-all'
    end

    methods
        % Selects all the variables in current variable
        function this = SelectAllAction(props, manager)
            if ~isfield(props, 'ID')              
                props.ID = internal.matlab.variableeditor.Actions.struct.SelectAllAction.ActionType;
            end            
            if ~isfield(props, 'Enabled')              
                props.Enabled = true;
            end        
            this@internal.matlab.variableeditor.VEAction(props, manager);            
            this.Callback = @this.selectAll;
        end
         
        function UpdateActionState(~)           
        end        
    end
    
    methods(Access='protected')
        % Handles SelectAll and InvertSelection for all the ViewModels.
         function selectAll(this, actionInfo)
             arguments
                 this;
                 actionInfo = struct;
             end
             focusedDoc = this.veManager.FocusedDocument;
             
             if ~isempty(focusedDoc)
                 menuID = 'SelectAll';
                 if isfield(actionInfo, 'menuID')
                     menuID = actionInfo.menuID;
                 end
                 dataSize = focusedDoc.ViewModel.getTabularDataSize;
                 if strcmp(menuID, 'SelectAll')
                     % Set src to client as the action was triggered from
                     % the client.
                     endRow = dataSize(1);
                     endColumn = dataSize(2);
                     % On select all, set selection upto grid size
                     % (including Infinite grid) and not only up to
                     % datasize.
                     gridSize = focusedDoc.ViewModel.getProperty("GridSize");
                     if ~isempty(gridSize)
                         endRow = max(endRow, gridSize(1));
                         endColumn = max(endColumn, gridSize(2));
                     end
                     focusedDoc.ViewModel.setSelection([1, endRow],[1, endColumn], 'action');
                 elseif strcmp(menuID, 'InvertSelection')
                     s = focusedDoc.ViewModel.getSelection();
                     sRow = s{1};
                     sCol = s{2};
                     if (sRow(1) == 1 && sRow(2) == dataSize(1) && sCol(1)==1 && sCol(2) == dataSize(2))
                        focusedDoc.ViewModel.setSelection([], []);
                        return;
                     end                     
                     rowIdx = internal.matlab.variableeditor.BlockSelectionModel.getInvertedSelectionIntervals(sRow, focusedDoc.DataModel.Data, 'rows', dataSize(1), dataSize);
                     % For structViewModels, all columns are selected by default.
                     if (isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureViewModel') || ...
                             isa(focusedDoc.ViewModel, 'internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel'))
                        colIdx = [1 dataSize(2)];
                     else
                        colIdx = internal.matlab.variableeditor.BlockSelectionModel.getInvertedSelectionIntervals(sCol, focusedDoc.DataModel.Data, 'columns', dataSize(2), dataSize);
                     end
                     focusedDoc.ViewModel.setSelection(rowIdx, colIdx, 'action');
                 end
             end
         end
    end
end

