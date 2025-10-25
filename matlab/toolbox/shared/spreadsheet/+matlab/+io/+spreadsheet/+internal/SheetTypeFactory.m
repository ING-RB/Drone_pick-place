classdef SheetTypeFactory
% 

%Copyright 2021 The MathWorks, Inc.

    properties (Constant)
        InvalidSheetNameChars = [":", "\", "/", "?", "*", "[", "]"];
        MaxSheetIndex = double(intmax("int32"));
        MaxSheetNameLength = 31;
    end

    methods (Static)

        function sheetType = makeSheetType(sheetNameOrIndex)
            import matlab.io.spreadsheet.internal.SheetTypeFactory
            import matlab.io.spreadsheet.internal.SheetType

            sheetType = SheetType.Invalid;

            if SheetTypeFactory.isEmptySheetName(sheetNameOrIndex)
                sheetType = SheetType.Empty;
            elseif SheetTypeFactory.isValidSheetIndex(sheetNameOrIndex)
                sheetType = SheetType.Index;
            elseif SheetTypeFactory.isValidSheetName(sheetNameOrIndex)
                sheetType = SheetType.Name;
            end
        end

        function tf = isEmptySheetName(sheetNameOrIndex)
            isEmptyChar = ischar(sheetNameOrIndex) && isempty(sheetNameOrIndex);
            isEmptyString = isstring(sheetNameOrIndex) && isscalar(sheetNameOrIndex) && sheetNameOrIndex == "";
            tf = isEmptyChar || isEmptyString;
        end

        function tf = isValidSheetName(sheetName)
            import matlab.io.spreadsheet.internal.SheetTypeFactory

            tf = matlab.internal.datatypes.isScalarText(sheetName) && ...
                strlength(sheetName) > 0 && ...
                strlength(sheetName) <= SheetTypeFactory.MaxSheetNameLength && ...
                ~contains(sheetName, SheetTypeFactory.InvalidSheetNameChars);
        end

        function tf = isValidSheetIndex(sheetIndex)
            import matlab.io.spreadsheet.internal.SheetTypeFactory
            import matlab.io.internal.common.isNonNegativeScalarInt

            tf = isNonNegativeScalarInt(sheetIndex);

            if tf
                sheetIndex = double(sheetIndex);
                tf = (sheetIndex > 0) && (sheetIndex <= SheetTypeFactory.MaxSheetIndex);
            end
        end

    end

end
