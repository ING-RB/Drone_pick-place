%mlreportgen.ppt.TextOrientation Orientation of text in a table entry
%    textOrientationObj = TextOrientation() causes the text in a table
%    entry to be displayed in the horizontal orientation.
%
%    textOrientationObj = TextOrientation(orientation) causes the text in a
%    table entry to be displayed in the specified orientation.
%
%    TextOrientation properties:
%       Value       - Text orientation
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code sets the text orientation to be vertical for the
%    entries in the first row.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myTextOrientation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table
%    t = Table({'Col 1', 'Col 2'; 'entry 1', 'entry 2'});
%    t.Height = '2in';
%    t.Width = '2in';
%    t.StyleName = "Medium Style 2 - Accent 1";
%    t.Style = [t.Style {VAlign("middleCentered")}];
%
%    % Specify vertical text orientation for the entries in the first row
%    tr1te1 = t.entry(1,1);
%    tr1te1.Style = [ tr1te1.Style {TextOrientation("down")} ];
%
%    tr1te2 = t.entry(1,2);
%    tr1te2.Style = [ tr1te2.Style {TextOrientation("down")} ];
%
%    % Add the title and table to the slide
%    replace(slide,"Title","Vertical table entry content");
%    replace(slide,"Table",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.TableEntry

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Text orientation
     %  Text orientation, specified as a character vector or a string
     %  scalar. Valid values are:
     %
     %      horizontal  - text orientation is horizontal (default)
     %      down        - text orientation is vertical, with the content
     %                    rotated 90 degrees clockwise
     %      up          - text orientation is vertical, with the content
     %                    rotated 90 degrees counterclockwise
     Value;

end
%}