classdef VECopyAction < internal.matlab.variableeditor.VEAction
    % VECopyAction
    % Copies to clipboard from view's current selection for the
    % VariableEditor
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'VECopyAction'
        % ActionClass property is used by LE Packagers to load specific actions
        ActionClass = "internal.matlab.variableeditor.Actions.VECopyAction";
    end
    
    properties
        Manager;
    end
    
    methods
        function this = VECopyAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.VECopyAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.CopyToClipboard;
            this.Manager = manager;
            this.Enabled = true;
        end
        
        function CopyToClipboard(this, copyInfo)
            % g2631664: Disable the futher copy actions while one is
            % processing to prevent a potential slowdown.
            this.Enabled = false;

            idx = arrayfun(@(x) isequal(x.DocID, copyInfo.docID), this.Manager.Documents);
            doc = this.Manager.Documents(idx);
            vm = doc.ViewModel;

            selectedData = {};
            currentSelection = vm.getSelection();
            rows = currentSelection{1};
            % g3499743: The current column selection order can be reversed if the user selects from
            % right to left. This order is important for use with the Plot Gallery. To prevent
            % values being reversed during copying and pasting, we order the column selection range.
            cols = sortrows(currentSelection{2});
            colHeaders = [];
            rowHeaders = [];

            % If no row or column selection exists, nothing to paste to
            % clipboard
            if isempty(rows) || isempty(cols)
                return;
            end
            if istabular(vm.DataModel.Data)
                rowHeaders = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(vm.DataModel.Data);
                if ~isempty(rowHeaders)
                    % Column header name for row header will be the
                    % dimension name
                    colHeaders = string(vm.DataModel.Data.Properties.DimensionNames{1});
                end
            end
            isnumericView = isa(vm, 'internal.matlab.variableeditor.NumericArrayViewModel');
            numFormat = '';
            if isnumericView
                numFormat = internal.matlab.variableeditor.NumberDisplayFormatProvider.getCorrespondingLongFormat(vm.DisplayFormatProvider.NumDisplayFormat);
            end
            for i=1:height(rows)
                dRowRange = [];
                rowRange = rows(i,:);
                for j=1:height(cols)
                    colRange = cols(j,:);
                    if isnumericView
                        dColRange = vm.getDisplayData(rowRange(1), rowRange(2), colRange(1), colRange(2), numFormat);
                    else
                        dColRange = vm.getDisplayData(rowRange(1), rowRange(2), colRange(1), colRange(2));
                    end
                    dRowRange = [dRowRange  dColRange];
                    if i==1
                        headerNames = vm.getHeadersForRange(colRange(1), colRange(2));
                        % headerNames could be an array with multiple rows
                        % (including nested headers). if row dim name
                        % exists, match the heights before concatenation.
                        h = height(headerNames);
                        if h > 1 && ~isempty(colHeaders)
                            colHeaders(2:h,1) = "";
                        end
                        colHeaders = [colHeaders headerNames];
                        if ~isempty(colHeaders)
                            colHeaders(colHeaders(:,1)=="") = '-';
                        end
                    end
                end
                selectedData = [selectedData; dRowRange];
                if ~isempty(rowHeaders)
                    selectedData = [rowHeaders(rowRange(1):rowRange(2)) selectedData];
                end
            end
            selectedData = [colHeaders; selectedData];

            strData = arrayfun(@(x) sprintf('%s\t', selectedData{x,:}), [1:height(selectedData)], 'UniformOutput', false);
            strData = strjoin(strtrim(strData), '\n');
            clipboard('copy', strData);

            % Re-enable new copy action once it is finished 
            this.Enabled = true;
        end      
        
         function  UpdateActionState(~)
        end
    end 
end

