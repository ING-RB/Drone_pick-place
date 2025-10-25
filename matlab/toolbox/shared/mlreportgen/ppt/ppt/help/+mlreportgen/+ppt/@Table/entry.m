%entry Access table entry
%    tableEntryOut = entry(tableObj,row,column) returns the table entry for
%    the specified column of the specified row.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*;
%     ppt = Presentation('myTableEntryMethod.pptx');
%     open(ppt);
%
%     % Add a slide to the presentation
%     slide = add(ppt,'Title and Content');
%
%     % Create a table
%     t = Table(magic(5));
%
%     % Specify the background color for the table entry in row 3, column 4
%     entry4row3 = t.entry(3,4);
%     entry4row3.BackgroundColor = 'red';
%
%     % Add the table to the slide
%     replace(slide,'Content',t);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Table.row, mlreportgen.ppt.TableEntry

%    Copyright 2019 MathWorks, Inc.
%    Built-in function.
