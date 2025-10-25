classdef ExceptionFactory
%EXCEPTIONFACTORY Creates and throws exceptions related to
% Arrow / Parquet functionality.

% Copyright 2022 The MathWorks, Inc.

    methods(Static)
        function throw(exceptionType, varargin)
            import matlab.io.internal.arrow.error.ExceptionType
            import matlab.io.internal.arrow.error.ExceptionFactory

            switch(exceptionType)
              case ExceptionType.ComplexNumber
                ExceptionFactory.throwComplexNumber();
              case ExceptionType.ExceedsMaxNestingLevel
                ExceptionFactory.throwExceedsMaxNestingLevel();
              case ExceptionType.IncompatibleTimeZone
                ExceptionFactory.throwIncompatibleTimeZone(varargin{:});
              case ExceptionType.InvalidCellElementDims
                ExceptionFactory.throwInvalidCellElementDims();
              case ExceptionType.InvalidCellstrDims
                ExceptionFactory.throwInvalidCellstrDims(varargin{:});
              case ExceptionType.InvalidDataType
                ExceptionFactory.throwInvalidDataType(varargin{:});
              case ExceptionType.InvalidNDCharArray
                ExceptionFactory.throwInvalidNDCharArray();
              case ExceptionType.NonColumnarArray
                ExceptionFactory.throwNonColumnarArray();
              case ExceptionType.NonScalarMissing
                ExceptionFactory.throwNonScalarMissing(varargin{:});
              case ExceptionType.NonUniformCell
                ExceptionFactory.throwNonUniformCell(varargin{:});
              case ExceptionType.NonUniformCharWidth
                ExceptionFactory.throwNonUniformCharWidth(varargin{:});
              case ExceptionType.NonUniformVarNames
                ExceptionFactory.throwNonUniformVarNames(varargin{:});
              case ExceptionType.OrdinalCategoriesMismatch
                ExceptionFactory.throwOrdinalCategoriesMismatch(varargin{:});
              case ExceptionType.OrdinalMismatch
                ExceptionFactory.throwOrdinalMismatch(varargin{:});
              case ExceptionType.RowNamesLabelMismatch
                ExceptionFactory.throwRowNamesLabelMismatch(varargin{:});
              case ExceptionType.RowNamesMismatch
                ExceptionFactory.throwRowNamesMismatch(varargin{:});
              case ExceptionType.RowTimesLabelMismatch
                ExceptionFactory.throwRowTimesLabelMismatch(varargin{:});
              case ExceptionType.SparseArray
                ExceptionFactory.throwSparseArray(varargin{:});
              case ExceptionType.ZeroVariableTable
                ExceptionFactory.throwZeroVariableTable();
              case ExceptionType.DatetimeOutOfRange
                ExceptionFactory.throwDatetimeOutOfRange();
              otherwise
                % Should never be reached in production.
                error(message("MATLAB:io:arrow:matlab2arrow:Unknown"));
            end
        end
    end

    methods(Static, Access=private)
        function throwComplexNumber()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:ComplexNumber.
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:ComplexNumber";
            ArrowException.makeAndThrow(errId);
        end

        function throwExceedsMaxNestingLevel()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:ExceedsMaxNestingLevel
        %
        % Exception Class Type: MException
        %
        % NOTE: ExceedsMaxNestingLevel does not have an location
        % included in its message, so the exception class type is
        % MException.
            errId = "MATLAB:io:arrow:matlab2arrow:ExceedsMaxNestingLevel";
            error(message(errId));
        end

        function throwIncompatibleTimeZone(expectedTimeZoneAware)
        % Exception Identifier:
        %       MATLAB:io:arrow:matlab2arrow:IncompatibleTimeZoneNaive
        %                            OR
        %       MATLAB:io:arrow:matlab2arrow:IncompatibleTimeZoneAware
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            if expectedTimeZoneAware
                % Expected all datetime arrays to be timezone-aware,
                % but found a timezone-naive datetime.
                errId = "MATLAB:io:arrow:matlab2arrow:IncompatibleTimeZoneNaive";
            else
                % Expected all datetime arrays to be timezone-naive,
                % but found a timezone-aware datetime.
                errId = "MATLAB:io:arrow:matlab2arrow:IncompatibleTimeZoneAware";
            end
            ArrowException.makeAndThrow(errId, HasReferenceLocation=true);
        end

        function throwInvalidCellElementDims()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:InvalidCellElementDims
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:InvalidCellElementDims";
            ArrowException.makeAndThrow(errId);
        end

        function throwInvalidCellstrDims(index)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:InvalidCellstrDims
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:InvalidCellstrDims";
            except = ArrowException(errId);
            except = appendBracesIndexOperation(except, index);
            throw(except);
        end

        function throwInvalidDataType(invalidDataType)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:InvalidDataType
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            msgHoleValues = {invalidDataType};
            errId = "MATLAB:io:arrow:matlab2arrow:InvalidDataType";
            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues);
        end

        function throwInvalidNDCharArray()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:InvalidNDCharArray
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:InvalidNDCharArray";
            ArrowException.makeAndThrow(errId);
        end

        function throwNonColumnarArray()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:NonColumnarArray
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:NonColumnarArray";
            ArrowException.makeAndThrow(errId);
        end

        function throwNonScalarMissing(index)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:NonScalarMissing
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:NonScalarMissing";
            except = ArrowException(errId);
            except = appendBracesIndexOperation(except, index);

            throw(except);
        end

        function throwNonUniformCell(actualClassType, expectedClassType, causeIndex, referenceIndex)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:NonUniformCell
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            msgHoleValues = {actualClassType, expectedClassType};
            errId = "MATLAB:io:arrow:matlab2arrow:NonUniformCell";

            except = ArrowException(errId, MessageHoleValues=msgHoleValues,...
                                    HasReferenceLocation=true);

            if nargin > 3
                except = appendBracesIndexOperation(except, causeIndex, referenceIndex);
            end

            throw(except);
        end

        function throwNonUniformCharWidth(actualWidth, expectedWidth)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:NonUniformCharWidth
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            msgHoleValues = {actualWidth, expectedWidth};
            errId = "MATLAB:io:arrow:matlab2arrow:NonUniformCharWidth";
            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues,...
                                        HasReferenceLocation=true);
        end

        function throwNonUniformVarNames(actualVarNames, expectedVarNames, tabularType)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:NonUniformVarNames
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.formatStringVector

            fmtActNames = formatStringVector(actualVarNames);
            fmtExpNames = formatStringVector(expectedVarNames);
            msgHoleValues = {tabularType, fmtActNames, fmtExpNames};

            errId = "MATLAB:io:arrow:matlab2arrow:NonUniformVarNames";

            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues,...
                                        HasReferenceLocation=true);
        end

        function throwOrdinalCategoriesMismatch(actualCategories, expectedCategories)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:OrdinalCategoriesMismatch
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.formatStringVector

            fmtActCats = formatStringVector(actualCategories);
            fmtExpCats = formatStringVector(expectedCategories);
            msgHoleValues = {fmtActCats, fmtExpCats};

            errId = "MATLAB:io:arrow:matlab2arrow:OrdinalCategoriesMismatch";

            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues,...
                                        HasReferenceLocation=true);
        end

        function throwOrdinalMismatch(expectedOrdinal)
        % Exception Identifier:
        %       MATLAB:io:arrow:matlab2arrow:NonordinalMismatch
        %                            OR
        %       MATLAB:io:arrow:matlab2arrow:OrdinalMismatch
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            if expectedOrdinal
                % Expected all categorical arrays to be ordinal, but found
                % a non-ordinal categorical array.
                errId = "MATLAB:io:arrow:matlab2arrow:NonordinalMismatch";
            else
                % Expected all categorical arrays to be non-ordinal, but
                % found an ordinal categorical array.
                errId = "MATLAB:io:arrow:matlab2arrow:OrdinalMismatch";
            end
            ArrowException.makeAndThrow(errId, HasReferenceLocation=true);
        end

        function throwRowNamesLabelMismatch(actualRowNamesLabel, expectedRowNamesLabel)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:RowNamesLabelMismatch
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:RowNamesLabelMismatch";
            msgHoleValues = {actualRowNamesLabel, expectedRowNamesLabel};

            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues,...
                                        HasReferenceLocation=true);
        end

        function throwRowNamesMismatch(expectedRowNames)
        % Exception Identifier:
        %       MATLAB:io:arrow:matlab2arrow:NoRowNamesMismatch
        %                            OR
        %       MATLAB:io:arrow:matlab2arrow:HasRowNamesMismatch
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            if expectedRowNames
                % Expected all tables to have RowNames, but found a table
                % without RowNames.
                errId = "MATLAB:io:arrow:matlab2arrow:NoRowNamesMismatch";
            else
                % Expected all tables to NOT have RowNames, but found a
                % table with RowNames.
                errId = "MATLAB:io:arrow:matlab2arrow:HasRowNamesMismatch";
            end
            ArrowException.makeAndThrow(errId, HasReferenceLocation=true);
        end

        function throwRowTimesLabelMismatch(actualRowTimesLabel, expectedRowTimesLabel)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:RowTimesLabelMismatch
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            msgHoleValues = {actualRowTimesLabel, expectedRowTimesLabel};
            errId = "MATLAB:io:arrow:matlab2arrow:RowTimesLabelMismatch";

            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues,...
                                        HasReferenceLocation=true);
        end

        function throwSparseArray(arrayType)
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:SparseNumericArray
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            msgHoleValues = {arrayType};
            errId = "MATLAB:io:arrow:matlab2arrow:SparseArray";
            ArrowException.makeAndThrow(errId, MessageHoleValues=msgHoleValues);
        end

        function throwZeroVariableTable()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:ZeroVariableTable
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:ZeroVariableTable";
            matlab.io.internal.arrow.error.ArrowException.makeAndThrow(errId);
        end

        function throwDatetimeOutOfRange()
        % Exception Identifier: MATLAB:io:arrow:matlab2arrow:DatetimeOutOfRange
        %
        % Exception Class Type: matlab.io.internal.arrow.error.ArrowException
            import matlab.io.internal.arrow.error.ArrowException

            errId = "MATLAB:io:arrow:matlab2arrow:DatetimeOutOfRange";
            matlab.io.internal.arrow.error.ArrowException.makeAndThrow(errId);
        end
    end
end
