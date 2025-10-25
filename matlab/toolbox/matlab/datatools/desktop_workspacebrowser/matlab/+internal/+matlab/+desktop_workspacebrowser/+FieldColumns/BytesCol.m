classdef BytesCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Bytes" Column display for workspacebrowser view

    % Copyright 2020-2024 The MathWorks, Inc.   
    
    properties
        Workspace = 'debug';
    end
    
    methods
        function this = BytesCol()            
            this.HeaderName = "Bytes";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Bytes'));
            this.Editable = false;
            this.Sortable = true;
            this.Visible_I = false;
            this.ColumnIndex_I = 13;            
        end
        
        function viewData = getData(this, startRow, endRow, data, fieldNames, ~, ~, formatOutput, dataTruncated, fieldNameIds)
            arguments
                this
                startRow
                endRow
                data
                fieldNames
                ~ % virtualProps
                ~ % origData
                formatOutput logical = true
                dataTruncated logical = false
                fieldNameIds = fieldNames
            end

            % Adjust for truncated columns like the other column classes do
            if dataTruncated
                rows = 1:length(data);
            else
                rows = startRow:endRow;
            end

            viewData = cell(length(rows), 1);
            % Determine the view type based on the equality of fieldNameIds 
            % and fieldNames. If they differ, the view is assumed to be a 
            % tree table view
            if ~isequal(fieldNameIds, fieldNames)
                fnames = internal.matlab.datatoolsservices.FormatDataUtils.extractFieldsAfterWorkspaceName(fieldNameIds(rows));
            else
                fnames = fieldNames(rows);
            end

            w = evalin(this.Workspace, "whos('" + strjoin(fnames, "','") + "')");
            for i=1:length(w)
                metadata = w(i);
                idx = find(strcmp(fnames, metadata.name));
                if ~isempty(idx)
                    if formatOutput
                        viewData{idx} = string(metadata.bytes);                 
                    else
                        viewData{idx} = metadata.bytes;                 
                    end
                end
            end
        end
        
        % Returns the sorted indices w.r.t order of fields in the struct.
        % Get the unformatted stat data and sort them.
        function sortIndices = getSortedIndices(this, data, fieldnames, virtualProps, origData)
            viewData = this.getData(1, length(data), data, fieldnames, virtualProps, origData, false);
            if this.SortAscending
                [~,sortIndices] = sortrows(viewData, 1);
            else
                [~,sortIndices] = sortrows(viewData, -1);
            end
        end
    end
end