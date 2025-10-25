%toString Convert number to formatted text
%    formattedNumber = toString(numberObj) converts the number specified by
%    numberObj to formatted text.
%
%    The conversion uses the first of these format specifications that it
%    finds:
%    1. The specification in an mlreportgen.ppt.NumberFormat object in the
%       Style property of the mlreportgen.ppt.Number object specified by
%       numberObj.
%    2. The specification in a NumberFormat object in the Style property of
%       an element, such as a paragraph or table, that contains the
%       specified Number object.
%    3. The default specification set by
%       mlreportgen.ppt.setDefaultNumberFormat.
%
%    If the conversion does not find a format specification, the conversion
%    uses the maximum number of digits needed to represent the number
%    accurately. You can use this method to see the formatted text that
%    results from adding a mlreportgen.ppt.Number object to a presentation.
%
%    Example:
%
%    import mlreportgen.ppt.*
%    numberObj = Number(pi);
%    numberObj.Style = [numberObj.Style {NumberFormat("%0.2f")}];
%    formattedNumber = toString(numberObj);
%
%    See also mlreportgen.ppt.NumberFormat,
%    mlreportgen.ppt.getDefaultNumberFormat,
%    mlreportgen.ppt.setDefaultNumberFormat

%    Copyright 2024 The MathWorks, Inc.
%    Built-in function.