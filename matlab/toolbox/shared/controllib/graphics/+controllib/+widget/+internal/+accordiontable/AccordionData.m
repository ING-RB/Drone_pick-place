classdef AccordionData
    properties
        % Name/ID of the accordion
        Name string
        % Title of the accordion. Will get its own row in the table
        AccordionTitle string
        % Logical array for the accordion. Control cell editability (does
        % not change style in the table)
        Editable logical
        % Logical array for the accordion. Enables cells (style is changed
        % if disabled)
        Enabled  logical
        % Background color for each cell specified in RGBA format
        BackgroundColor (:,:,4)
        % Background color semantic variable
        BackgroundColorSemanticVariable string
        % Render the accordion label as hyperlink
        RenderTitleAsHyperlink (1,1) logical
        % Is accordion visible
        IsAccordionVisible (1,1) logical
        % Is accordion collapsed.
        % Note, this property is kept in sync with the UI when attached to
        % an AccordionTable
        IsAccordionCollapsed (1,1) logical
    end
    properties (SetAccess = private)
        % Cell of cells. Each inner cell represents the data for a row
        RowData cell
        % size of the data [numrows x numcol]
        RowDataSize
    end
    methods
        function this = AccordionData(name,title,rowData)
            arguments
                name string
                title string
                rowData cell
            end

            % install name, title and data
            this.Name = name;
            this.AccordionTitle = title;
            % cell props will be initialized via set method
            this = setRowData(this,rowData);
            
            this.RenderTitleAsHyperlink = true;
            this.IsAccordionVisible = true;
            this.IsAccordionCollapsed = false;
        end
        function this = setRowData(this,rowData)
            this = setRowData_(this,rowData);
        end
        function idx = getAccordianIdx(this,name)
            names = [this.Name];
            idx = ismember(names,name);
        end
        function this = setValueAt(this,ridx,cidx,val)
            % set the value of a cell given rows and cols
            this.RowData{ridx}{cidx} = val;
        end
        function val = getValueAt(this,ridx,cidx)
            val = this.RowData{ridx}{cidx};
        end
        function this = setValuesAtCol(this,cidx,val)
            for ridx = 1:this.RowDataSize(1)
                this = setValueAt(this,ridx,cidx,val);
            end
        end
        function this = setEditableAtCol(this,cidx,val)
            for ridx = 1:this.RowDataSize(1)
                this = setEditableAt(this,ridx,cidx,val);
            end
        end
        function this = setEditableAt(this,ridx,cidx,val)
            % set the editability of a cell given rows and cols
            this.Editable(ridx,cidx) = val;
        end
        function this = setEnabledAt(this,ridx,cidx,val)
            % set the cell as enabled given rows and cols
            this.Enabled(ridx,cidx) = val;
        end
        function this = setEnabledAtCol(this,cidx,val)
            for ridx = 1:this.RowDataSize(1)
                this = setEnabledAt(this,ridx,cidx,val);
            end
        end
        function this = highlightCell(this,row,col,rgba)
            % higlight a cells given a row and columns
            if isnumeric(rgba)
                this.BackgroundColor(row,col,:) = rgba;
            else
                this.BackgroundColorSemanticVariable(row,col) = rgba;
            end
        end
        function this = highlightRow(this,r,rgba)
            % highlight all cells in a row
            for i = 1:this.RowDataSize(2)
                this = highlightCell(this,r,i,rgba);
            end
        end
    end
    methods (Access = private)
        function this = setRowData_(this,rowData)
            % rowData as input is supported in 2 forms:
            % 1. cell vector of cells (each outer cell represents a row)
            % 2. numrow x numcol cell array
            %
            % format 2 will be converted to format 1 internally to
            % facilitate serialization to JS
            
            if isempty(rowData)
                rowData = {{}};
            else
                if ~iscell(rowData{1})
                    for j = size(rowData,1):-1:1
                        temp{j} = rowData(j,:);
                    end
                    rowData = temp;
                end
            end
            
            this.RowData = rowData;
            nr = numel(rowData);
            if nr
                nc = numel(rowData{1});
            else
                nc = 0;
            end
            sz = [nr,nc];
            for i = 1:nr
                if nc ~= numel(rowData{i})
                    error(message('Controllib:widget:AccordionDataInconsistentCols'));
                end
            end
            
            % reset cell props if data size has changed
            if ~isequal(this.RowDataSize,sz)
            
                this.RowDataSize = sz;
                this.Editable  = true(sz);
                this.Enabled   = true(sz);
                bgcolor        = ones([sz,4])*255;
                bgcolor(:,:,4) = 1.0;
                this.BackgroundColor = bgcolor;

                this.BackgroundColorSemanticVariable = repmat(...
                    "",sz);
            end
        end
    end
end