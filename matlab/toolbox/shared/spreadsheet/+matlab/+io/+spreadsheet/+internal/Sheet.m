classdef (Abstract) Sheet < handle
    % SHEET The Worksheet for a spreadsheet application.
    %   Contains methods to create and manipulate ranges with respect to
    %   the sheet.
    %
    
    %   Copyright 2015-2024 The MathWorks, Inc.

    properties (Constant, Hidden)
        % Cell type constant for empty cells.
        EMPTY    = uint8(0);
        % Cell type constant for number cells.
        NUMBER   = uint8(1);
        % Cell type constant for string cells.
        STRING   = uint8(2);
        % Cell type constant for datetime cells.
        DATETIME = uint8(3);
        % Cell type constant for boolean cells.
        BOOLEAN  = uint8(4);
        % Cell type constant for blank cells.
        BLANK    = uint8(5);
        % Cell type constant for error cells.
        ERROR    = uint8(6);
        % Cell type constant for duration cells.
        DURATION = uint8(8);
    end

    properties (Abstract, GetAccess = public, SetAccess = public)
        % The name of the sheet
        Name
    end
    
    properties (Abstract, GetAccess = public, SetAccess = private)        
        % Type of the sheet (e.g. Worksheet, Chart)
        Type
        
        % Logical scalar indicating if the sheet is protected
        Protected
        
        % Sheet visibility (Visible, Hidden, VeryHidden)
        HiddenState
    end
    
    methods (Abstract)
        %
        % CLEAR(sheet)
        %
        %   Clear the contents of the sheet.
        %
        % CLEAR(sheet, range)
        %
        %   Clear the contents of the sheet in the cells denoted by range.
        %
        clear(sheet, range)
        
        %
        % range = USEDRANGE(sheet)
        %
        %   Return the used range of this sheet, which is the range
        %   occupied by the data in the sheet.
        %
        range = usedRange(sheet)
        
        %
        % range = GETRANGE(sheet, rangeStrAB)
        % range = GETRANGE(sheet, rangeVector)
        %
        %   Get a range object representing the range denoted by the the
        %   range string rangeStrAB (in AX:BY notation) or a range vector.
        %
        %   Range vector is a 4 element row-vector containing 1 based
        %   indexes. e.g. [4, 5, 6, 7] represents a range starting at the
        %   4th row, 5th column of the sheet spanning the next 6 rows and 7
        %   columns.
        %
        range = getRange(sheet, range)
        
        %
        % range = GETNAMEDRANGE(sheet, name)
        %
        %   Get a range object representing the named range denoted by the
        %   name.
        %
        range = getNamedRange(sheet, name)
        
        %
        % t = TYPES(sheet, range)
        %
        %   Get a UINT8 array specifying the types of the data in the cells
        %   represented by range. The values can be compared using the constants
        %   defined in the sheet class, e.g.
        %
        %   t = types(sheet, usedRange(sheet));
        %   nums = t == sheet.NUMBER;
        %
        types = types(sheet, range)

        %
        % data = READ(sheet)
        %
        %   Returns the data in the used range of the sheet as a 2-D cell array.
        %   The types of data in the cell are governed by the output of the types()
        %   method of the sheet.
        %
        %   EMPTY     - NaN scalar
        %   NUMBER    - double scalar
        %   STRING    - char array
        %   DATETIME  - char array specifying the date and time
        %   BOOLEAN   - logical scalar
        %   BLANK     - NaN scalar
        %   ERROR     - NaN scalar
        %
        % data = READ(sheet, range)
        %
        %   Read the data same as above, but only read the cells specified by
        %   range.
        %
        % data = READ(sheet, range, types)
        %
        %   Read the data same as above, but only read the cells specified by
        %   range, and the types. The types must be obtained by calling the
        %   TYPES method on the same range.
        %
        % See also matlab.io.spreadsheet.internal.Sheet/types
        %
        out = read(sheet, range, types)
        
        %
        % WRITE(sheet, data)
        %
        %   Writes the data starting in the first cell of the sheet.
        %   The types of data in the sheet are governed by the data type in the cell array.
        %
        %   double         - NUMBER
        %   numeric types  - NUMBER
        %   char array     - STRING
        %   matlab String  - STRING
        %   logical scalar - BOOLEAN
        %
        % WRITE(sheet, data, range, preserveformat)
        %
        %   Write the data using the first corner of the range as a start cell. 
        %   If the second half of the range is specified, it is ignored.
        %
        %   preserveformat TRUE preserves the existing formatting of the cell being written.
        %   preserveformat FALSE removes any existing formatting of the cell being written.
        %
        % See also matlab.io.spreadsheet.internal.Sheet/types
        %
        write(sheet, data, range, preserveformat)
        
        %
        % range = GETDATASPAN(sheet, range)
        % range = GETDATASPAN(sheet)
        %
        %  Return the range / dataspan for a sheet.
        %  This value is calculated only once per sheet & cached on the
        %  sheet object. Can only be used with a LibXL object i.e with mode
        %  'UseExcel' as false.
        %
        getDataSpan(sheet, range)
        
        %
        % types = GETTYPES(sheet)
        %
        %   Get a UINT8 array specifying the types of the data in the cells
        %   represented by range where range = GETDATARANGE(sheet).
        %   This value is calculated only once per sheet & cached on the
        %   sheet object. Can only be used with a LibXL object i.e with mode
        %   'UseExcel' as false.
        %
        getTypes(sheet)

        % types = prefetch(sheet)
        %
        %   Get a UINT8 array specifying the types of the data in the cells
        %   represented by range where range = GETDATARANGE(sheet).
        %   This value is calculated only once per sheet & cached on the
        %   sheet object. Can only be used with a GSHEET object. Done as a
        %   performance optimization for detectImportOptions.
        %
        types = prefetch(sheet)

        % tf = is_format_gsheet(sheet)
        %
        %   Determine whether the sheet is of type GSHEET or Excel
        tf = is_format_gsheet(sheet)
    end
end
