%mlreportgen.dom.Border Border of a DOM object
%    border = Border() creates an unspecified border.
%
%    border = Border('style') creates a border of the specified style.
%    See mlreportgen.dom.Border.Style for a list of valid border styles.
%
%    border = Border('style', 'color') creates a border having the 
%    specified style and color. See mlreportgen.dom.Border.Color for
%    information on specifying border color.
%
%    border = Border('style', 'color', 'width') creates a border having the 
%    specified style, color, and width. See mlreportgen.dom.Border.Width
%    for information on specifying border width.  
%
%    Border properties:
%        BottomColor - Color of bottom border segment
%        BottomStyle - Style of bottom border segment
%        BottomWidth - Width of bottom border segment
%        Color       - Default color of border segments
%        Id          - Id of this object
%        LeftColor   - Color of left border segment
%        LeftStyle   - Style of left border segment
%        LeftWidth   - Width of left border segment
%        RightColor  - Color of right border segment
%        RightStyle  - Style of right border segment
%        RightWidth  - Width of right border segment
%        Style       - Default style of border segments
%        Tag         - Tag of this object
%        TopColor    - Color of top border segment
%        TopStyle    - Style of top border segment
%        TopWidth    - Width of top border segment
%        Width       - Default width of border segments
%
%    Example:
%
%    import mlreportgen.dom.*;
%    doctype = 'html';
%    d = Document('test', doctype);
%    t = Table(magic(5));
%    t.Style = {Border('inset', 'crimson', '6pt'), Width('50%')};
%    t.TableEntriesInnerMargin = '6pt';
%    t.TableEntriesHAlign = 'center';
%    t.TableEntriesVAlign = 'middle';
%    append(d, t);
%    close(d);
%    rptview('test', doctype);
%
%    See also mlreportgen.dom.ColSep, mlreportgen.dom.RowSep

%    Copyright 2014-2022 MathWorks, Inc.
%    Built-in class

