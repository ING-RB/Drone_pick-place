%mlreportgen.ppt.BackgroundColor Background color of presentation element
%    backgroundColorObj = BackgroundColor() creates a white background
%    color object.
%
%    backgroundColorObj = BackgroundColor(color) creates a background color
%    object based on the specified CSS color name or hexadecimal RGB color
%    value.
%
%    backgroundColorObj = BackgroundColor("rgb(r,g,b)") creates a background color 
%    specified by  an rgb triplet such that r,g,b values are in between 0 to 255.
%
%    backgroundColorObj = BackgroundColor([x y z]) creates a background color specified 
%    by an rgb triplet [x y z] such that each of them is decimal number between 0 and 1.
%
%
%    BackgroundColor properties:
%       Value       - CSS color name or a hexadecimal RGB value or an RGB
%                     triplet
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code creates a table with rows and table entries of
%    different background color.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myBackground.pptx");
%    open(ppt);
%
%    Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table
%    table = Table();
%
%    % Create the first table row with beige background color
%    tr1 = TableRow();
%    tr1.Style = {BackgroundColor("beige")};
%
%    % Create first table entry for the first row
%    te1tr1 = TableEntry();
%    append(te1tr1,Paragraph("Beige row"));
%    append(tr1,te1tr1);
%
%    % Create second table entry for the first row
%    te2tr1 = TableEntry();
%    append(te2tr1,Paragraph("More text"));
%    append(tr1,te2tr1);
%
%    % Append the first table row to the table
%    append(table,tr1);
%
%    % Create the second table row
%    tr2 = TableRow();
%
%    % Create first table entry for the second row with yellow background
%    % color
%    te1tr2 = TableEntry();
%    te1tr2.Style = {BackgroundColor("yellow")};
%    append(te1tr2,Paragraph("Yellow cell"));
%    append(tr2,te1tr2);
%
%    % Create second table entry for the second row
%    te2tr2 = TableEntry();
%    append(te2tr2,Paragraph("Default white background"));
%    append(tr2,te2tr2);
%
%    % Append the second table row to the table
%    append(table,tr2);
%
%    % Add the title and table to the presentation
%    replace(slide,"Title","A Colorful Table");
%    replace(slide,"Table",table);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.FontColor

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class
