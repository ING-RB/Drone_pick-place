% mlreportgen.ppt.NumberFormat Number formatting
%     numberFormatObj  = NumberFormat() creates a NumberFormat object. Set
%     the Value property to the format specification.
%
%     numberFormatObj  = NumberFormat(value) creates a NumberFormat object
%     and sets the Value property to the format specified by value.
%
%    NumberFormat properties:
%      Value            - Number format specification
%      FormatIntegers   - Whether to apply format specification to integers
%      Id               - ID for this PPT API object
%      Tag              - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myNumberFormatPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Add title of the slide
%    replace(slide,"Title","Slide with formatted numeric content");
%
%    % Create a Number object, specify its number format specification,
%    % and append it to a paragraph
%    para = Paragraph("The value of pi is: ");
%    number = Number(pi);
%    number.Style = [number.Style {NumberFormat("%0.4f")}];
%    append(para,number);
%
%    % Replace the content for the slide with the paragraph
%    replace(slide,"Content",para);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Number, sprintf,
%    mlreportgen.ppt.getDefaultNumberFormat,
%    mlreportgen.ppt.setDefaultNumberFormat

%    Copyright 2024 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Number format specification
     %  Format specification, specified as a character vector or string
     %  scalar. The specification must be a valid format specification for
     %  the sprintf function and use one of these operators: %f, %e, %E,
     %  g, %G.
     Value;

     %FormatIntegers Whether to apply format specification to integers
     %  Whether to apply the number format specification to integers,
     %  specified as a logical value. If true, the format specification
     %  will be applied to integers. If false, the format specification
     %  will not be applied to integers. The default value is true.
     %
     %  Example:
     %
     %    % Create a presentation
     %    import mlreportgen.ppt.*
     %    ppt = Presentation("myNumberFormatPresentation.pptx");
     %    open(ppt);
     %
     %    % Add a slide to the presentation
     %    slide = add(ppt,"Title and Table");
     %
     %    % Add title for the slide
     %    replace(slide,"Title","Table with formatted numeric content");
     %
     %    % Create a table with numeric content
     %    table = Table({12.123, 456.325; 100, 458.965});
     %
     %    % Specify number format specification for the table.
     %    % Set the FormatIntegers property to false to prevent "100" to be
     %    % formatted as "100.00".
     %    numberFormat = NumberFormat("%0.2f");
     %    numberFormat.FormatIntegers = false;
     %    table.Style = [table.Style {numberFormat}];
     %
     %    % Add the table to the slide
     %    replace(slide,"Table",table);
     %
     %    % Close and view the presentation
     %    close(ppt);
     %    rptview(ppt);
     FormatIntegers;

end
%}
