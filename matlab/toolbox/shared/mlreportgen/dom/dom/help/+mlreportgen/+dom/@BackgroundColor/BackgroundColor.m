%mlreportgen.dom.BackgroundColor Background color of a document object
%    colorObj = BackgroundColor() creates a white background.
%
%    colorObj = BackgroundColor('name') creates a background color of the 
%    specified name.
%
%    The name must be a CSS color name. See 
%    https://www.w3.org/wiki/CSS/Properties/color/keywords for a list
%    of valid CSS color names.
%    
%    colorObj = BackgroundColor('#RRGGBB') creates a background color specified by 
%    a hexadecimal rgb value.
%
%    colorObj = BackgroundColor("rgb(r,g,b)") creates a background color specified by 
%    an rgb triplet such that r,g,b values are in between 0 to 255.
%
%    colorObj = BackgroundColor([x y z]) creates a background color specified by an rgb 
%    triplet [x y z] such that each of them is decimal number between 0 and 1.
%
%    BackgroundColor properties:
%        HexValue - Hexadecimal rgb value of this color (read-only)
%        Id       - Id of this color object
%        Tag      - Tag of this color object
%        Value    - Name or hexadecimal rgb value or rgb triplet of this color
%
%    Example:
%
%    import mlreportgen.dom.*;
%    doctype = 'html';
%    d = Document('test', doctype);
%    blue = 'DeepSkyBlue';
%    % blue = '#00BFFF';
%    colorfulStyle = {Bold, Color(blue), BackgroundColor('Yellow')};
%    p = Paragraph('deep sky blue paragraph with yellow background');
%    p.Style = colorfulStyle;
%    append(d, p);
%    close(d);
%    rptview('test', doctype);
%
%    See also mlreportgen.dom.Color

%    Copyright 2014-2022 MathWorks, Inc.
%    Built-in class

%{
properties
     %Value Background color name or rgb value
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color)
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     Value;

     %HexValue Hex value represented by a color name (read-only)
     %     This property specifies the hex rgb value of the Value
     %     property. If the Value property is itself a hex rgb value,
     %     the two values are identical.
     HexValue;
end
%}