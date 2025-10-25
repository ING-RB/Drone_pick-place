%append Append content to table entry
%    contentObj = append(tableEntry,content) appends content to a table
%    entry.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation('myTablePresentation.pptx');
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
%     te3tr1.Style = {FontColor('green')};
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
%     te1tr2.Style = {FontColor('red')};
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
%     te3tr2.Style = {FontColor('green')};
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
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.TableEntry,
%    mlreportgen.ppt.TableRow

%    Copyright 2019 MathWorks, Inc.
%    Built-in function.
