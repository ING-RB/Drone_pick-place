    %mlreportgen.re.internal.db.CALSEntry Defines a DocBook table entry
    %    entry = CALSEntry() creates an empty table entry. Use the init
    %    method to initialize the entry.
    %
    %    CALSEntry properties:
    %      Align        - Horizonatal aligment of entry content
    %      ColSep       - Whether to draw a line after this entry
    %      ColSpanEnd   - Number of last column spanned by this entry
    %      ColSpanStart - Number of first column spanned by this entry
    %      MoreRows     - Number of rows spanned by this entry
    %      Rotate       - Whether to rotate entry content
    %      RowSep       - Whether to draw a line below this entry
    %      VAlign       - Vertical alignment of entry content
    %
    %    CALSEntry methods:
    %      appendChild     - Append XML content to this entry
    %      getAlign        - Get horizontal alignment of entry content
    %      getColSep       - Get whether to draw a line after entry
    %      getColSpanEnd   - Get number of last column spanned by entry
    %      getColSpanStart - Get number of first column spanned by entry
    %      getImpl         - Get XML element containing this entry
    %      getMoreRows     - Get number of rows spanned by this entry
    %      getRotate       - Get whether to rotate entry content
    %      getRowSep       - Get whether to draw line below this entry
    %      getVAlign       - Get vertical alignment of entry content
    %      init            - Initialize this entry
    %      setAlign        - Set horizontal alignment of entry content
    %      setColSep       - Set whether to draw a line after entry
    %      setColSpanEnd   - Set number of last column spanned by entry
    %      setColSpanStart - Set number of first column spanned by entry
    %      setMoreRows     - Set number of rows spanned by entry
    %      setRotate       - Set whether to rotate entry content
    %      setRowSep       - Set whether to draw line below entry
    %      setVAlign       - Set whether to align content vertically
    
    %   Copyright 2021 MathWorks, Inc.
    
    %{
properties
     % Align Horizontal alignment of table entry
     %   Specifies the horizontal alignment of this table entry's content
     %   relative to the left and right sides of the entry. Valid values
     %   are:
     %
     %     'Left' (default)
     %     'Center'
     %     'Right'
     %     'Justify'
     %     'Char'
     Align;

     % VAlign Vertical alignment of this entry's content
     %  A character vector that specifies the vertical alignment of this
     %  entry's content relative to the top and bottom sides of the entry.
     %  Valid values are:
     %    'Top'
     %    'Middle'
     %    'Bottom'
     VAlign;

     % ColSep Whether to draw a line after this entry
     %  A value of true causes a line to be drawn after this entry,
     %  separating it from the next entry. The default value is false.
     ColSep;

     % RowSep Whether to draw a line below this entry
     %  A value of true causes a line to be drawn below this entry,
     %  separating it from the entry below. The default value is false.
     RowSep;

     % Rotate Whether to rotate entry's content
     %  A value of true rotates this entry's content 90 degrees 
     %  counterclockwise relative to the table's orientation.
     %  The default value is false.
     Rotate;

     % ColSpanStart Number of first column spanned by this entry
     ColSpanStart;

     % ColSpanEnd Number of last column spanned by this entry
     ColSpanEnd;

     % MoreRows Number of rows spanned by this entry beyond current row
     MoreRows;

end
%}