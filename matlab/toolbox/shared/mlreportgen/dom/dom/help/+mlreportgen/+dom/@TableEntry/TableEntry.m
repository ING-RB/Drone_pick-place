%mlreportgen.dom.TableEntry Create a table Entry
%   entryObj = TableEntry() creates an empty table entry.
%
%   entryObj = TableEntry('text') creates a table entry containing a Text 
%   object constructed from the specified text.
%
%   entryObj = TableEntry(number) creates a table entry containing a Number 
%   object constructed from the specified floating-point number or integer.
%
%   entryObj = TableEntry('text','StyleName') creates a table entry 
%   containing a Text object containing the specified text and having 
%   the specified style.
%
%   entryObj = TableEntry(domObj) creates a table entry containing 
%   domObj, where domObj is an object of any of the following types:
%
%       * CustomElement
%       * EmbeddedObject
%       * Image
%       * OrderedList
%       * Paragraph
%       * UnorderedList
%       * Table
%       * Text
%       * Number
%
%   TableEntry methods:
%       append         - Append a MATLAB or DOM object to this part
%       clone          - Clone this part
%
%   TableEntry properties:
%       Border            - Type of border to draw around this entry
%       BorderColor       - Color of border drawn around this entry
%       BorderWidth       - Width of border drawn around this entry
%       Children          - Children of this entry
%       ColSpan           - Number of columns spanned by this entry
%       CustomAttributes  - Custom element attributes
%       Hyphenation       - Hyphenation character (deprecated)
%       Id                - Id of this element
%       InnerMargin       - Inner margin (padding) around this entry
%       Parent            - Parent of this entry
%       RowSpan           - Number of rows spanned by this table entry
%       Style             - Formats that define this element's style
%       StyleName         - Name of element's stylesheet-defined style
%       Tag               - Tag of this element
%       Valign            - Vertical alignment of this table entry
%
%    See also mlreportgen.dom.Table, mlreportgen.dom.FormalTable, 
%    mlreportgen.dom.Hyphenate

%    Copyright 2013-2022 MathWorks, Inc.
%    Built-in class

%{
properties
    %Border Type of border to draw around this table entry. 
    %   Valid types are:  
    %
    %                                                    Applies To
    %   VALID VALUE                 DESCRIPTION          DOCX HTML
    %   'dashed'                    dashed line          X    X
    %   'dashdotstroked'                                 X
    %   'dashsmallgap'              dashed line          X
    %   'dotted'                    dotted line          X    X
    %   'dotdash'                   dot dash line        X
    %   'dotdotdash'                dot dot dash line    X
    %   'double'                    double line          X    X
    %   'doublewave'                double wavy line     X
    %   'inset'                                          X    X
    %   'none'                      no border            X    X
    %   'outset'                                         X    X
    %   'single'                    single line          X
    %   'solid'                     single line               X
    %   'thick'                     thick line           X
    %   'thickthinlargegap'                              X
    %   'thickthinmediumgap'                             X
    %   'thickthinsmallgap'                              X
    %   'thinthicklargegap'                              X
    %   'thinthicksmallgap'                              X
    %   'thinthickmediumgap'                             X
    %   'thinthickthinlargegap'                          X
    %   'thinthickthinmediumgap'                         X
    %   'thinthickthinsmallgap'                          X
    %   'threedemboss'                                   X
    %   'threedengrave'                                  X
    %   'triple'                    triple line          X
    %   'wave'                      wavy line            X
    %
    %   Note: Setting this property adds a corresponding Border format 
    %   object to this entry's Style property. Unsetting this 
    %   property removes the object.
    Border;


    %BorderColor Color of this table entry's border   
    %   The value of this property may be a color name (e.g., 'blue')
    %   or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
    %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
    %    (eg. 'rgb(0,0,255)' corresponds to blue color).
    %
    %   See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
    %   list of valid color names.
    BorderColor;

    %BorderWidth Width of this table entry's border
    %   The value of this property is a string having the 
    %   format valueUnits where Units is an abbreviation for the units 
    %   in which the size is expressed. The following abbreviations are
    %   valid:
    %
    %   Abbreviation  Units
    %   px            pixels
    %   cm            centimeters
    %   in            inches
    %   mm            millimeters
    %   pc            picas
    %   pt            points
    BorderWidth;

    %ColSpan Number of columns spanned by this table entry
    %
    ColSpan;

    %Hyphenation Hyphenation character (deprecated)
    %   This property specifies whether to hyphenate text and, 
    %   optionally, the hyphenation character to use. The property is
    %   specified as one of the following:
    %
    %   - Boolean true or false. If true, a hyphen is used as the 
    %     hyphenation character. If false, hyphenation is not enabled.
    %
    %   - A hyphenation character in the form of a character vector, for 
    %     example, '-' for hyphen or ' ' for space.
    Hyphenation;

    %InnerMargin Inner margin (padding) of this table entry
    %   The value of this property is a string having the 
    %   format valueUnits where Units is an abbreviation for the units 
    %   in which the size is expressed. The following abbreviations are
    %   valid:
    %   
    %   Abbreviation  Units
    %   
    %   px            pixels
    %   cm            centimeters
    %   in            inches
    %   mm            millimeters
    %   pc            picas
    %   pt            points
    %   
    %   Note: setting this property appends an InnerMargin format to 
    %   the Style format array of this table entry.
    InnerMargin;

    %RowSpan Number of rows spanned by this table entry
    RowSpan;

    %VAlign Vertical alignment of table entry's contents
    HAlign;

end
%}