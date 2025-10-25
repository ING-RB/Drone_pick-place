    %mlreportgen.re.internal.db.TableMaker Generate a DocBook XML table 
    %    tm = TableMaker(doc) creates an object that generates the DocBook
    %    table specified by its properties.
    %    tm = TableMaker(doc,colWidths) creates a table with the column
    %    widths specified by the colWidths string array.
    %
    %    TableMaker properties:
    %      OwnerDoc     - MAXP Document object
    %      TableContent - MxN array of CALSEntry objects
    %      NumCols      - Number of table columns
    %      ColWidths    - String array of column widths
    %      TableTitle   - Table title specified as a MAXP Node 
    %      GroupAlign   - Horizontal table group alignment
    %      Border       - Whether table has a border
    %      PageWide     - Whether table spans width of page
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
    %      setColWidthsPercent   - Set relative column widths
    %      getGroupAlign         - Get GroupAlign property
    %      setGroupAlign         - Set GroupAlign property
    %      getNumCols            - Get NumCols property
    %      setNumCols            - Set NumCols property
    %      getNumFootRows        - Get number of rows in table foot
    %      setNumFootRows        - Set number of rows in table foot
    %      getNumHeadRows        - Get number of rows in table head
    %      setNumHeadRows        - Set number of rows in table head
    %      getPageWide           - Get PageWide property
    %      setPageWide           - Set PageWide property
    %      getTitle              - Get TableTitle property
    %      setTitle              - Set TableTitle property
    %      createTable           - Create table specified by TM props
    %      applyStyleCenterAlign - Apply center align table style
    %      applyStyleSingleRule  - Apply single rule table style
    %      forceHtmlTable        - Force HTML table creation
    %
    %    See also mlreportgen.re.internal.db.CALSEntry
      
    % Copyright 2021 MathWorks, Inc.
    
    
%{
properties
     % OwnerDoc MAXP document used to create table
     %   The value of this property is an matlab.io.xml.dom.Document
     %   object
     OwnerDoc;
 
     % TableContent Content of table
     %   A vector (1xN or Nx1) of objects that specifies the contents
     %   of a table's head, body, and foot sections. The content may
     %   be any of the following:
     %
     %   * Vector of mlreportgen.re.internal.db.CALSEntry objects
     %   * Vector of matlab.io.xml.dom.Node objects
     %   * Vector of strings
     %   * Cell vector containing any of the following types of cells:
     %     - string
     %     - character vector
     %     - mlreportgen.re.internal.db.CALSEntry object
     %     - matlab.io.xml.dom.Node object
     %
     %   The size of the content vector should be 1xN or Nx1 where
     %       N = R*C
     %       C = number of table columns
     %       R = number of table rows, including head, body, and foot
     %           sections.
     TableContent;

     % NumCols Number of columns in the table to be made
     NumCol;
        
     % ColWidths Widths of the columns of the table to be made
     %   The value of this property is a 1xC array of strings that specify
     %   the table widths.
     ColWidths;
        
     % Title Title of table to be made
     %   The value of this property is an matlab.io.xml.dom.Node
     %   object.
     Title;
        
     % GroupAlign Alignment of table entries
     %   The value of this property is a string that specifies the
     %   alignment of the tables entries. Valid values are:
     %     
     %     'Left' (default)
     %     'Center'
     %     'Right'
     %     'Justify'
     %     'Char'
     %
     %   See also https://tdg.docbook.org/tdg/4.5/tgroup.html
     GroupAlign;
        
     % Border Whether table to be made should have a border
     %   Value of this property is a logical. True (default) specifies
     %   that table should have a border.
     Border;
        
     % PageWide Whether the table to be made should span page
     %   The value of this property is a logical. True (default)
     %   specifies that the table should span the page between the
     %   margins.
     PageWide;
        
     % NumHeadRows Number of rows in the header of the table to be made
     %   The value of this property is a double. The default value is 1.
     NumHeadRows;
        
     % NumFootRows Number of footer rows in table
     %   The value of this property is a double. The default value is 0.
     NumFootRows
        
     % ForceHTML Use HTML instead of DocBook markup to generate table
     %   The value of this variable is a logical. False (the default)
     %   specifies use of DocBook markup. HTML markup avoids the need
     %   to convert from DocBook to HTML markup and hence can be faster
     %   for large tables.
     ForceHTML;
        
     % CurrentTable Table generated by this TableMaker
     %   The value of this property is a matlab.io.xml.dom.Element
     %   object containing the table.
     CurrentTable;
        
     % CurrentGroup Table group generated by this TableMaker
     %   The value of this property is a matlab.io.xml.dom.Element
     %   object that contains the head, body, and foot sections of
     %   this table.
     CurrentGroup;
        
     % CurrentHead Head of table generated by this TableMaker
     %   The value of this property is a matlab.io.xml.dom.Element
     %   object containing the header section of the table generated
     %   by this TableMaker.
     CurrentHead;
        
     % CurrentBody Body of table generated by this TableMaker
     %   The value of this property is a matlab.io.xml.dom.Element
     %   object containing the body of the table generated by this
     %   TableMaker.
     CurrentBody;
        
     % CurrentFoot Foot of table generated by this TableMaker
     %   The value of this property is a matlab.io.xml.dom.Element
     %   object containing the footer section of the table generated
     %   by this TableMaker.
     CurrentFoot;
end
%}
