% mlreportgen.ppt.Table Table to include in a presentation
%     tableObj = Table() creates an empty table object.
%
%     tableObj = Table(nCols) creates an empty table object with the number
%     of columns that you specify.
%
%     tableObj = Table(tableValues) returns a table whose content is
%     specified by a two-dimensional numeric array, two-dimensional
%     categorical array, or a two-dimensional cell array of numbers,
%     character vectors, string scalars, or mlreportgen.ppt.Paragraph
%     objects.
%
%     tableObj = Table(tableValues,styleName) returns a table that has the
%     specified content and style name. Use the getTableStyleNames method
%     of the mlreportgen.ppt.Presentation object to get the list of valid
%     style names.
%
%    Table properties:
%      NCols                - Number of table columns
%      Name                 - Table name
%      X                    - Upper-left x-coordinate position of table
%      Y                    - Upper-left y-coordinate position of table
%      Width                - Width of table
%      Height               - Height of table
%      BackgroundColor      - Table background color
%      ColSpecs             - Table column format objects
%      FlowDirection        - Table column flow direction
%      Border               - Border style
%      BorderColor          - Border color
%      BorderWidth          - Border width
%      ColSep               - Style of column separators
%      ColSepColor          - Color of column separators
%      ColSepWidth          - Width of column separators
%      RowSep               - Style of row separators
%      RowSepColor          - Color of row separators
%      RowSepWidth          - Width of row separators
%      Font                 - Font family for text in this table
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color for text in this table
%      FontSize             - Font size of text in this table
%      StyleName            - Table style name
%      Style                - Array of table formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    Table methods:
%      append       - Add content to table
%      replace      - Replace table
%      row          - Access table row
%      entry        - Access table entry
%      clone        - Copy table
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation('myTablePresentation.pptx');
%    open(ppt);
%
%    % Add two slides to the presentation
%    slide1 = add(ppt,'Title and Table');
%    slide2 = add(ppt,'Title and Table');
%
%    % Create a table using a cell array and add it to the first slide
%    table1 = Table({'a','b';'c','d'});
%    table1.Children(1).FontColor = 'red';
%    table1.Children(2).FontColor = 'green';
%    contents = find(ppt,'Table');
%    replace(contents(1),table1);
%
%    % Create a second table using the MATLAB magic function and add it to
%    % the second slide
%    table2 = Table(magic(9));
%    replace(contents(2),table2);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.TemplateTable, mlreportgen.ppt.TableRow,
%    mlreportgen.ppt.TableEntry, mlreportgen.ppt.TablePlaceholder

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %NCols Number of table columns
     %  Number of table columns, specified as an integer. This property is
     %  read-only. To specify the number of columns, create a table by
     %  using the syntax mlreportgen.ppt.Table(nCols). Otherwise, the Table
     %  constructor determines the number of columns from the table
     %  content. If you add rows to a table or entries to a row and the
     %  number of columns changes, the NCols property value is updated. If
     %  the rows do not all have the same number of entries, the row with
     %  the largest number of table entries determines the number of
     %  columns in the table.
     NCols;

     %StyleName Table style name
     %  Name of the style to be used to format this table specified as a
     %  character array or string scalar. The style is assumed to be
     %  defined in the presentation file that serves as the template for
     %  the presentation containing this table.
     StyleName;

     %BackgroundColor Table background color
     %  Table background color, specified as a character vector or a
     %  string scalar. Use either a CSS color name or a hexadecimal RGB
     %  value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for the red, green, and blue
     %  values. For example, '#0000ff' specifies blue.
     BackgroundColor;

     %ColSpecs Table column formatting objects
     %    An array of mlreportgen.ppt.ColSpec objects that specify the
     %    width, alignment, and other formatting properties of table
     %    columns. The first object applies to the first column, the second
     %    object applies to the second column, and so on.
     %
     %    Example:
     %    The following code sets the width and background color of the
     %    first two columns of a table.
     %
     %    % Create a presentation
     %    import mlreportgen.ppt.*
     %    ppt = Presentation('myColSpec.pptx');
     %    open(ppt);
     %
     %    % Add a slide to the presentation
     %    slide = add(ppt,'Title and Content');
     %
     %    % Create a table and specify the width and background color of
     %    % the first two columns using the ColSpecs
     %    t = Table(magic(12));
     %    t.Style = {HAlign('center')};
     %    colSpecs(1) = ColSpec('1in');
     %    colSpecs(1).BackgroundColor = 'red';
     %    colSpecs(2) = ColSpec('2in');
     %    colSpecs(2).BackgroundColor = 'green';
     %    t.ColSpecs = colSpecs;
     %
     %    % Add the table to the slide
     %    replace(slide,'Content',t);
     %
     %    % Close and view the presentation
     %    close(ppt);
     %    rptview(ppt);
     %
     %    See also mlreportgen.ppt.ColSpec
     ColSpecs;

     %FlowDirection Table column flow direction
     %    Table column flow direction, specified as a character vector or a
     %    string scalar. Valid values are:
     %
     %        LeftToRight   - left-to-right column order (default)
     %        RightToLeft   - right-to-left column order
     %
     %    Example:
     %    The following code sets the table column's flow direction as
     %    right-to-left.
     %
     %    % Create a presentation
     %    import mlreportgen.ppt.*
     %    ppt = Presentation("myFlowDirection.pptx");
     %    open(ppt);
     %
     %    % Add a slide to the presentation
     %    slide = add(ppt,"Title and Content");
     %
     %    % Create a table and specify the column flow direction
     %    t = Table({'entry(1,1)', 'entry(1,2)'; 'entry(2,1)', 'entry(2,2)'});
     %    t.FlowDirection = "RightToLeft";
     %
     %    % Add the table to the slide
     %    replace(slide,"Content",t);
     %
     %    % Close and view the presentation
     %    close(ppt);
     %    rptview(ppt);
     %
     %    See also mlreportgen.ppt.FlowDirection
     FlowDirection;

     %Border Border style
     %  Table border style, specified as a character vector or a string
     %  scalar. Valid values are:
     %
     %      'none'
     %      'solid'
     %      'dot'
     %      'dash'
     %      'largeDash'
     %      'dashDot'
     %      'largeDashDot'
     %      'largeDashDotDot'
     %      'systemDash'
     %      'systemDot'
     %      'systemDashDot'
     %      'systemDashDotDot'
     %
     %  See also mlreportgen.ppt.Border
     Border;

     %BorderColor Border color
     %  Table border color, specified as a character vector or a string
     %  scalar. Use either a CSS color name or a hexadecimal RGB value or 
     %  an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     %
     %  See also mlreportgen.ppt.Border
     BorderColor;

     %BorderWidth Border width
     %  Table border width, specified as a character vector or a string
     %  scalar. Use the format valueUnits, where Units is an abbreviation
     %  for the units. These abbreviations are valid:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %  See also mlreportgen.ppt.Border
     BorderWidth;

     %ColSep Style of column separators
     %  Style of table column separators, specified as a character vector
     %  or a string scalar. Valid values are:
     %
     %      'none'
     %      'solid'
     %      'dot'
     %      'dash'
     %      'largeDash'
     %      'dashDot'
     %      'largeDashDot'
     %      'largeDashDotDot'
     %      'systemDash'
     %      'systemDot'
     %      'systemDashDot'
     %      'systemDashDotDot'
     %
     %  See also mlreportgen.ppt.ColSep
     ColSep;

     %ColSepColor Color of column separators
     %  Color of table column separators, specified as a character vector
     %  or a string scalar. Use either a CSS color name or a hexadecimal
     %  RGB value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     %
     %  See also mlreportgen.ppt.ColSep
     ColSepColor;

     %ColSepWidth Width of column separators
     %  Width of table column separators, specified as a character vector
     %  or a string scalar. Use the format valueUnits, where Units is an
     %  abbreviation for the units. These abbreviations are valid:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %  See also mlreportgen.ppt.ColSep
     ColSepWidth;

     %RowSep Style of row separators
     %  Style of table row separators, specified as a character vector or a
     %  string scalar. Valid values are:
     %
     %      'none'
     %      'solid'
     %      'dot'
     %      'dash'
     %      'largeDash'
     %      'dashDot'
     %      'largeDashDot'
     %      'largeDashDotDot'
     %      'systemDash'
     %      'systemDot'
     %      'systemDashDot'
     %      'systemDashDotDot'
     %
     %  See also mlreportgen.ppt.RowSep
     RowSep;

     %RowSepColor Color of row separators
     %  Color of table row separators, specified as a character vector or a
     %  string scalar. Use either a CSS color name or a hexadecimal RGB
     %  value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     %
     %  See also mlreportgen.ppt.RowSep
     RowSepColor;

     %RowSepWidth Width of row separators
     %  Width of table row separators, specified as a character vector or a
     %  string scalar. Use the format valueUnits, where Units is an
     %  abbreviation for the units. These abbreviations are valid:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %  See also mlreportgen.ppt.RowSep
     RowSepWidth;

     %Font Font family for text in this table
     %  Font family for the text in this table, specified as a character
     %  vector or a string scalar. Specify a font that appears in the font
     %  list in Microsoft PowerPoint. To see the font list, in PowerPoint,
     %  on the Home tab, in the Font group, click the arrow to the right of
     %  the font.
     Font;

     %ComplexScriptFont Font family for complex scripts
     %  Font family for complex scripts, specified as a character vector or
     %  a string scalar. Specify a font family for substituting in a locale
     %  that requires a complex script (such as Arabic or Asian) for
     %  rendering text.
     ComplexScriptFont;

     %FontColor Font color for text in this table
     %  Font color for text in this table, specified as a character vector
     %  or a string scalar. Use either a CSS color name or a hexadecimal
     %  RGB value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     FontColor;

     %FontSize Font size of text in this table
     %  Font size of text in this table, specified as a character vector or
     %  a string scalar. Use the format valueUnits, where Units is an
     %  abbreviation for the font size. These abbreviations are valid:
     %
     %  Abbreviation  Units
     %
     %  px            pixels (default)
     %  cm            centimeters
     %  in            inches
     %  mm            millimeters
     %  pc            picas
     %  pt            points
     FontSize;

end
%}
