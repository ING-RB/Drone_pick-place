%replace Replace table with another table
%     tableObj = replace(table,replacementTable) replaces a table with
%     another table.
%
%     Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation('myTableReplacePresentation.pptx');
%     open(ppt);
%
%     % Add a slide to the presentation
%     slide = add(ppt,'Blank');
%
%     % Create a table t1 and add it to the slide
%     t1 = Table(magic(7));
%     t1.X = '2in';
%     t1.Y = '2in';
%     t1.Width = '6in';
%     t1.Height = '4in';
%     add(slide,t1);
%
%     % Create another table t2
%     t2 = Table(magic(9));
%     t2.X = '2in';
%     t2.Y = '2in';
%     t2.Width = '7in';
%     t2.Height = '5in';
%
%     % Replace table t1 with table t2
%     replace(t1,t2);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Table

%    Copyright 2019 The MathWorks, Inc.
%    Built-in function.
