%mlreportgen.dom.Number Convert a number to text
%    numberObj = Number(number) creates an object that represents the specified number
%    as text. The type of the number argument must be a MATLAB numeric type, such as
%    double. By default the number-to-text conversion uses the maximum number of digits
%    needed to represent the number accurately (as many as 17 digits for irrational
%    numbers). To specify a different precision, include a NumberFormat object
%    in this object's Style property.
%
%    numberObj = Number(number,stylename) creates an object that represents the
%    specified number as text having the style specified by 'stylename'. The style 
%    must be defined in the stylesheet of the template of the document to 
%    which this number object is appended.
%
%    numberObj = Number() creates an empty Number object. Use the object's Value 
%    property to specify a number to be represented as text.
%
%    Number methods:
%        append         - Append a custom element to this number object
%        clone          - Clone this number object
%        toString       - Converts number to the formatted string based on 
%                         the NumberFormat object
%
%    Number properties:
%        Value             - Number to be represented as text
%        Children          - Children of this number
%        CustomAttributes  - Custom element attributes
%        Id                - Id of this number
%        Parent            - Parent of this number
%        Style             - Formats that define the number's text style
%        StyleName         - Name of this numbers's stylesheet-defined text style
%        Tag               - Tag of this number
%
%   Example
%
%   % Convert pi to '3.14'.
%   import mlreportgen.dom.*
%   n = Number(pi);
%   n.Style = {NumberFormat('%0.2f')};

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Value numeric value of this number object
     %     Number to convert to formatted text, specified as a scalar.
     Value;
end
%}