function arrayStruct = buildArrayStruct(array)
%BUILDARRAYSTRUCT Builds a struct representation of the input array to be
%passed to the C++ layer.
%
% ARRAY can have one of the following types:
%  uint8, uint16, uint32, uint64, int8, int16, int32, int64, single,
%  double, logical, string, char, categorical, datetime, duration, or a
%  cell array of character vectors.
%
% If ARRAY is a character array, its dimensions can be N by M. Otherwise,
% ARRAY must be N by 1.
%
% ARRAYSTRUCT is a scalar struct.
%
% ARRAYSTRUCT contains the following fields:
%
% Field Name    Class       Description
% ----------    -------     -----------------------------------------------
% ArrowType     char        Always set to 'array'.
% Type          char        The datatype of the input array this struct
%                              represents, i.e. 'double', 'datetime', etc.
% Valid         struct      Struct representation of the validity bitmap.
% Data          struct      Struct representation of the array's values.
%                              Data's schema is depends from the input
%                              arrays datatype.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.arrow.internal.matlab2arrow.*;
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory

    validateDimensions(array);
    arrayType = class(array);

    % For numeric variables, the underlying array data can be directly passed
    % to the C++ layer.
    switch arrayType
      case {'uint8', 'uint16', 'uint32', 'uint64', ...
            'int8', 'int16', 'int32', 'int64', ...
            'single', 'double'}
        [dataStruct, validStruct] = buildNumericStruct(array);
      case 'logical'
        [dataStruct, validStruct] = buildLogicalStruct(array);
        % String variables need to be decomposed into a uint8 array of
        % contiguous UTF-8 code units and another uint32 array of offsets
        % locating the start of each string in the UTF-8 array.
      case {'string', 'char'}
        arrayType = 'string';
        [dataStruct, validStruct] = buildStringStruct(array);
      case 'categorical'
        [dataStruct, validStruct] = buildCategoricalStruct(array);
      case 'datetime'
        [dataStruct, validStruct] = buildDatetimeStruct(array);
      case 'duration'
        [dataStruct, validStruct] = buildDurationStruct(array);
      case 'cell'
        [array, isCellstr] = isCellOfCharVectors(array);
        if isCellstr
            % Convert cell array of character vectors to UTF-8 compatible arrays.
            arrayType = 'string';
            [dataStruct, validStruct] = buildStringStruct(array);
        else
            arrayStruct = buildListArrayStruct(array);
            return;
        end
      otherwise
        ExceptionFactory.throw(ExceptionType.InvalidDataType, arrayType);
    end

    arrayStruct.ArrowType = 'array';
    arrayStruct.Type = arrayType;
    arrayStruct.Valid = validStruct;
    arrayStruct.Data = dataStruct;
end


function validateDimensions(input)
    if ischar(input)
        validateCharDimensions(input);
    else
        % All other datatypes must be columnar for conversion.
        validateIsColumnarArray(input);
    end
end

function validateCharDimensions(input)
    if ~ismatrix(input)
        % N-dimensional char matrices are not supported for conversion.
        exceptionType = matlab.io.internal.arrow.error.ExceptionType.InvalidNDCharArray;
        matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
    end
end

function validateIsColumnarArray(input)
    if ~iscolumn(input) && ~(isempty(input) && size(input, 2) <= 1)
        exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonColumnarArray;
        matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
    end
end

function [c, isCellstr] = isCellOfCharVectors(c)
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory

    firstCharIndex = inf;
    hasChars = false;
    missingIndices = false(size(c));
    for i = 1:numel(c)
        if ischar(c{i})
            hasChars = true;
            firstCharIndex = min(firstCharIndex, i);
            % only char vectors or empty char arrays are supported.
            if ~isvector(c{i}) && ~isempty(c{i})
                ExceptionFactory.throw(ExceptionType.InvalidCellstrDims, i);
            end

            % forces the char array is a columnar vector.
            c{i} = reshape(c{i}, 1, []);
        elseif class(c{i}) == "missing"
            % Only scalar <missing> values are allowed
            if ~isscalar(c{i})
                ExceptionFactory.throw(ExceptionType.NonScalarMissing, i);
            end

            % Cell arrays containing missing values and char vectors are
            % treated like cellstrs, i.e. mapped to arrow::StringArrays.
            missingIndices(i) = true;
        else
            if hasChars
                ExceptionFactory.throw(ExceptionType.NonUniformCell, class(c{i}), "char", i, firstCharIndex);
            end
            % c{i} is not a char array, meaning c itself is not a cellstr.
            % c must either represent an arrow::ListArray or it's invalid.
            % buildListArrayStruct will take care of marshaling c or
            % erroring if it's invalid.
            isCellstr = false;
            return;
        end
    end
    isCellstr = isempty(c) || hasChars;
    if isCellstr
        % Replace <missing> with {''}. buildStringStruct
        % expects either a string array or a cell array containing
        % only char vectors. It cannot handle cell arrays
        % containing <missing> values. Because ismissing({''})
        % returns true - just like ismissing(missing) - it's ok to
        % replace {missing} with {''}.
        c(missingIndices) = {''};
    end
end
