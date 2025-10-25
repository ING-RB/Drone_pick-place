%row Access table row
%    tableRowOut = row(table,rowNumber) returns the row specified by the
%    rowNumber.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*;
%     ppt = Presentation('myTableRowMethod.pptx');
%     open(ppt);
%
%     % Add a slide to the presentation
%     slide = add(ppt,'Title and Content');
%
%     % Create a table
%     t = Table(magic(5));
%
%     % Specify the background color for the third row in the table
%     row3 = t.row(3);
%     row3.BackgroundColor = 'red';
%
%     % Add the table to the slide
%     replace(slide,'Content',t);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Table.entry, mlreportgen.ppt.TableRow

%    Copyright 2019 MathWorks, Inc.
%    Built-in function.
