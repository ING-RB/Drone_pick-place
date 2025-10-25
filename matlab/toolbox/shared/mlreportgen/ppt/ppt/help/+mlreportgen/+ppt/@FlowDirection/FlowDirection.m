%mlreportgen.ppt.FlowDirection Table column flow direction
%    flowDirectionObj = FlowDirection() causes the columns to flow from
%    left to right.
%
%    flowDirectionObj = FlowDirection(flow) causes the table columns to
%    appear in the specified flow direction.
%
%    FlowDirection properties:
%       Value       - Table column flow direction
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code sets the table column's flow direction as
%    right-to-left.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myFlowDirection.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a table and specify the column flow direction
%    t = Table({'entry(1,1)', 'entry(1,2)'; 'entry(2,1)', 'entry(2,2)'});
%    t.Style = [t.Style {FlowDirection("RightToLeft")}];
%
%    % Add the table to the slide
%    replace(slide,"Content",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Table column flow direction
     %  Table column flow direction, specified as a character vector or a
     %  string scalar. Valid values are:
     %
     %      LeftToRight     - left-to-right column order (default)
     %      RightToLeft     - right-to-left column order
     Value;

end
%}