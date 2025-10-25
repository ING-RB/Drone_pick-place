%toString Converts number to the formatted string based on the NumberFormat 
%object
%    formattedNumber = toString(numberObj) converts the number specified by 
%    numberObj to a formatted string. If the Style property of numberObj is 
%    set to a NumberFormat object, the conversion uses the precision specified 
%    by the NumberFormat object. Otherwise, the conversion uses the maximum 
%    number of digits needed to represent the number accurately.
%
%   Example
%
%   import mlreportgen.dom.*
%   numberObj = Number(pi);
%   numberObj.Style = {NumberFormat('%0.2f')};
%   formattedNumber = toString(numberObj);

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.
