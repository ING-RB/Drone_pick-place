%mlreportgen.dom.TableRow Creates a table row
%    row = TableRow() creates an empty table row.
%
%    TableRow methods:
%        append         - Append entries to this table row
%        clone          - Clone this row
%
%    TableRow properties:
%        Children          - Children of this table row
%        CustomAttributes  - Custom row attributes
%        Entries           - Table entries in this row
%        NEntries          - Number of entries in this row
%        Height            - Height of this row
%        Id                - Id of this row
%        Parent            - Parent of this table row
%        Style             - Formats that define this row's style
%        StyleName         - Name of row's stylesheet-defined style
%        Tag               - Tag of this row
%
%    See also mlreportgen.dom.TableEntry, mlreportgen.dom.Table

%    Copyright 2013-2019 Mathworks, Inc.
%    Built-in class

%{
properties
     %Entries Table entries in this row
     %
     %    The value of this read-only property is an array of handles to
     %    this row's table entries. Use this property to access the
     %    row's table entries.
     %
     %    Example:
     %
     %    import mlreportgen.dom.*
     %    d = Document;
     %    t = Table({'e11', 'e12'; 'e21', 'e22'});
     %    entry22 = row(t,2).Entries(2);
     %    % Note: entry22 = entry(t,2,2); also works
     %    entry22.Style = [entry22.Style {Color('red')}];
     %    append(d,t);
     %    close(d);
     %    rptview(d);
     %    
     %    See also mlreportgen.dom.Table.entry
     Entries;

     %NEntries Number of entries in this row
     %
     %    The value of this read-only property specifies the number of
     %    table entries in this row.
     NEntries;

     %Height Height of this row
     %
     %    The value of this property is a string having the format 
     %    valueUnits where Units is an abbreviation for the units in
     %    which the size is expressed, e.g., '12pt'. The following 
     %    abbreviations are valid:
     %
     %    Abbreviation  Units
     %
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    If this row's Style property includes an 
     %    mlreportgen.dom.RowHeight format, this property displays the
     %    height specified by the format object. If you set this property
     %    to a height value, a RowHeight object of the specified height is
     %    created and added or used to replace an existing RowHeight object
     %    in the row's Style property. The new RowHeight's type is 'exact'.
     %    This causes Word to generate a row of the specified height,
     %    truncating content that does not fit the height. HTML and PDF
     %    viewers create a row of at least the specified height,
     %    adjusting the row height as necessary to accommadate the 
     %    content.
     %
     %    See also mlreportgen.dom.RowHeight
     Height;

end
%}