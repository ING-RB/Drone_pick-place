% mlreportgen.ppt.Number Number to include as formatted text in a presentation
%     numberObj = Number() creates an empty Number object. Use the Value
%     property to specify a number to convert to formatted text.
%
%     numberObj = Number(value) creates a Number object with the Value
%     property set to the specified value.
%
%    Number methods:
%      clone                - Copy number
%      toString             - Convert number to formatted text
%
%    Number properties:
%      Value                - Number value
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myNumberPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Add title of the slide
%    replace(slide,"Title","Slide with numeric content");
%
%    % Create a Number object and append it to a paragraph
%    para = Paragraph("The value of pi is: ");
%    number = Number(pi);
%    append(para,number);
%
%    % Replace the content for the slide with the paragraph
%    replace(slide,"Content",para);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Text,
%    mlreportgen.ppt.NumberFormat, mlreportgen.ppt.getDefaultNumberFormat,
%    mlreportgen.ppt.setDefaultNumberFormat

%    Copyright 2024 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Number value
     %  Number to convert to formatted text, specified as a double.
     Value;

end
%}
