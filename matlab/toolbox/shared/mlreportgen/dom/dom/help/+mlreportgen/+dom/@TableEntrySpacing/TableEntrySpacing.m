%mlreportgen.dom.TableEntrySpacing Distance between the borders of adjoining
%table cells
%    tableEntrySpacing = TableEntrySpacing() creates cell spacing format of 0.03 inches.
%
%    tableEntrySpacing = TableEntrySpacing('value') creates cell spacing format of specified value.
%    The 'value' argument is a string having the format valueUnits where Units 
%    is an abbreviation for the units in which the size is expressed.
%    The following abbreviations are valid:
%
%    Note: For PDF and HTML reports, this format is only applicable when
%    BorderCollapse property of the table is set to 'off'.
%
%    Abbreviation  Units
%    px            pixels
%    cm            centimeters
%    in            inches
%    mm            millimeters
%    pc            picas
%    pt            points
%    
%    TableEntrySpacing properties:
%        Id    - Id of this object
%        Tag   - Tag of this object
%        Value - Cell spacing value
%
%    Example:
%
%     import mlreportgen.dom.*;  
%     doctype = "html-file";
%     d = Document("Table_with_cell_spacing",doctype);
%     table = Table(magic(5));
%     border = Border("inset");
%     border.Width = "1pt";
%     table.Style = {border,TableEntrySpacing("0.3in"),BorderCollapse("off"),BackgroundColor("lightblue"),Width("50%")};
%     table.TableEntriesStyle = {border};
%     append(d,table);
%     close(d);
%     rptview(d);
%     See also mlreportgen.dom.Border, mlreportgen.dom.BorderCollapse

%    Copyright 2021 MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Value of tableEntrySpacing
     %
     %    Value is a string having the format valueUnits where Units is 
     %    an abbreviation for the units in which the size is expressed. 
     %    The following abbreviations are valid:
     %
     %    Abbreviation  Units
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     Value;
end
%}