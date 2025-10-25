%mlreportgen.dom.NumberFormat Specifies the formatting of a Number object
%    numberFormatObj = NumberFormat() creates a NumberFormat object with an
%    empty Value. Set the Value property to the format specification.
%
%    numberFormatObj = NumberFormat(formatString) creates a NumberFormat 
%    object based on the specified format string.
%    The format string must be an sprintf number format string.  
%    See https://www.mathworks.com/help/matlab/ref/sprintf.html
%    
%
%    NumberFormat properties:
%        Value            - a character vector or string scalar that specifies 
%                           an sprintf number format string with the
%                           following formatting operators - %f, %e, %E, %g, %G.  
%        FormatIntegers   - Boolean - specifies whether to apply NumberFormat to
%                           integers. If true, NumberFormat will be applied
%                           to integers. If false, NumberFormat will not be
%                           applied to integers. Default is true.
%        Id               - Id of this NumberFormat object
%        Tag              - Tag of this NumberFormat object
%
%    Example:
%
%    % Create a Number and add a NumberFormat style
%     import mlreportgen.dom.*
% 
%     rpt = Document('Report with NumberFormat','pdf');
% 
%     n = Number(pi);
%     n.Style = {NumberFormat("%0.4f")};
%     append(rpt, n);
% 
%     close(rpt);
%     rptview(rpt);
%
%    See also mlreportgen.dom.Number,
%    mlreportgen.dom.setDefaultNumberFormat, mlreportgen.dom.getDefaultNumberFormat

%    Copyright 2020-22 MathWorks, Inc.
%    Built-in class

%{
properties
     %Value Sprintf number format string
     %    The value of this property is a character vector or string scalar 
     %    that specifies an sprintf number format string with the following 
     %    formatting operators - %f, %e, %E, %g, %G.
     Value;

     %FormatIntegers Boolean value that specifies whether to format
     %integers
     %     This property specifies whether to apply NumberFormat to integers
     %     using NumberFormat. If true, NumberFormat will be applied to 
     %     integers. If false, NumberFormat will not be applied to integers. 
     %     Default is true.
     %
     %     Example:
     %
     %     import mlreportgen.dom.*
     %     
     %     rpt = Document('mydoc', 'pdf');
     %     mTable = MATLABTable(table({12.123, 456.325; 100, 458.965}));
     %     numberFormat = NumberFormat("%0.2f");
     %
     %     % To prevent 100 to be formatted as 100.00, set FormatIntegers to
     %     % false
     %     numberFormat.FormatIntegers = false;
     %     mTable.Style = {numberFormat};
     %
     %     append(rpt, mTable);
     %
     %     close(rpt);
     %     rptview(rpt.OutputPath);
     FormatIntegers;
end
%}