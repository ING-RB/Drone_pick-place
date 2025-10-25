function validVLENData = validateVLEN(dataToWrite, ncid, xtype)
%VALIDATEVLEN Check that this cell array matches the NC_VLEN type definition
%   Verify this is valid data that can be written as this NC_VLEN type in
%   this NetCDF file. Specifically, check it is a homogeneous cell array
%   and recursively validate the base type of NC_VLEN type matches the
%   datatype of cell array elements. For convenience, it would attempt to
%   convert the given data to the expected NC_VLEN base type (if data is
%   numeric and lossless conversion is possible).

%   Copyright 2021 The MathWorks, Inc.

% If everything is good, this should be true.
% If dataToWrite is found to not match NC_VLEN definition below, we will
% either convert dataToWrite if possible, or throw an error. 
validVLENData = dataToWrite;

% Make sure xtype matches the datatype. The stop conditions of the
% recursion is when xtype is atomic (not an NC_VLEN). For numeric base
% types, we try to convert dataToWrite to the correct datatype (if
% possible) inside these stop conditions. The recursive condition of the
% recursion is when xtype is User-Defined (see the "otherwise" case).
switch (xtype)
    case netcdf.getConstant('NC_DOUBLE')
        if ~isa(dataToWrite, 'double')
            if isnumeric(dataToWrite)
                % converting to expected base type
                validVLENData = double(dataToWrite); 
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_DOUBLE'));
            end
        end
    case netcdf.getConstant('NC_FLOAT')
        if ~isa(dataToWrite, 'single')
            if isnumeric(dataToWrite) &&...
                    all(dataToWrite>=-realmax('single'), 'all') &&...
                    all(dataToWrite<=realmax('single'), 'all')
                % converting to expected base type
                validVLENData = single(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_FLOAT'));
            end
        end
    case netcdf.getConstant('NC_INT64')
        if ~isa(dataToWrite, 'int64')
            if canBeConvertedToIntegerType(dataToWrite, 'int64')
                % converting to expected base type
                validVLENData = int64(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_INT64'));
            end
        end
    case netcdf.getConstant('NC_UINT64')
        if ~isa(dataToWrite, 'uint64')
            if canBeConvertedToIntegerType(dataToWrite, 'uint64')
                % converting to expected base type
                validVLENData = uint64(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_UINT64'));
            end
        end
    case netcdf.getConstant('NC_INT')
        if ~isa(dataToWrite, 'int32')
            if canBeConvertedToIntegerType(dataToWrite, 'int32')
                % converting to expected base type
                validVLENData = int32(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_INT32'));
            end
        end
    case netcdf.getConstant('NC_UINT')
        if ~isa(dataToWrite, 'uint32')
            if canBeConvertedToIntegerType(dataToWrite, 'uint32')
                % converting to expected base type
                validVLENData = uint32(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_UINT'));
            end
        end
    case netcdf.getConstant('NC_SHORT')
        if ~isa(dataToWrite, 'int16')
            if canBeConvertedToIntegerType(dataToWrite, 'int16')
                % converting to expected base type
                validVLENData = int16(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_SHORT'));
            end
        end
    case netcdf.getConstant('NC_USHORT')
        if ~isa(dataToWrite, 'uint16')
            if canBeConvertedToIntegerType(dataToWrite, 'uint16')
                % converting to expected base type
                validVLENData = uint16(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_USHORT'));
            end
        end
    case netcdf.getConstant('NC_BYTE')
        % both uint8 and int8 can be represented by NC_BYTE
        if ~(isa(dataToWrite, 'uint8') || isa(dataToWrite, 'int8'))
            if canBeConvertedToIntegerType(dataToWrite, 'uint8')
                % converting to expected base type
                validVLENData = uint8(dataToWrite);
            elseif canBeConvertedToIntegerType(dataToWrite, 'int8')
                % converting to expected base type
                validVLENData = int8(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_BYTE'));
            end
        end
    case netcdf.getConstant('NC_UBYTE')
        if ~isa(dataToWrite, 'uint8')
            if canBeConvertedToIntegerType(dataToWrite, 'uint8')
                % converting to expected base type
                validVLENData = uint8(dataToWrite);
            else
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_UBYTE'));
            end
        end
    case netcdf.getConstant('NC_CHAR')
        if ~isa(dataToWrite, 'char')
            error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                class(dataToWrite), 'NC_CHAR'));
        end
    case netcdf.getConstant('NC_STRING')
        if ~isa(dataToWrite, 'string')
            error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                class(dataToWrite), 'NC_STRING'));
        end
    otherwise % recursive case
        % Must be a user-defined type
        [~, ~, baseTypeID, ~, classID] = ...
            netcdf.inqUserType(ncid, xtype);

        if (classID == netcdf.getConstant("NC_VLEN"))
            % NC_VLEN data must be a homogeneous cell array
            if ~iscell(dataToWrite)
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(dataToWrite), 'NC_VLEN'));
            end
            if ~isCellHomogeneous(dataToWrite)
                error(message('MATLAB:imagesci:netcdf:nonhomogeneousVLEN'));
            end

            % Must validate each element of cell array recursively
            for i=1:numel(dataToWrite)
                validVLENData{i} = validateVLEN(dataToWrite{i}, ...
                    ncid, baseTypeID);
            end

        else % we did not recognize the user-defined type
            error(message('MATLAB:imagesci:netcdf:unrecognizedVarDatatype', xtype))
        end
end
end


function tf = canBeConvertedToIntegerType(values, intType)
% Check if given values are whole numbers that are within 
% intmin and intmax range of the given integer type
tf = isnumeric(values) && areIntegerValues(values) &&...
                    all(values>=intmin(intType), 'all') &&...
                    all(values<=intmax(intType), 'all');
end

function tf = areIntegerValues(values)
% Check if these numeric values are whole numbers (i.e. they don't have any
% fractional part, so they can be fully represented by integer numeric
% types)
tf = all(round(values) == values, 'all');
end