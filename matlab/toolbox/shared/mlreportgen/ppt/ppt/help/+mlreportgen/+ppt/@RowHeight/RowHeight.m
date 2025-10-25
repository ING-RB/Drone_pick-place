%mlreportgen.ppt.RowHeight Table row height
%    rowHeightObj = RowHeight() specifies row height to be 0.41 inch.
%
%    rowHeightObj = RowHeight(value) sets a row to the specified height.
%
%    Note: If the row content is too big to fit in the specified height or
%    if the specified height value is negative, the resulting PowerPoint
%    presentation adjusts the row height to accommodate the content.
%
%    RowHeight properties:
%       Value       - Row height value
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myRowHeight.pptx");
%    open(ppt);
%    slide = add(ppt,"Title and Content");
%
%    % Create a table and specify the row heights
%    t = Table(magic(2));
%    t.row(1).Style = {RowHeight("2in")};
%    t.row(2).Height = "1in";
%    replace(slide,"Content",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.TableRow

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class
