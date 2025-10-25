%mlreportgen.ppt.ColWidth Table column width
%    widthObj = ColWidth() creates a format object that specifies a column
%    width of 0.25 inches.
%
%    widthObj = ColWidth(value) creates a column width object having the
%    specified width.
%
%    ColWidth properties:
%       Value       - Column width value
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation('myColWidth.pptx');
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,'Title and Content');
%
%    % Create a table and specify the first column width to be four inches
%    C = {'wide column' 17 'aaaa' 4 5 6 7 8 9 10 11;...
%         'long text string' 'bb' 1 3 5 7 9 11 13 15 17;...
%         'more text' 1 2 3 4 5 6 7 8 9 10};
%    t = Table(C);
%    t.entry(1,1).Style = {ColWidth('4in')};
%
%    % Add the table to the slide
%    replace(slide,'Content',t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.ColSpec

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class
