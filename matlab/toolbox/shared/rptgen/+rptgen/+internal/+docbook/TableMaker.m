classdef TableMaker < handle
    %TABLEMAKER Generate a CALS table 
    %    tm = TableMaker(doc) creates an object that generates the DocBook
    %    table specified by its properties.
    %    tm = TableMaker(doc, colWidths) creates a table with the column
    %    widths specified by the colWidths string array.
    %
    %    TableMaker properties:
    %      OwnerDoc     - MAXP Document object
    %      TableContent - MxN array of CALSEntry objects
    %      NumCols      - Number of table columns
    %      ColWidths    - String array of column widths
    %      TableTitle   - TableTitle specified as a MAXP Node 
    %      GroupAlign   - Horizontal table group alignment
    %      Border       - Whether table has a border
    %      PgWide       - Whether table spans width of page
    %      NumHeadRows  - Number of table header rows
    %      NumFootRows  - Number of table footer rows
    %      ForceHTML    - Create table using HTML markup
    %      CurrentTable - Table element created by this table maker
    %      CurrentGroup - Table group element created by this table maker
    %      CurrentHead  - Header of table created by this table maker
    %      CurrentBody  - Body of table created by this table maker
    %      CurrentFoot  - Footer of table created by this table maker
    %
    %    TableMaker methods:
    %      getContent            - Get TableContent property
    %      setContent            - Set TableContent property
    %      getBorder             - Get Border property
    %      setBorder             - Set Border property
    %      getColWidths          - Get ColWidths property
    %      setColWidths          - Set ColWidths property
    %      getGroupAlign         - Get GroupAlign property
    %      setGroupAlign         - Set GroupAlign property
    %      getNumCols            - Get NumCols property
    %      setNumCols            - Set NumCols property
    %      getPageWide           - Get PgWide property
    %      setPageWide           - Set PgWide property
    %      getTitle              - Get Title property
    %      setTitle              - Get Title property
    %      createTable           - Create table specified by TM props
    %      applyStyleCenterAlign - Apply center align table style
    %      applyStyleSingleRule  - Apply single rule table style
    %      forceHtmlTable        - Force HTML table creation
    %
    %    See also rptgen.internal.docbook.CALSEntry
    
    
    % Copyright 2020 Mathworks, Inc.
    
    properties
        
        % OwnerDoc MAXP document used to create table
        %   The value of this property is an matlab.io.xml.dom.Document
        %   object
        OwnerDoc {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(OwnerDoc, ...
            'matlab.io.xml.dom.Document')} = [] 
        
        % TableContent Content of table
        %   An RxC array of rptgen.internal.docbook.CALSEntry object
        %   that specifies the table entries of a table's header, body,
        %   and footer sections.
        TableContent (:,:) {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(TableContent, ...
            'rptgen.internal.docbook.CALSEntry')} = []
        
        % NumCols Number of columns in the table to be made
        NumCols double = 1
        
        % ColWidths Widths of the columns of the table to be made
        %   The value of this property is a 1xC of strings that specify
        %   the table widths.
        ColWidths (1,:) {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ColWidths,'string')} = []
        
        % TableTitle Title of table to be made
        %   The value of this property is an matlab.io.xml.dom.Node
        %   object.
        TableTitle {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(TableTitle,'matlab.io.xml.dom.Node')} = []
        
        % GroupAlign Alignment of table entries
        %   The value of this property is a string that specifies the
        %   alignment of the tables entries. Valid values are:
        %     
        %     "left" (default)
        %     "center"
        %     "right"
        %     "justify"
        %     "char"
        %
        %   See also https://tdg.docbook.org/tdg/4.5/tgroup.html
        GroupAlign string = "left"
        
        % Border Whether table to be made should have a border
        %   Value of this property is a logical. True (default) specifies
        %   that table should have a border.
        Border logical = true
        
        % PgWide Whethr the table to be made should span page.
        %   The value of this property is a logical. True (default)
        %   specifies that the table should span the page between the
        %   margins.
        PgWide logical = true
        
        % NumHeadRows Number of rows in the header of the table to be made
        %   The value of this property is a double. The default value is 1.
        NumHeadRows double = 1
        
        % NumFootRows Number of footer rows in table
        %   The value of this property is a double. The default value is 0.
        NumFootRows double = 0
        
        % ForceHTML Use HTML instead of DocBook markup to generate table
        %   The value of this variable is a logical. False (the default)
        %   specifies use of DocBook markup. HTML markup avoids the need
        %   to convert from DocBook to HTML markup and hence can be faster
        %   for large tables.
        ForceHTML logical  = false
        
        % CurrentTable Table generated by this TableMaker
        %   The value of this property is a matlab.io.xml.dom.Element
        %   object containing the table.
        CurrentTable {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrentTable, ...
            'matlab.io.xml.dom.Element')} = []
        
        % CurrentGroup Table group generated by this TableMaker
        %   The value of this property is a matlab.io.xml.dom.Element
        %   object that contains the head, body, and foot sections of
        %   this table.
        CurrentGroup {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrentGroup, ...
            'matlab.io.xml.dom.Element')} = []
        
        % CurrentHead Head of table generated by this TableMaker
        %   The value of this property is a matlab.io.xml.dom.Element
        %   object containing the header section of the table generated
        %   by this TableMaker.
        CurrentHead  {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrentHead, ...
            'matlab.io.xml.dom.Element')} = []
        
        % CurrentBody Body of table generated by this TableMaker
        %   The value of this property is a matlab.io.xml.dom.Element
        %   object containing the body of the table generated by this
        %   TableMaker.
        CurrentBody {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrentBody, ...
            'matlab.io.xml.dom.Element')} = []
        
        % CurrentFoot Foot of table generated by this TableMaker
        %   The value of this property is a matlab.io.xml.dom.Element
        %   object containing the footer section of the table generated
        %   by this TableMaker.
        CurrentFoot {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrentFoot, ...
            'matlab.io.xml.dom.Element')} = []
    end
    
    methods (Static, Access=private)

        %  A switch to enable/disable html override
        function v = ForcedHTMLEnabled(varargin) 
            persistent ForcedHTMLEnabled
            
            if isempty(ForcedHTMLEnabled)
                ForcedHTMLEnabled = true;
            end    
            
            if nargin > 0
                ForcedHTMLEnabled = varargin{1};
            end
            
            v = ForcedHTMLEnabled;
        end
        
    end
    
    methods (Static)
        function enableHtmlTable(tf)
            import rptgen.internal.docbook.TableMaker
            TableMaker.ForcedHTMLEnabled(tf);
        end
    end
    
    methods
        function forceHtmlTable(obj,tf)
            %forceHtmlTable Use HTML markup to generate table
            %  forceHtmlTable(tm,tf) specifies whether to use HTML
            %  markup instead of DocBook to generate a table. If the tf
            %  argument is true, the TableMaker uses HTML markup. This
            %  can shorten the time required to generate tables in an 
            %  HTML report.
            %
            %  Note: this option should only be used to generate tables
            %  to be included in an HTML report.
            import rptgen.internal.docbook.TableMaker
            if TableMaker.ForcedHTMLEnabled
                obj.ForceHTML = tf;
            else
                obj.ForceHTML = false;
            end
        end
    end
    
    methods
        function obj = TableMaker(ownerDoc, colWidths)
            obj.OwnerDoc = ownerDoc;
            if nargin == 2
                setColWidths(obj,colWidths);
            end
        end
        
        function entries = getContent(obj)
            %getContent Get the content of the table to be made
            %  entries = getContent(tm) returns a RxC array of CALSEntry
            %  objects containing the content of the header, body, and
            %  footer sections of this table.
            %
            %  See also rptgen.internal.docbook.CALSEntry
            entries = obj.TableContent;
        end
        
        function setContent(obj,content)
            %setContent Specify the content of the table to be made.
            %  setContent(tm,entries) sets the content of the table to be
            %  made. Entries can be
            %    * CALSEntry object
            %    * RxC array of strings
            %    * RxC cell array of
            %       * CALSEntry objects
            %       * char arrays
            %       * strings
            %       * matlab.io.xml.dom.Node objects
            %
            %  See also rptgen.internal.docbook.CALSEntry 
            import rptgen.internal.docbook.*
            if ~isempty(content)
                if isa(content,'rptgen.internal.docbook.CALSEntry')
                    %setContent(obj,CALSEntry)
                    obj.TableContent = content;
                else
                    nEntries = numel(content);
                    obj.TableContent = rptgen.internal.docbook.CALSEntry.empty(nEntries,0);
                    for i = 1:nEntries
                        obj.TableContent(i,1) = rptgen.internal.docbook.CALSEntry;
                    end
                    switch class(content)
                        case 'string'
                            % setContent(obj,["a","b"])
                            for i = 1:nEntries
                                init(obj.TableContent(i,1),obj.OwnerDoc,content(i));
                            end
                        case 'cell'
                            for i = 1:nEntries
                                c = content{i};
                                if isa(c,'rptgen.internal.docbook.CALSEntry')
                                    % setContent(obj, {CALSEntry1, CALSEntry2})
                                    obj.TableContent(i,1) = c;
                                else
                                    % setContent(obj, {'a','b'})
                                    % setContent(obj, {"a","b"})
                                    % setContent(obj, {domnode1, domnode2});
                                    init(obj.TableContent(i,1),obj.OwnerDoc,c);
                                end
                            end
                    end
                end
            end
        end
              
        function setNumCols(obj,numCols)
            %setNumCols Set number of colums in table to be made
            %  setNumCols(tm,numCols) specifies number of columns in 
            %  table to be made.
            obj.NumCols = numCols;
            obj.ColWidths = "";
        end
        
        function numCols  =  getNumCols(obj)
            %getNumCols Set number of colums in table to be made
            %  n = getNumCols(tm) returns number of columns in 
            %  table to be made.
            numCols = obj.NumCols;
        end
          
        function title = getTitle(obj)
            %getTitle Get title of table to be made
            %  titleNode = getTitle(tm) returns an
            %  matlab.io.xml.dom.Node object specifying title of table
            %  to be made
            title = obj.TableTitle;
        end
        
        function setTitle(obj,title)
            %setTitle set title of table to be made
            %  setTitle(tm,title) specifies the title of the table to be
            %  made. The title argument must be a character array, a
            %  string, or a matlab.io.xml.dom.Node object.
            if isempty(title)
                obj.TableTitle = [];
            else
                if isa(title,'matlab.io.xml.dom.Node')
                    node = title;
                else
                    node = createTextNode(obj.OwnerDoc,title);
                end
                obj.TableTitle = node;
            end
        end

        
        function setBorder(obj,isBorder)
            obj.Border = isBorder;
        end
        
        function border = getBorder(obj)
            border = obj.Border;
        end
        
        function setPageWide(obj,isPgWide)
            obj.PgWide = isPgWide;
        end
        
        function tf = getPageWide(obj)
            tf = obj.PgWide;
        end
        
        function setNumHeadRows(obj,nhr)
            obj.NumHeadRows = nhr;
        end
        
        function nhr = getNumHeadRows(obj)
            nhr = obj.NumHeadRows;
        end
        
        function setNumFootRows(obj,nfr)
            obj.NumFootRows = nfr;
        end
        
        function nfr =  getNumFootRows(obj)
            nfr = obj.NumFootRows;
        end
        
        function setGroupAlign(obj,ga)
            obj.GroupAlign = ga;
        end
        
        function ga = getGroupAlign(obj)
            ga = obj.GroupAlign;
        end
        
        
        function setColWidths(obj,cWid)
            % Set column widths with point sizes. cWid is an integer array.
            nColWidths = numel(cWid);
            obj.ColWidths = strings(1,nColWidths);
            for i = 1:nColWidths
                %Zero or (god forbid) negative width columns are not allowed
                % Multiply column width by 60.  This used to be 1000 but this prevented page width = false from working.
                % Mozilla and IE seem to calculate column width differently.
                % Both use some mixing of the content width and the requested relative width.
                % Mozilla seems to do the right thing and use the content width only to prevent collapse beyond a minimum.
                % IE seems to blend the content width and the requested width.
                % To fix this, we merely have to make the requested with dwarf the content width.
                obj.ColWidths(i) = string(num2str(max(cWid(i)*60,1)));
            end
            obj.NumCols = nColWidths;
        end
        
        
        function setColWidthsPercent(obj,cWid)
            % Set column widths with percentages. cWid is an array of doubles.
            nColWidths = numel(cWid);
            obj.ColWidths(nColWidths) = string;
            sumWid = 0;
            for i=1:nColWidths
                sumWid = sumWid + max(cWid(i),0.01);
            end
            
            for i=1:nColWidths
                obj.ColWidths(i) =  ...
                    string(num2str(round(max(cWid(i),0.01)/sumWid))) + "%";
            end
            obj.NumCols = nColWidths;
        end
        
        function colWidths = getColWidths(obj)
            colWidths = obj.ColWidths;
        end
        
        function table = createTable(obj)
            %createTable Create a table
            %  table = createTable(obj) creates the table specified by
            %  where obj is a TableMaker object. This method returns 
            %  a table element containing the table.
            if isempty(obj.TableContent)
                table = createComment(obj.OwnerDoc,"Table contains no content");
                return
            end
            
            if obj.ForceHTML
                table = createHTMLTable(obj);
                return
            end
            
            if isempty(obj.TableTitle)
                obj.CurrentTable = createElement(obj.OwnerDoc,"informaltable");
            else
                obj.CurrentTable = createElement(obj.OwnerDoc,"table");
                titleTag = createElement(obj.OwnerDoc,"title");
                appendChild(obj.CurrentTable,titleTag);
                appendChild(titleTag,obj.TableTitle);
            end
            
            if obj.Border
                setAttribute(obj.CurrentTable,"frame","all");
                setAttribute(obj.CurrentTable,"colsep","1");
                setAttribute(obj.CurrentTable,"rowsep","1");
            else
                setAttribute(obj.CurrentTable,"frame","none");
                setAttribute(obj.CurrentTable,"colsep","0");
                setAttribute(obj.CurrentTable,"rowsep","0");
            end
            
            if obj.PgWide
                setAttribute(obj.CurrentTable,"pgwide","1");
            else
                setAttribute(obj.CurrentTable,"pgwide","0");
            end
            
            obj.CurrentGroup = createElement(obj.OwnerDoc,"tgroup");
            setAttribute(obj.CurrentGroup,"cols",num2str(obj.NumCols));
            
            %NOTE: CALS tables use "align" as the default horizontal alignment
            %of the table.  HTML uses "align" to decide how to lay the table out
            %relative to previous tables and images.  In stylesheets v1.36,
            %Norm is using the CALS align meaning in HTML, resulting in strange
            %cascaded tables in the output.  This was fixed for v1.64.
            setAttribute(obj.CurrentGroup,"align",obj.GroupAlign);
            appendChild(obj.CurrentTable,obj.CurrentGroup);
            
            for i = 1:obj.NumCols
                colspecTag = createElement(obj.OwnerDoc,"colspec");
                colNum = num2str(i);
                setAttribute(colspecTag,"colnum",colNum);
                setAttribute(colspecTag,"colname",colNum);
                
                cWid = "1";
                if ~isempty(obj.ColWidths) && i <= numel(obj.ColWidths)
                    cWid = obj.ColWidths(i);
                end
                setAttribute(colspecTag,"colwidth",cWid + "*");
                appendChild(obj.CurrentGroup,colspecTag);
            end
            
            %Note that row and column numbering is 1-based here
            colNum = obj.NumCols+1;
            rowNum = 0;
            numRows = round(numel(obj.TableContent)/obj.NumCols); %integer division rounds up, right?
            
            if obj.NumHeadRows > 0
                headRowBegin = 1;
            else
                headRowBegin = 0;
            end
            
            if numRows > obj.NumHeadRows + obj.NumFootRows
                bodyRowBegin = obj.NumHeadRows+1;
            else
                bodyRowBegin = -2;
            end
            
            footRowBegin = numRows +1 - obj.NumFootRows;
            
            subGroupTag = [];
            rowTag = [];
            
            nEntries = numel(obj.TableContent);
            for i = 1:nEntries
                if colNum > obj.NumCols
                    colNum=1;
                    rowNum = rowNum + 1;
                    
                    if rowNum == headRowBegin
                        obj.CurrentHead = createElement(obj.OwnerDoc,"thead");
                        subGroupTag = obj.CurrentHead;
                    elseif rowNum == bodyRowBegin
                        obj.CurrentBody = createElement(obj.OwnerDoc,"tbody");
                        subGroupTag = obj.CurrentBody;
                    elseif rowNum == footRowBegin
                        obj.CurrentFoot = createElement(obj.OwnerDoc,"tfoot");
                        subGroupTag = obj.CurrentFoot;
                    end
                    
                    rowTag = createElement(obj.OwnerDoc,"row");
                    appendChild(subGroupTag,rowTag);
                end
                
                % An empty CALSEntry object is an object that has no
                % MAXP implementation.
                entryImpl = getImpl(obj.TableContent(i));
                if ~isempty(entryImpl)
                    %It is OK for TableContent to be null.  The TableContent may
                    %simply be a placeholder for a nonexistent cell which is
                    %masked by another row or column spanning cell
                    appendChild(rowTag,entryImpl);
                end
                
                colNum = colNum + 1; %could check entry width to allow row spanning
            end
            
            % tgroup expects children in the order: head, foot, body **/
            if ~isempty(obj.CurrentHead)
                appendChild(obj.CurrentGroup,obj.CurrentHead);
            end
            
            if ~isempty(obj.CurrentFoot)
                appendChild(obj.CurrentGroup,obj.CurrentFoot);
            end
            
            if ~isempty(obj.CurrentBody)
                appendChild(obj.CurrentGroup,obj.CurrentBody);
            end
            
            table = obj.CurrentTable;
        end
        
        function applyStyleCenterAlign(obj)
            % Makes a two-column table centered around its middle
            % (left column is right-aligned and the right column is left-aligned)
            nEntries = numel(obj.TableContent);
            for i = 1:nEntries
                j = i;
                currEntry = obj.TableContent(j);
                if ~isempty(currEntry)
                    setAlign(currEntry,currEntry.ALIGN_RIGHT);
                    j = j+1;
                    if j <= nEntries
                        currEntry = obj.TableContent(j);
                        setAlign(currEntry,currEntry.ALIGN_LEFT);
                    end
                end
            end
        end
        
        function applyStyleSingleRule(obj)
            % Makes a table have no border and no internal rules
            % but a single rule below the header.
            %
            % Should there also be a single rule above the footer?
            %/
            setBorder(obj,false);
            if obj.NumHeadRows > 0
                nCols = numel(obj.ColWidths);
                startEntryIdx = ((obj.NumHeadRows-1) * nCols) + 1;
                endEntryIdx = obj.NumHeadRows * nCols;
                for i = startEntryIdx:endEntryIdx
                    if ~isempty(obj.TableContent(i))
                        setColsep(obj.TableContent(i),false);
                        setRowsep(obj.TableContent(i),true);
                    end
                end
            end
        end
        
    end
    
    methods (Access=private)
        
        function table = createHTMLTable(obj)
            %  A 'replacement' method for createTable.
            %  To avoid sluggishness from the XSLT processor with large 
            %  HTML tables, createHTMLTable is called in its stead
            %  whenever the fForceHTML flag has been set
            
            %  Embed the title in its own table-spanning row
            if ~isempty(obj.TableTitle)
                obj.CurrentTable = createElement(obj.OwnerDoc,"table");
                titleCell = createElement(obj.OwnerDoc,"caption");
                appendChild(titleCell,obj.TableTitle);
                appendChild(obj.CurrentTable,titleCell);
            else
                obj.CurrentTable = createElement(obj.OwnerDoc,"informaltable");
            end
            
            %  Set an attribute flag to indicate to help build XSLT filters
            setAttribute(obj.CurrentTable,"fastRender", "1");
            
            if obj.Border == true
                border = "1";
            else
                border = "0";
            end
            setAttribute(obj.CurrentTable,"border",border);
            setAttribute(obj.CurrentTable,"cellspacing", "0");
            
            if obj.PgWide
                setAttribute(obj.CurrentTable,"width","100%");
            end
            
            %  Build numeric col widths
            
            sumOfColWidths = 0;
            numericColWidths = zeros(1,obj.NumCols);
            nColWidths = numel(obj.ColWidths);
            for i=1:obj.NumCols
                if ~isempty(obj.ColWidths) && i <= nColWidths
                    colwidth = obj.ColWidths(i);
                    if strlength(colwidth) > 0
                        numericColWidths(i) = str2double(colwidth);
                    else
                        numericColWidths(i) = 1;
                    end
                else
                    numericColWidths(i) = 1;
                end
                sumOfColWidths = sumOfColWidths + numericColWidths(i);
            end
            
            n = obj.NumCols - 1;
            for i = 0:n
                colTag = createElement(obj.OwnerDoc,"col");
                iStr = num2str(i);
                setAttribute(colTag,"colnum",iStr);
                setAttribute(colTag,"colname",iStr);
                setAttribute(colTag,"width", ...
                    string(num2str(numericColWidths(i+1)/sumOfColWidths*100)) + "%");
                appendChild(obj.CurrentTable,colTag);
            end
            
            numRows = numel(obj.TableContent) / obj.NumCols;
            
            %  Create a header, footer and body section as needed
            if obj.NumHeadRows > 0
                obj.CurrentHead = createElement(obj.OwnerDoc,"thead");
                appendChild(obj.CurrentTable,obj.CurrentHead);
            end
            
            if numRows > obj.NumHeadRows + obj.NumFootRows
                obj.CurrentBody = createElement(obj.OwnerDoc,"tbody");
                appendChild(obj.CurrentTable,obj.CurrentBody);
            end
            
            if obj.NumFootRows > 0
                obj.CurrentFoot = createElement(obj.OwnerDoc,"tfoot");
                appendChild(obj.CurrentTable,obj.CurrentFoot);
            end
            
            %  Create each row...
            nRows = numRows-1;
            for i = 0:nRows
                curRow = createElement(obj.OwnerDoc,"tr");
                
                %  If we're writing the header section
                if i < obj.NumHeadRows
                    appendChild(obj.CurrentHead,curRow);
                    %  If we're writing the footer section
                elseif i > numRows - obj.NumFootRows - 1
                    appendChild(obj.CurrentFoot,curRow);
                    %  If we're writing the body section
                else
                    appendChild(obj.CurrentBody,curRow);
                end
                
                %  Create a cell for every column in the row
                for j = 1:obj.NumCols
                    curContentItem = obj.TableContent(i*obj.NumCols + j);
                    curContentItem = getImpl(curContentItem);
                    if isempty(curContentItem)
                        continue;
                    end
                    
                    if (i < obj.NumHeadRows) || ...
                            (i > (numRows - obj.NumFootRows - 1))
                        cellType = "th";
                    else
                        cellType = "td";
                    end
                    
                    curCell = createElement(obj.OwnerDoc,cellType);
                    appendChild(curRow,curCell);
                    
                    cellAlignment = getAttribute(curContentItem,"align");
                    if isempty(cellAlignment)
                        cellAlignment = obj.GroupAlign;
                    end
                    setAttribute(curCell,"align", cellAlignment);
                    
                    %  Copy the children from the corresponding
                    %  obj.TableContent object into the cell
                    %  NOTE* Grab the number of children first because
                    %  it changes as children are moved from the old parent to
                    %  the new parent
                    numChildren = getLength(curContentItem);
                    for k = 1:numChildren
                        child = node(curContentItem,1);
                        appendChild(curCell,child);
                    end
                    
                    % The content is copied over, now look for multi-cell
                    % spanning indicators
                    colspan = getNumColsSpanned(curContentItem);
                    if(colspan > 1)
                        setAttribute(curCell,"colspan", ...
                            string(num2str(colspan)));
                    end
                    
                    rowspan = getNumRowsSpanned(curContentItem);
                    if(rowspan > 1)
                        setAttribute(curCell, "rowspan", ...
                            string(num2str(rowspan)));
                    end
                end
            end
            
            table = obj.CurrentTable;
        end
    end
end

function colspan = getNumColsSpanned(cell)
startCol = getAttribute(cell,"namest");
endCol = getAttribute(cell,"nameend");

if isempty(startCol) || isempty(endCol)
    colspan = 1;
else
    try
        startIndex = str2double(startCol);
        endIndex = str2double(endCol);
        numCols = endIndex - startIndex + 1;
    catch
        %  In theory, this exception should never happen here
        numCols = 1;
    end
    
    colspan = numCols;
end
end

function rowspan = getNumRowsSpanned(cell)
rowCt = getAttribute(cell,"morerows");
if isempty(rowCt)
    rowspan = 1;
else
    try
        numRows = str2double(rowCt) + 1;
    catch
        %  In theory, this exception should never happen here
        numRows = 1;
    end
    rowspan = numRows;
end
end

function tagName = getRowTagName(thisRow,numRows) %#ok<DEFNU>
if thisRow <= obj.NumHeadRows
    tagName = "thead";
elseif thisRow > numRows - obj.NumFootRows
    tagName = "tfoot";
else
    tagName = "tbody";
end


end



