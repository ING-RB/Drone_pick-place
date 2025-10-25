%mlreportgen.ppt.VAlign Vertical alignment of table entry content
%    vAlignObj = VAlign() creates a vertical alignment object that
%    specifies top alignment.
%
%    vAlignObj = VAlign(value) creates a vertical alignment object based
%    on the specified alignment value.
%
%    VAlign properties:
%       Value       - Vertical alignment
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a table with its table entries having
%    different vertical alignment options to align the content.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation('myVAlignPresentation.pptx');
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table
%    table = Table();
%    table.Height = "3in";
%
%    % Create the first table row
%    tr1 = TableRow();
%
%    % Create the first table entry for the first row with top aligment
%    te1tr1 = TableEntry("top");
%    te1tr1.Style = {VAlign("top")};
%    append(tr1,te1tr1);
%
%    % Create the second table entry for the first row with middle aligment
%    te2tr1 = TableEntry("middle");
%    te2tr1.Style = {VAlign("middle")};
%    append(tr1,te2tr1);
%
%    % Create the third table entry for the first row with bottom aligment
%    te3tr1 = TableEntry("bottom");
%    te3tr1.Style = {VAlign("bottom")};
%    append(tr1,te3tr1);
%
%    % Append the first table row to the table
%    append(table,tr1);
%
%    % Create the second table row
%    tr2 = TableRow();
%
%    % Create the first table entry for the second row with top-centered aligment
%    te1tr2 = TableEntry("topCentered");
%    te1tr2.Style = {VAlign("topCentered")};
%    append(tr2,te1tr2);
%
%    % Create the second table entry for the second row with middle-centered aligment
%    te2tr2 = TableEntry("middleCentered");
%    te2tr2.Style = {VAlign("middleCentered")};
%    append(tr2,te2tr2);
%
%    % Create the third table entry for the second row with bottom-centered aligment
%    te3tr2 = TableEntry("bottomCentered");
%    te3tr2.Style = {VAlign("bottomCentered")};
%    append(tr2,te3tr2);
%
%    % Append the second table row to the table
%    append(table,tr2);
%
%    % Add the title and table to the presentation
%    replace(slide,"Title","Table entries with different vertical alignment");
%    replace(slide,"Table",table);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.HAlign, mlreportgen.ppt.TableEntry

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Vertical alignment
     %  Vertical alignment for table entry content, specified as a
     %  character vector or a string scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'top'               Content aligned vertically to the top (default)
     %      'bottom'            Content aligned vertically to the bottom
     %      'middle'            Content aligned vertically to the middle
     %      'topCentered'       Content aligned vertically to the top and horizontally to the center
     %      'bottomCentered'    Content aligned vertically to the bottom and horizontally to the center
     %      'middleCentered'    Content aligned vertically to the middle and horizontally to the center
     Value;

end
%}