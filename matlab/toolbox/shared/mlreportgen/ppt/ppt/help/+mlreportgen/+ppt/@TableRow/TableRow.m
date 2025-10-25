% mlreportgen.ppt.TableRow Row to include in a table
%     tableRowObj = TableRow() creates an empty table row object.
%
%    TableRow properties:
%      Height               - Height of this row
%      Font                 - Default font for text in this row
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color
%      FontSize             - Font size
%      BackgroundColor      - Row background color
%      Style                - Default formatting for text in table entries in row
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    TableRow methods:
%      append               - Add content to table row
%      clone                - Copy table row
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation('myTableRowPresentation.pptx');
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
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.Table.row,
%    mlreportgen.ppt.TableEntry

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Height Height of this row
     %  Height of this row, specified as a character vector or a string
     %  scalar. Use the format valueUnits, where Units is an abbreviation
     %  for the units. These abbreviations are valid:
     %
     %  Abbreviation    Units
     %
     %  px              pixels (default)
     %  cm              centimeters
     %  in              inches
     %  mm              millimeters
     %  pc              picas
     %  pt              points
     %
     %  Note: Specifying a table height but not the height for any row
     %  makes the height of all rows the same, where the row height is
     %  determined by dividing the table height by the number of rows. If
     %  any row of the table specifies its height, the table height is not
     %  used to determine the row heights.
     %
     %  See also mlreportgen.ppt.RowHeight
     Height;

     %Font Default font for text in this row
     %  Default font for text in this row, specified as a character vector
     %  or a string scalar. Specify a font that appears in the PowerPoint
     %  list of fonts in the Home tab Font area.
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
     %  (eg. [0 0 1] corresponds to blue color) or  an RGB  triplet string 
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

     %BackgroundColor Row background color
     %  Row background color, specified as a character vector or a string
     %  scalar. Use either a CSS color name or a hexadecimal RGB value or an  
     %  RGB triplet (eg. [0 0 1] corresponds to blue color) or  an RGB   
     %  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     BackgroundColor;

end
%}
