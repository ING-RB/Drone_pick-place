%getTableStyleNames Get table style names for presentation
%   tableStyles = getTableStyleNames(presentation) gets the table style
%   names for a presentation.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation
%  ppt = Presentation("myPresentation.pptx");
%  open(ppt);
%
%  % Get the names of the table styles in the presentation template
%  tableStyles = getTableStyleNames(ppt);
%
%  % Create a table and specify the table style name
%  table = Table({"a","b";"c","d"});
%  table.StyleName = "Medium Style 2 - Accent 1";
%
%  % Add a slide that has a title and a table. Replace the table
%  % placeholder with the table you created.
%  slide = add(ppt,"Title and Table");
%  replace(slide,"Table",table);
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also getMasterNames, getLayoutNames

%  Copyright 2022 The MathWorks, Inc.
%  Built-in function.