%{
properties
     %BottomColor Color of bottom border segment
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     BottomColor;

     %BottomStyle Style of bottom border segment
     %    Valid styles are:  
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION	      DOCX HTML/PDF
     %    'dashed'                    dashed line          X    X
     %    'dashdotstroked'                                 X
     %    'dashsmallgap'              dashed line          X
     %    'dotted'                    dotted line          X    X
     %    'dotdash'                   dot dash line        X	 	
     %    'dotdotdash'                dot dot dash line    X
     %    'double'                    double line          X    X
     %    'doublewave'                double wavy line     X 	
     %    'inset'                                          X    X
     %    'none'                      no border            X    X
     %    'outset'                                         X    X
     %    'single'                    single line          X
     %    'solid'                     single line               X
     %    'thick'                     thick line           X
     %    'thickthinlargegap'                              X
     %    'thickthinmediumgap'                             X
     %    'thickthinsmallgap'                              X
     %    'thinthicklargegap'                              X
     %    'thinthicksmallgap'                              X
     %    'thinthickmediumgap'                             X
     %    'thinthickthinlargegap'                          X
     %    'thinthickthinmediumgap'                         X
     %    'thinthickthinsmallgap'                          X
     %    'threedemboss'                                   X
     %    'threedengrave'                                  X
     %    'triple'                    triple line          X
     %    'wave'                      wavy line            X
     BottomStyle;

     %BottomWidth Width of bottom border segment
     %
     %    The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The width values supported by Word depend on the border
     %    style in the following instances:
     %
     %    STYLE                     VALID WIDTH VALUES
     %    'dashdotstroked'          3pt
     %    'wave'                    0.75pt to 1.5pt
     %    'doubleWave'              0.75pt
     %    'thinthickthinmediumgap'  0.25pt to 4.5pt
     %    'thinthickthinsmallgap'   1.5pt to 6pt
     %    'threedemboss'            0.75pt to 6pt
     %    'threedengrave'           0.75pt to 6pt
     %
     %    If you specify an invalid width for a border style, the Border
     %    object throws an error.
     BottomWidth;

     %Color Default color of border segments
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     Color;

     %LeftColor Color of left border segment
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     LeftColor;

     %LeftStyle Style of left border segment
     %    Valid styles are:  
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION	      DOCX HTML/PDF
     %    'dashed'                    dashed line          X    X
     %    'dashdotstroked'                                 X
     %    'dashsmallgap'              dashed line          X
     %    'dotted'                    dotted line          X    X
     %    'dotdash'                   dot dash line        X	 	
     %    'dotdotdash'                dot dot dash line    X
     %    'double'                    double line          X    X
     %    'doublewave'                double wavy line     X 	
     %    'inset'                                          X    X
     %    'none'                      no border            X    X
     %    'outset'                                         X    X
     %    'single'                    single line          X
     %    'solid'                     single line               X
     %    'thick'                     thick line           X
     %    'thickthinlargegap'                              X
     %    'thickthinmediumgap'                             X
     %    'thickthinsmallgap'                              X
     %    'thinthicklargegap'                              X
     %    'thinthicksmallgap'                              X
     %    'thinthickmediumgap'                             X
     %    'thinthickthinlargegap'                          X
     %    'thinthickthinmediumgap'                         X
     %    'thinthickthinsmallgap'                          X
     %    'threedemboss'                                   X
     %    'threedengrave'                                  X
     %    'triple'                    triple line          X
     %    'wave'                      wavy line            X
     LeftStyle;

     %LeftWidth Width of left border segment
     %
     %    The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The width values supported by Word depend on the border
     %    style in the following instances:
     %
     %    STYLE                     VALID WIDTH VALUES
     %    'dashdotstroked'          3pt
     %    'wave'                    0.75pt to 1.5pt
     %    'doubleWave'              0.75pt
     %    'thinthickthinmediumgap'  0.25pt to 4.5pt
     %    'thinthickthinsmallgap'   1.5pt to 6pt
     %    'threedemboss'            0.75pt to 6pt
     %    'threedengrave'           0.75pt to 6pt
     %
     %    If you specify an invalid width for a border style, the Border
     %    object throws an error.
     LeftWidth;

     %RightColor Color of right border segment
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     RightColor;

     %RightStyle Style of right border segment
     %    Valid styles are:  
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION	      DOCX HTML/PDF
     %    'dashed'                    dashed line          X    X
     %    'dashdotstroked'                                 X
     %    'dashsmallgap'              dashed line          X
     %    'dotted'                    dotted line          X    X
     %    'dotdash'                   dot dash line        X	 	
     %    'dotdotdash'                dot dot dash line    X
     %    'double'                    double line          X    X
     %    'doublewave'                double wavy line     X 	
     %    'inset'                                          X    X
     %    'none'                      no border            X    X
     %    'outset'                                         X    X
     %    'single'                    single line          X
     %    'solid'                     single line               X
     %    'thick'                     thick line           X
     %    'thickthinlargegap'                              X
     %    'thickthinmediumgap'                             X
     %    'thickthinsmallgap'                              X
     %    'thinthicklargegap'                              X
     %    'thinthicksmallgap'                              X
     %    'thinthickmediumgap'                             X
     %    'thinthickthinlargegap'                          X
     %    'thinthickthinmediumgap'                         X
     %    'thinthickthinsmallgap'                          X
     %    'threedemboss'                                   X
     %    'threedengrave'                                  X
     %    'triple'                    triple line          X
     %    'wave'                      wavy line            X
     RightStyle;

     %RightWidth Width of right border segment
     %
     %    The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The width values supported by Word depend on the border
     %    style in the following instances:
     %
     %    STYLE                     VALID WIDTH VALUES
     %    'dashdotstroked'          3pt
     %    'wave'                    0.75pt to 1.5pt
     %    'doubleWave'              0.75pt
     %    'thinthickthinmediumgap'  0.25pt to 4.5pt
     %    'thinthickthinsmallgap'   1.5pt to 6pt
     %    'threedemboss'            0.75pt to 6pt
     %    'threedengrave'           0.75pt to 6pt
     %
     %    If you specify an invalid width for a border style, the Border
     %    object throws an error.
     RightWidth;

     %Style Default style of border segments
     %    Valid styles are:  
     %                                                    Applies To
     %    STYLE                       DESCRIPTION	      DOCX HTML/PDF
     %    'dashed'                    dashed line          X    X
     %    'dashdotstroked'                                 X
     %    'dashsmallgap'              dashed line          X
     %    'dotted'                    dotted line          X    X
     %    'dotdash'                   dot dash line        X	 	
     %    'dotdotdash'                dot dot dash line    X
     %    'double'                    double line          X    X
     %    'doublewave'                double wavy line     X 	
     %    'inset'                                          X    X
     %    'none'                      no border            X    X
     %    'outset'                                         X    X
     %    'single'                    single line          X
     %    'solid'                     single line               X
     %    'thick'                     thick line           X
     %    'thickthinlargegap'                              X
     %    'thickthinmediumgap'                             X
     %    'thickthinsmallgap'                              X
     %    'thinthicklargegap'                              X
     %    'thinthicksmallgap'                              X
     %    'thinthickmediumgap'                             X
     %    'thinthickthinlargegap'                          X
     %    'thinthickthinmediumgap'                         X
     %    'thinthickthinsmallgap'                          X
     %    'threedemboss'                                   X
     %    'threedengrave'                                  X
     %    'triple'                    triple line          X
     %    'wave'                      wavy line            X
     %
     %    Note: In Microsoft Word output, the inset and outset border styles 
     %    apply only to tables. In Word, PDF, and HTML output, the inset and 
     %    output styles apply only to tables whose entries are spaced apart. 
     %    Use mlreportgen.dom.TableEntrySpacing format to specify table entry spacing.
     Style;

     %TopColor Color of top border segment
     %    The value of this property may be a color name (e.g., 'blue')
     %    or a hexadecimal RGB value (e.g., '#0000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/wiki/CSS/Properties/color/keywords for a
     %    list of valid color names.
     TopColor;

     %TopStyle Style of top border segment
     %    Valid styles are:  
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION	      DOCX HTML/PDF
     %    'dashed'                    dashed line          X    X
     %    'dashdotstroked'                                 X
     %    'dashsmallgap'              dashed line          X
     %    'dotted'                    dotted line          X    X
     %    'dotdash'                   dot dash line        X	 	
     %    'dotdotdash'                dot dot dash line    X
     %    'double'                    double line          X    X
     %    'doublewave'                double wavy line     X 	
     %    'inset'                                          X    X
     %    'none'                      no border            X    X
     %    'outset'                                         X    X
     %    'single'                    single line          X
     %    'solid'                     single line               X
     %    'thick'                     thick line           X
     %    'thickthinlargegap'                              X
     %    'thickthinmediumgap'                             X
     %    'thickthinsmallgap'                              X
     %    'thinthicklargegap'                              X
     %    'thinthicksmallgap'                              X
     %    'thinthickmediumgap'                             X
     %    'thinthickthinlargegap'                          X
     %    'thinthickthinmediumgap'                         X
     %    'thinthickthinsmallgap'                          X
     %    'threedemboss'                                   X
     %    'threedengrave'                                  X
     %    'triple'                    triple line          X
     %    'wave'                      wavy line            X
     TopStyle;

     %TopWidth Width of top border segment
     %
     %    The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The width values supported by Word depend on the border
     %    style in the following instances:
     %
     %    STYLE                     VALID WIDTH VALUES
     %    'dashdotstroked'          3pt
     %    'wave'                    0.75pt to 1.5pt
     %    'doubleWave'              0.75pt
     %    'thinthickthinmediumgap'  0.25pt to 4.5pt
     %    'thinthickthinsmallgap'   1.5pt to 6pt
     %    'threedemboss'            0.75pt to 6pt
     %    'threedengrave'           0.75pt to 6pt
     %
     %    If you specify an invalid width for a border style, the Border
     %    object throws an error.
     TopWidth;

     %Width Default width of border segments
     %
     %    The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The width values supported by Word depend on the border
     %    style in the following instances:
     %
     %    STYLE                     VALID WIDTH VALUES
     %    'dashdotstroked'          3pt
     %    'wave'                    0.75pt to 1.5pt
     %    'doubleWave'              0.75pt
     %    'thinthickthinmediumgap'  0.25pt to 4.5pt
     %    'thinthickthinsmallgap'   1.5pt to 6pt
     %    'threedemboss'            0.75pt to 6pt
     %    'threedengrave'           0.75pt to 6pt
     %
     %    If you specify an invalid width for a border style, the Border
     %    object throws an error.
     Width;

end
%}