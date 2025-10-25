classdef TableAccordionData < controllib.widget.internal.accordiontable.CommonHTMLData
    % TableAccordionData is the main data source for building a accordion
    % table webpage
    properties
        % Name of the columns
        HeaderNames (1,:) string
        % Rendering of the columns (accepts text, numeric, and bool)
        RenderTypes (1,:) string {mustBeMember(RenderTypes,["bool","text","numeric"])}
        % Alignment of the columns (accepts left, center, and right)
        ColAlign    (1,:) string {mustBeMember(ColAlign,["left","center","right"])}
        % Initial width of each column specified as a string consistent
        % with the CSS "width" property
        ColWidth    (1,:) string
        % Array of AccordionData (see AccordionData class for more info)
        AccordionData  controllib.widget.internal.accordiontable.AccordionData
        % No content message when AccordionData is empty
        NoContentMsg string = "NO CONTENT"
    end
    properties (SetAccess = private)
        NumCols
        NumAccordions
    end
    methods
        function this = TableAccordionData(headerNames,accordData)
            this.NumCols = numel(headerNames);
            this.HeaderNames = headerNames;
            % make sure the # of cols in consistent with the number of
            % headers
            for ad = accordData(:)'
                if ad.RowDataSize(2) ~= this.NumCols
                    error(message('Controllib:widget:AccordionTableInconsistentCols',ad.RowDataSize(2),this.NumCols));
                end
            end
            this.NumAccordions = numel(accordData);
            this.AccordionData = accordData;
            
            this.RenderTypes(1:this.NumCols) = "text";
            this.ColAlign(1:this.NumCols)    = "center";
            this.ColWidth(1:this.NumCols)    = "auto";
            
            % auto determine render types based on first row of data
            if this.NumAccordions
                for colidx = 1:this.NumCols
                    val = getValueAt(this,1,1,colidx);
                    if isnumeric(val)
                        rtype = "numeric";
                    elseif islogical(val)
                        rtype = "bool";
                    else
                        rtype = "text";
                    end
                    this.RenderTypes(colidx) = rtype;
                end
            end
            % initialize the JS event structure
            this.JSEventData = struct();
        end
        function setAccordionTitle(this,aidx,val)
            arguments
                this (1,1)
                aidx
                val {mustBeTextScalar}
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx).AccordionTitle = val;
        end
        function setValueAt(this,aidx,ridx,cidx,val)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                cidx (1,1) {mustBePositive,mustBeInteger}
                val
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx) = setValueAt(this.AccordionData(aidx),ridx,cidx,val);
        end
        function val = getValueAt(this,aidx,ridx,cidx)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                cidx (1,1) {mustBePositive,mustBeInteger}
            end
            aidx = getAccordIdx(this,aidx);
            val = getValueAt(this.AccordionData(aidx),ridx,cidx);
        end
        function setValuesAtCol(this,cidx,val)
            arguments
                this (1,1)
                cidx (1,1) {mustBePositive,mustBeInteger}
                val  (1,1)
            end
            for aidx = 1:this.NumAccordions
                this.AccordionData(aidx) = setValuesAtCol(this.AccordionData(aidx),cidx,val);
            end
        end
        function setEditableAt(this,aidx,ridx,cidx,val)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                cidx (1,:) {mustBePositive,mustBeInteger}
                val  (1,1) logical
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx) = setEditableAt(this.AccordionData(aidx),ridx,cidx,val);
        end
        function setEditableAtCol(this,cidx,val)
            arguments
                this (1,1)
                cidx (1,:) {mustBePositive,mustBeInteger}
                val  
            end
            for aidx = 1:this.NumAccordions
                this.AccordionData(aidx) = setEditableAtCol(this.AccordionData(aidx),cidx,val);
            end
        end
        function setEnabledAt(this,aidx,ridx,cidx,val)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                cidx (1,:) {mustBePositive,mustBeInteger}
                val  (1,1) logical
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx) = setEnabledAt(this.AccordionData(aidx),ridx,cidx,val);
        end
        function setEnabledAtCol(this,cidx,val)
            arguments
                this (1,1)
                cidx (1,:) {mustBePositive,mustBeInteger}
                val  
            end
            for aidx = 1:this.NumAccordions
                this.AccordionData(aidx) = setEnabledAtCol(this.AccordionData(aidx),cidx,val);
            end
        end
        function setAccordionVisibility(this,aidx,val)
            arguments
                this (1,1)
                aidx
                val  (1,1) logical
            end
            aidx = getAccordIdx(this,aidx);
            [this.AccordionData(aidx).IsAccordionVisible] = deal(val);
        end
        function setAccordionCollapsed(this,aidx,val)
            arguments
                this (1,1)
                aidx
                val  (1,1) logical
            end
            aidx = getAccordIdx(this,aidx);
            [this.AccordionData(aidx).IsAccordionCollapsed] = deal(val);
        end
        function highlightCell(this,aidx,ridx,cidx,rgba)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                cidx (1,1) {mustBePositive,mustBeInteger}
                rgba       {localMustBeRGBAOrSemanticVar}
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx) = highlightCell(this.AccordionData(aidx),ridx,cidx,rgba);
        end
        function highlightRow(this,aidx,ridx,rgba)
            arguments
                this (1,1)
                aidx
                ridx (1,1) {mustBePositive,mustBeInteger}
                rgba       {localMustBeRGBAOrSemanticVar}
            end
            aidx = getAccordIdx(this,aidx);
            this.AccordionData(aidx) = highlightRow(this.AccordionData(aidx),ridx,rgba);
        end
    end
    methods (Access = private)
        function aidx = getAccordIdx(this,ain)
            if islogical(ain)
                aidx = find(ain);
            elseif isstring(ain) || ischar(ain)
                aidx = find(getAccordianIdx(this.AccordionData,name));
            else
                aidx = ain;
            end
        end
    end
end
function x = localMustBeRGBAOrSemanticVar(x)
if isnumeric(x)
    x = localMustBeRGBA(x);
else
    x = localMustBeSemanticVar(x);
end
end
function x = localMustBeRGBA(x)
arguments
    x (1,4) {mustBeNumeric,mustBeNonnegative}
end
end
function x = localMustBeSemanticVar(x)
arguments
    x (1,1) string
end
end