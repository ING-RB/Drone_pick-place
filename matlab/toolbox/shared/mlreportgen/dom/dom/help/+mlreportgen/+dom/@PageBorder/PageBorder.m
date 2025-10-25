%mlreportgen.dom.PageBorder Border of pages in a Word or PDF layout
%    pageBorder = PageBorder() creates a page border object with default
%    properties where all the segments are solid, black, and 0.5 point
%    wide, the top and bottom segments are one point from the page margins, 
%    and the left and right segments are four points from the page margins.
%
%    pageBorder = PageBorder(style) creates a page border with the specified
%    style. See mlreportgen.dom.PageBorder.Style for a list of valid page border
%    styles.
%
%    pageBorder = PageBorder(style,color) creates a page border having
%    the specified style and color. See mlreportgen.dom.PageBorder.Color for
%    information on specifying page border color.
%
%    pageBorder = PageBorder(style,color,width) creates a page border
%    having the specified style, color, and width. See mlreportgen.dom.PageBorder.Width
%    for information on specifying page border width.
%
%    pageBorder = PageBorder(style,color,width,margin) creates a
%    page border having the specified style, color, width, and margin. See
%    mlreportgen.dom.PageBorder.Margin for information on specifying page border margin.
%
%    PageBorder properties:
%        Style          - Default style of page border segments
%        Color          - Default color of page border segments
%        Width          - Default width of page border segments
%        Margin         - Default margin of page border segments
%        MeasureFrom    - Relative positioning of the page border
%        SurroundHeader - Whether the page border surrounds the header region
%        SurroundFooter - Whether the page border surrounds the footer region
%        TopStyle       - Style of top page border segment
%        TopColor       - Color of top page border segment
%        TopWidth       - Width of top page border segment
%        TopMargin      - Margin of top page border segment
%        LeftStyle      - Style of left page border segment
%        LeftColor      - Color of left page border segment
%        LeftWidth      - Width of left page border segment
%        LeftMargin     - Margin of left page border segment
%        BottomStyle    - Style of bottom page border segment
%        BottomColor    - Color of bottom page border segment
%        BottomWidth    - Width of bottom page border segment
%        BottomMargin   - Margin of bottom page border segment
%        RightStyle     - Style of right page border segment
%        RightColor     - Color of right page border segment
%        RightWidth     - Width of right page border segment
%        RightMargin    - Margin of right page border segment
%        Tag            - Tag of this object
%        Id             - Id of this object
%
%    Example:
%
%    import mlreportgen.dom.*;
%    d = Document("test","docx");
%    open(d);
%    pageBorder = PageBorder("solid","red","0.5pt");
%    pageBorder.MeasureFrom = "pageboundary";
%    d.CurrentPageLayout.PageBorder = pageBorder;
%    append(d,"This page has a 0.5pt solid red page border.");
%    close(d);
%    rptview(d);
%
%    See also mlreportgen.dom.PageSize, mlreportgen.dom.PageMargins,
%    mlreportgen.dom.DOCXPageLayout, mlreportgen.dom.PDFPageLayout

%    Copyright 2021-2022 MathWorks, Inc.
%    Built-in class

