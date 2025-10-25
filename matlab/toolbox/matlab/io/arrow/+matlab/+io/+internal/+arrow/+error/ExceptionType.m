classdef ExceptionType
%EXCEPTIONTYPE Enumeration specifying the type of an exception.

% Copyright 2022 The MathWorks, Inc.

    enumeration
        ComplexNumber
        ExceedsMaxNestingLevel
        IncompatibleTimeZone
        InvalidCellElementDims
        InvalidCellstrDims
        InvalidDataType
        InvalidNDCharArray
        NonColumnarArray
        NonScalarMissing
        NonUniformCell
        NonUniformCharWidth
        NonUniformVarNames
        OrdinalCategoriesMismatch
        OrdinalMismatch
        RowNamesMismatch
        RowNamesLabelMismatch
        RowTimesLabelMismatch
        SparseArray
        ZeroVariableTable
        DatetimeOutOfRange
        Unknown % Fail-safe
    end
end

