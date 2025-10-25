%mlreportgen.dom.getDefaultNumberFormat returns the default number format
%set for the DOM API
%
%    format = mlreportgen.dom.getDefaultNumberFormat() returns the sprintf 
%             format specification used by default to format Number objects. 
%             An empty character array causes a number to be formatted using 
%             the maximum number of digits needed to represent the number accurately.
%
%    Example:
%
%    % Get the default number format
%     import mlreportgen.dom.*
% 
%     rpt = Document("Report with getDefaultNumberFormat","pdf");
% 
%     numberFormat = getDefaultNumberFormat();
%     p = Paragraph("Default number format is : ");
%     p.append(numberFormat);
%
%     append(rpt,p);
% 
%     close(rpt);
%     rptview(rpt);
%
%    See also mlreportgen.dom.Number, mlreportgen.dom.NumberFormat,
%    mlreportgen.dom.setDefaultNumberFormat

%    Copyright 2020 MathWorks, Inc.
%    Built-in function