%{
properties
     %Style Default style of page border segments. Use either a character
     %    vector or a string scalar to set the value of this property.
     %
     %    Valid styles are:
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION         DOCX PDF
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
     Style;
     
     %Color Default color of page border segments
     %
     %    The value of this property is a character vector that specifies a 
     %    color name (e.g., "blue") or a hexadecimal RGB value
     %    (e.g., 'e.g., '#000ff'). or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/TR/2018/REC-css-color-3-20180619/ for a list
     %    of valid color names.
     Color;
     
     %Width Default width of page border segments
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
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
     %    If you specify an invalid width for a border style, the
     %    PageBorder object throws an error.
     Width;
     
     %Margin Default margin of page border segments
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     Margin;
     
     %MeasureFrom Specifies the relative positioning of the page border
     %
     %      Valid values:
     %
     %      pageboundary  -  Specifies the margin between the page boundary 
     %                       and the top, bottom, left, and right edges
     %                       of the page border. This property applies only
     %                       to Word reports.
     %      text          -  Specifies the space between the top, bottom,
     %                       left, and right edges of page border and page
     %                       margins.
     MeasureFrom;

     %SurroundHeader Whether page border surrounds header region
     %
     %      Valid values:
     %
     %      true  - (default) page border surrounds header region
     %      false - page border does not surround header region
     %
     %      Note: This property applies only when the MeasureFrom property
     %      is set to "text". For DOCX output this property applies to the
     %      entire document. For example, if you have a report with
     %      multiple sections, and if this property is set to false for any
     %      section in the report then the page border does not enclose the
     %      header of all the sections in the report.
     SurroundHeader;

     %SurroundFooter Whether page border surrounds footer region
     %
     %      Valid values:
     %
     %      true  - (default) page border surrounds footer region
     %      false - page border does not surround footer region
     %
     %      Note: This property applies only when the MeasureFrom property 
     %      is set to "text". For DOCX output this property applies to the
     %      entire document. For example, if you have a report with
     %      multiple sections, and if this property is set to false for any
     %      section in the report then the page border does not enclose the
     %      header of all the sections in the report.
     SurroundFooter;

     %TopStyle Style of top page border segment. Use either a character
     %    vector or a string scalar to set the value of this property. 
     %
     %    Valid styles are:
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION         DOCX PDF
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
     
     %TopColor Color of top page border segment
     %
     %    The value of this property is a character vector that specifies a 
     %    color name (e.g., "blue") or a hexadecimal RGB value
     %    (e.g., 'e.g., '#000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/TR/2018/REC-css-color-3-20180619/ for a list
     %    of valid color names.
     TopColor;
     
     %TopWidth Width of top page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
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
     %    If you specify an invalid width for a border style, the
     %    PageBorder object throws an error.
     TopWidth;

     %TopMargin Margin of top page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     TopMargin;

     %BottomStyle Style of bottom  page border segment. Use either a character
     %    vector or a string scalar to set the value of this property.
     %
     %    Valid styles are:
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION         DOCX PDF
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
          
     %BottomColor Color of bottom page border segment
     %
     %    The value of this property is a character vector that specifies a 
     %    color name (e.g., "blue") or a hexadecimal RGB value
     %    (e.g., 'e.g., '#000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/TR/2018/REC-css-color-3-20180619/ for a list
     %    of valid color names.
     BottomColor;
     
     %BottomWidth Width of bottom page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations are
     %    are valid:
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
     %    If you specify an invalid width for a border style, the
     %    PageBorder object throws an error.
     BottomWidth;

     %BottomMargin Margin of bottom page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     BottomMargin;

     %LeftStyle Style of left page border segment. Use either a character
     %    vector or a string scalar to set the value of this property.
     %
     %    Valid styles are:
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION         DOCX PDF
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
     
     %LeftColor Color of left page border segment
     %
     %    The value of this property is a character vector that specifies a 
     %    color name (e.g., "blue") or a hexadecimal RGB value
     %    (e.g., 'e.g., '#000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/TR/2018/REC-css-color-3-20180619/ for a list
     %    of valid color names.
     LeftColor;

     %LeftWidth Width of left page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
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
     %    If you specify an invalid width for a border style, the
     %    PageBorder object throws an error.
     LeftWidth;
     
     %LeftMargin Margin of bottom page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     LeftMargin;
     
     %RightStyle Style of right page border segment. Use either a character
     %    vector or a string scalar to set the value of this property.
     %
     %    Valid styles are:
     %
     %                                                    Applies To
     %    STYLE                       DESCRIPTION         DOCX PDF
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
     
     %RightColor Color of right page border segment
     %
     %    The value of this property is a character vector that specifies a 
     %    color name (e.g., "blue") or a hexadecimal RGB value
     %    (e.g., 'e.g., '#000ff') or an RGB triplet 
     %    (eg. [0 0 1] corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %    See https://www.w3.org/TR/2018/REC-css-color-3-20180619/ for a list
     %    of valid color names.
     RightColor;

     %RightWidth Width of right page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
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
     %    If you specify an invalid width for a border style, the
     %    PageBorder object throws an error.
     RightWidth;

     %RightMargin Margin of bottom page border segment
     %
     %    The value of this property is a string scalar or character vector
     %    having the format valueUnits where Units is an abbreviation for
     %    the units in which the size is expressed. The following abbreviations
     %    are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     RightMargin;

    
     
end
%}