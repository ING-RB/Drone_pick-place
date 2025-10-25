%mlreportgen.dom.RowHeight Height of a table row
%    heightObj = RowHeight() specifies a row that is exactly 1in high.
%
%    heightObj = RowHeight('height') sets a row to exactly the specified
%    height.
%
%    heightObj = RowHeight('height', 'type') sets a row to be either
%    exactly the specified height (type = 'exact') or at least the
%    specified height (type = 'atleast').
%
%    Note: This format enables you to specify an exact (fixed) row height
%    in Word output. If the row content is too big to fit in the specified
%    height, Word truncates the content to preserve the specified height.
%    For PDF and HTML output, the behavior of the format is the same as
%    mlreportgen.dom.Height format. In both cases, the document treats the
%    specified height as a minimum to be adjusted upward as necessary to
%    accommodate content. If you do not need to specify an exact height,
%    you can use either RowHeight or Height to specify the height.
%
%    RowHeight properties:
%        Id    - Id of this object
%        Tag   - Tag of this object
%        Type  - Type of row height
%        Value - Row height
%
%    Example:
%
%    % Create a row that is exactly 1-inch high
%    import mlreportgen.dom.*;
%    r = TableRow();
%    r.Style = {RowHeight};
%
%    See also mlreportgen.dom.Height, mlreportgen.dom.TableRow.

%    Copyright 2014-2019 Mathworks, Inc.
%    Built-in class

%{
properties

     %Type Type of row height
     %
     %    Specifies how the value of this object's Value property is to be
     %    interpreted by Word, PDF, and HTML documents, respectively:
     %
     %        * 'exact'    - Value property specifies the exact line 
     %                       row height. If the row content is too big to 
     %                       fit in the specified height, Word trunccates
     %                       the content to preserve the specified height.
     %                       PDF and HTML documents adjust the row height
     %                       as necessary to accommodate the row content.
     %      
     %        * 'atleast'  - Value is the minimum row height. If the 
     %                       row content is too big to fit in the specified
     %                       height, Word, PDF, and HTML adjust the row 
     %                       height to accommodate the content. 
     Type;

     %Value Height of row
     %
     %    The value of this property is a string having the format 
     %    valueUnits where Units is an abbreviation for the units in
     %    which the size is expressed. The following abbreviations are
     %    valid:
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
     Value;
end
%}