% mlreportgen.ppt.TableEntry Table entry to include in a table row
%     tableEntryObj = TableEntry() creates an empty table entry object.
%
%    TableEntry properties:
%      Font                 - Default font for text in this table entry
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color
%      FontSize             - Font size
%      BackgroundColor      - Table entry background color
%      HAlign               - Horizontal aligment of table entry content
%      VAlign               - Vertical alignment of table entry content
%      TextOrientation      - Orientation of text in this table entry
%      ColSpan              - Number of columns spanned by this table entry
%      RowSpan              - Number of rows spanned by this table entry
%      Border               - Border style
%      BorderColor          - Border color
%      BorderWidth          - Border width
%      Style                - Default formatting for text appended to table entry
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    TableEntry methods:
%      append               - Add content to table entry
%      clone                - Copy table entry
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation('myTableEntryPresentation.pptx');
%     open(ppt);
%
%     % Add a slide to the presentation
%     add(ppt,'Title and Content');
%
%     % Create a table
%     table = Table();
%
%     % Create the first table row
%     tr1 = TableRow();
%     tr1.Style = {Bold(true)};
%
%     % Create the first table entry for the first row
%     te1tr1 = TableEntry();
%     p = Paragraph('first entry');
%     p.FontColor = 'red';
%     append(te1tr1,p);
%     append(tr1,te1tr1);
%
%     % Create the second table entry for the first row
%     te2tr1 = TableEntry();
%     append(te2tr1,'second entry');
%     append(tr1,te2tr1);
%
%     % Create the third table entry for the first row
%     te3tr1 = TableEntry();
%     te3tr1.FontColor = 'green';
%     append(te3tr1,'third entry');
%     append(tr1,te3tr1);
%
%     % Append the first table row to the table
%     append(table,tr1);
%
%     % Create the second table row
%     tr2 = TableRow();
%
%     % Create the first table entry for the second row
%     te1tr2 = TableEntry();
%     te1tr2.FontColor = 'red';
%     p = Paragraph('first entry');
%     append(te1tr2,p);
%     append(tr2,te1tr2);
%
%     % Create the second table entry for the second row
%     te2tr2 = TableEntry();
%     append(te2tr2,'second entry');
%     append(tr2,te2tr2);
%
%     % Create the third table entry for the second row
%     te3tr2 = TableEntry();
%     te3tr2.FontColor = 'green';
%     append(te3tr2,'third entry');
%     append(tr2,te3tr2);
%
%     % Append the second table row to the table
%     append(table,tr2);
%
%     % Add the table to the presentation
%     contents = find(ppt,'Content');
%     replace(contents(1),table);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.Table.entry,
%    mlreportgen.ppt.TableRow

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Font Default font for text in this table entry
     %  Default font for text in this table entry, specified as a character
     %  vector or a string scalar. Specify a font that appears in the
     %  PowerPoint list of fonts in the Home tab Font area.
     Font;

     %ComplexScriptFont Font family for complex scripts
     %  Font family for complex scripts, specified as a character vector or
     %  a string scalar. Specify a font family for substituting in a locale
     %  that requires a complex script (such as Arabic or Asian) for
     %  rendering text.
     ComplexScriptFont;

     %FontColor Font color
     %  Font color, specified as a character vector or a string scalar. Use
     %  either a CSS color name or a hexadecimal RGB value or an RGB triplet 
     %  (eg. [0 0 1] corresponds to blue color) or an RGB  triplet string 
     %  (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     FontColor;

     %FontSize Font size
     %  Font size, specified as a character vector or a string scalar. Use
     %  the format valueUnits, where Units is an abbreviation for the font
     %  size. These abbreviations are valid:
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

     %BackgroundColor Table entry background color
     %  Table entry background color, specified as a character vector or a
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
     BackgroundColor;

     %HAlign Horizontal aligment of table entry content
     %  Horizontal alignment of table entry content, specified as one of
     %  these values:
     %
     %  Value               Description
     %  'center'            Centered
     %  'left'              Left-justified
     %  'right'             Right-justified
     %  'justified'         Left- and right-justified, spacing words evenly
     %  'distributed'       Left- and right-justified, spacing letters evenly
     %  'thaiDistributed'   Left- and right-justified Thai text, spacing characters evenly
     %  'justifiedLow'      Justification for Arabic text
     HAlign;

     %VAlign Vertical aligment of table entry content
     %  Vertical alignment of table entry content, specified as one of
     %  these values:
     %
     %  Value               Description
     %  'top'               Align content to the top of table entry
     %  'bottom'            Align content to the bottom of table entry
     %  'middle'            Align content to the middle of table entry
     %  'topCentered'       Align content to the top-center of table entry
     %  'middleCentered'    Align content to the middle-center of table entry
     %  'bottomCentered'    Align content to the bottom-center of table entry
     VAlign;

     %TextOrientation Orientation of text in this table entry
     %  Orientation of text in this table entry, specified as a character
     %  vector or a string scalar. Valid values are:
     %
     %    horizontal  - text orientation is horizontal
     %    down        - text orientation is vertical, with the content
     %                  rotated 90 degrees clockwise
     %    up          - text orientation is vertical, with the content
     %                  rotated 90 degrees counterclockwise
     %
     %    Example:
     %    The following code sets the text orientation to be vertical for
     %    the entries in the first row.
     %
     %    % Create a presentation
     %    import mlreportgen.ppt.*
     %    ppt = Presentation("myTextOrientation.pptx");
     %    open(ppt);
     %
     %    % Add a slide to the presentation
     %    slide = add(ppt,"Title and Table");
     %
     %    % Create a table
     %    t = Table({'Col 1', 'Col 2'; 'entry 1', 'entry 2'});
     %    t.Height = '2in';
     %    t.Width = '2in';
     %    t.StyleName = "Medium Style 2 - Accent 1";
     %    t.Style = [t.Style {VAlign("middleCentered")}];
     %
     %    % Specify vertical text orientation for the first row entries
     %    tr1te1 = t.entry(1,1);
     %    tr1te1.TextOrientation = "down";
     %
     %    tr1te2 = t.entry(1,2);
     %    tr1te2.TextOrientation = "down";
     %
     %    % Add the title and table to the slide
     %    replace(slide,"Title","Vertical table entry content");
     %    replace(slide,"Table",t);
     %
     %    % Close and view the presentation
     %    close(ppt);
     %    rptview(ppt);
     %
     %  See also mlreportgen.ppt.TextOrientation
     TextOrientation;

     %ColSpan Number of columns spanned by this table entry
     %  Number of table columns spanned by this table entry, specified as a
     %  double.
     %
     %  Example:
     %  This example shows how to create a table with table entries that
     %  span multiple columns.
     %
     %     ____________________________________________________
     %    |                                                    |
     %    |                     Header Row                     |
     %    |____________________________________________________|
     %    |                         |                          |
     %    |      Sub header 1       |       Sub header 2       |
     %    |_________________________|__________________________|
     %    |            |            |             |            |
     %    | entry(1,1) | entry(1,2) | entry(1,3)  | entry(1,4) |
     %    |____________|____________|_____________|____________|
     %
     %  % Create a presentation
     %  import mlreportgen.ppt.*
     %  ppt = Presentation("myColSpan.pptx");
     %  open(ppt);
     %
     %  % Add a slide to the presentation
     %  slide = add(ppt,"Title and Table");
     %
     %  % Create a table with 4 columns
     %  t = Table(4);
     %  t.Style = [t.Style {VAlign("middleCentered")}];
     %
     %  % Create the header row.
     %  % This row has a single table entry that spans all 4 columns.
     %  tr1 = TableRow();
     %  tr1te1 = TableEntry("Header Row");
     %  tr1te1.ColSpan = 4;
     %  append(tr1,tr1te1);
     %  append(t,tr1);
     %
     %  % Create the sub header row.
     %  % This row has 2 table entries, each spans 2 columns.
     %  tr2 = TableRow();
     %  tr2te1 = TableEntry("Sub header 1");
     %  tr2te1.ColSpan = 2;
     %  append(tr2,tr2te1);
     %  tr2te2 = TableEntry("Sub header 2");
     %  tr2te2.ColSpan = 2;
     %  append(tr2,tr2te2);
     %  append(t,tr2);
     %
     %  % Create the content row.
     %  % This row has 4 table entries that span a single column.
     %  tr3 = TableRow();
     %  append(tr3,TableEntry("entry(1,1)"));
     %  append(tr3,TableEntry("entry(1,2)"));
     %  append(tr3,TableEntry("entry(1,3)"));
     %  append(tr3,TableEntry("entry(1,4)"));
     %  append(t,tr3);
     %
     %  % Add the title and table to the slide
     %  replace(slide,"Title","Table Entry spanning multiple columns");
     %  replace(slide,"Table",t);
     %
     %  % Close and view the presentation
     %  close(ppt);
     %  rptview(ppt);
     ColSpan;

     %RowSpan Number of rows spanned by this table entry
     %  Number of table rows spanned by this table entry, specified as a
     %  double.
     %
     %  Example:
     %  This example shows how to create a table with table entries that
     %  span multiple rows.
     %
     %     __________________________________________________
     %    |                |                |                |
     %    |                |                |   entry(1,1)   |
     %    |                |                |________________|
     %    |                |  Sub header 1  |                |
     %    |                |                |   entry(2,1)   |
     %    |                |________________|________________|
     %    | Header Column  |                |                |
     %    |                |                |   entry(3,1)   |
     %    |                |                |________________|
     %    |                |  Sub header 2  |                |
     %    |                |                |   entry(4,1)   |
     %    |________________|________________|________________|
     %
     %  % Create a presentation
     %  import mlreportgen.ppt.*
     %  ppt = Presentation("myRowSpan.pptx");
     %  open(ppt);
     %
     %  % Add a slide to the presentation
     %  slide = add(ppt,"Title and Table");
     %
     %  % Create a table with 3 columns
     %  t = Table(3);
     %  t.Style = [t.Style {VAlign("middleCentered")}];
     %
     %  % Create the first table row
     %  tr1 = TableRow();
     %
     %  % Create the header column entry that spans to all the 4 rows
     %  tr1te1 = TableEntry("Header Column");
     %  tr1te1.RowSpan = 4;
     %  append(tr1,tr1te1);
     %
     %  % Create the first sub header entry spanning to 2 rows
     %  tr1te2 = TableEntry("Sub header 1");
     %  tr1te2.RowSpan = 2;
     %  append(tr1,tr1te2);
     %
     %  % Create the content entry for the first row
     %  append(tr1,TableEntry("entry(1,1)"));
     %  append(t,tr1);
     %
     %  % Create the second table row.
     %  % Add just the content entry to this row as the header and sub
     %  % header entries will span from the previous row.
     %  tr2 = TableRow();
     %  append(tr2,TableEntry("entry(2,1)"));
     %  append(t,tr2);
     %
     %  % Create the third table row
     %  tr3 = TableRow();
     %
     %  % Create the second sub header entry spanning to 2 rows
     %  tr3te2 = TableEntry("Sub header 2");
     %  tr3te2.RowSpan = 2;
     %  append(tr3,tr3te2);
     %
     %  % Create the content entry for the third row
     %  append(tr3,TableEntry("entry(3,1)"));
     %  append(t,tr3);
     %
     %  % Create the fourth table row.
     %  % Add just the content entry to this row as the header and sub
     %  % header entries will span from the previous rows.
     %  tr4 = TableRow();
     %  append(tr4,TableEntry("entry(4,1)"));
     %  append(t,tr4);
     %
     %  % Add the title and table to the slide
     %  replace(slide,"Title","Table Entry spanning multiple rows");
     %  replace(slide,"Table",t);
     %
     %  % Close and view the presentation
     %  close(ppt);
     %  rptview(ppt);
     RowSpan;

     %Border Border style
     %  Table entry border style, specified as a character vector or a
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
     %  See also mlreportgen.ppt.Border, mlreportgen.ppt.ColSep,
     %  mlreportgen.ppt.RowSep
     Border;

     %BorderColor Border color
     %  Table entry border color, specified as a character vector or a
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
     %  See also mlreportgen.ppt.Border, mlreportgen.ppt.ColSep,
     %  mlreportgen.ppt.RowSep
     BorderColor;

     %BorderWidth Border width
     %  Table entry border width, specified as a character vector or a
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
     %  See also mlreportgen.ppt.Border, mlreportgen.ppt.ColSep,
     %  mlreportgen.ppt.RowSep
     BorderWidth;

end
%}
