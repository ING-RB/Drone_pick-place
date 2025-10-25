function displaySizeTypeLine(containerClass, dataClass, dataNDims, dataSize, isSparse, isComplex, isHot, numNonZero)
% Print the array type/size line, e.g. "3×3 gpuArray single matrix"
%
%   displaySizeTypeLine(containerClass, dataClass, dataNDims, dataSize, isSparse, isHot)
%   where:
%   * containerClass: name of remote array type (e.g. 'tall', 'gpuArray')
%   * dataClass: underlying type of values (e.g. 'double', 'table', etc.)
%   * dataNDims: number of dimension of the array
%   * dataSize: dimension vector (if known)
%   * isSparse: true if the contained data is sparse
%   * isHot: true if hyperlinks should be shown in the displayed output
%   * numNonZero: number of non-zeros for non-empty sparse
%

% Copyright 2019-2024 The MathWorks, Inc.

[arrayType, isEmpty] = iCalculateArrayType(dataClass, dataNDims, dataSize);
sizeStr = iCalculateSizeStr(dataNDims, dataSize);

% Compute the message describing size and type etc.
arrayInfoStr = iComputeMessage(isHot, arrayType, sizeStr, isEmpty, isSparse, isComplex, containerClass, dataClass);

if isSparse && ~isEmpty
    % Special type line for non-empty sparse
    isScalar = arrayType=="Scalar";
    fprintf("  %s%s\n", arrayInfoStr, getNonZeroText(isScalar, numNonZero));
else
    % Standard type line
    fprintf("  %s\n", arrayInfoStr);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate a word to describe the array. This must match one of the
% suffixes for the MATLAB:services:printmat:* messages.
function [arrayType, isEmpty] = iCalculateArrayType(dataClass, dataNDims, dataSize)

arrayType    = "Array";
isEmpty      = any(dataSize == 0);
isScalar     = isequal(dataSize, [1 1]);
% (time)tables never show any "array" or "matrix" information.
isTabular    = ismember(dataClass, ["table", "timetable"]);
% cell arrays *always* show "array" and size
isCell       = strcmp(dataClass, "cell");

% Only numeric matrices can use the 'row vector' type descriptions.
canUseShapeDescription = dataNDims == 2 && ismember(dataClass, iNumericClasses());

if isScalar && ~isCell
    % Note that this isn't a "normal" array type; rather, it's an indication that
    % the size should not be shown. (Takes precedence over 'Tabular')
    arrayType = "Scalar";
elseif isTabular
    % Size should be shown (if non-scalar), but never "array"/"matrix" etc.
    arrayType = "Tabular";
elseif canUseShapeDescription
    if all(dataSize ~= 1)
        arrayType = "Matrix";
    elseif dataSize(1) == 1
        arrayType = "RowVector";
    else
        arrayType = "ColumnVector";
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function vals = iNumericClasses()
    integerTypeNames = strsplit(strtrim(sprintf("int%d uint%d ", ...
                                                repmat([8, 16, 32, 64], 2, 1))));
    vals  = ["single", "double", "logical", integerTypeNames];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate a MxNx... or similar size string.
function szStr = iCalculateSizeStr(dataNDims, dataSize)

if dataNDims >= 5
    % As of R2016b don't show all sizes for 5D or more, just show the
    % dimensionality.
    szStr = string(dataNDims)+"-D";
else
    strArr = matlab.bigdata.internal.util.getArraySizeAsString(dataNDims, dataSize);
    
    % Join together dimensions using the TIMES character.
    szStr = strjoin(cellstr(strArr), matlab.internal.display.getDimensionSpecifier());
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct the "2x3 tall double column vector" from the available information.
function str = iComputeMessage(isHot, arrayType, sizeStr, isEmpty, isSparse, isComplex, containerClass, dataClass)

% Type order is [sparse] [container] [underlyingType], each hyperlinked if
% isHot. e.g. sparse gpuArray double

% Add the sparsity piece, with hyperlink if appropriate.
overallDescr = strtrim([iGetClassOrAttributeDescriptor(isHot, true, containerClass), ...
                    iGetClassOrAttributeDescriptor(isHot, ~isempty(dataClass), dataClass)]);

if strcmp(arrayType, "Scalar")
    % Scalars (including tables) just get 'tall double' piece unless
    % sparse.
    if isSparse
        id = "MATLAB:services:printmat:SparseNumericScalar";
        if ~isHot
                id = id + "NoHyperlink";
        end
        str = getString(message(id, overallDescr));
    else
        str = overallDescr;
    end
elseif strcmp(arrayType, "Tabular")
    % Tables never get the array/matrix piece.
    if isEmpty
        id = "MATLAB:services:printmat:EmptyTabular";
        str = getString(message(id, sizeStr, overallDescr));
    else
        str = [sizeStr ' ' overallDescr];
    end
else
    % All messages are from MATLAB:services:printmat but they have separate
    % messages for every combination so build it up programmatically.
    id = "MATLAB:services:printmat:";
    if isEmpty
        id = id + "Empty";
    end        
    if isSparse
        id = id + "Sparse";
    end
    if isComplex
        % Complex tag is applied only to empty or sparse
        if isSparse || isEmpty
            id = id + "Complex";
        end
    else
        % Numeric sparse gets the "numeric" suffix if not complex or empty.
        % Logical sparse gets the "logical" suffix if not empty and treats
        % everything except scalar as just Vector.
        if isSparse && ~isEmpty 
            if dataClass=="logical"
                % Sparse logical has different array-type mappings.
                % Non-empty row, column, and matrix as "Vector".
                id = id + "Logical";
                if arrayType ~= "Scalar"
                    arrayType = "Vector";
                end
            else
                id = id + "Numeric";
            end
        elseif dataClass=="logical"
            % For some reason non-sparse logicals are always referred to as "Array".
            arrayType = "Array";

        end
    end
    id = id + arrayType;
    % Only the sparse and/or empty-complex messages have a specific
    % NoHyperlink variant.
    if ~isHot && (isSparse || (isComplex && isEmpty))
        id = id + "NoHyperlink";
    end
    
    str = getString(message(id, sizeStr, overallDescr));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the perhaps-hotlinked description for a class or attribute.
function str = iGetClassOrAttributeDescriptor(isHot, isClassOrAttribute, classOrAttributeName)
if ~isClassOrAttribute
    str = '';
    return
end
str = classOrAttributeName;
if isHot
    str = [getString(message("MATLAB:bigdata:array:ClassHotLinkStart", str)), ...
           str, ...
           getString(message("MATLAB:bigdata:array:ClassHotLinkEnd"))];
end
str = [str, ' '];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = getNonZeroText(isScalar, numNonZeros)
    % Add non-zero count to header
    if ~isScalar && numNonZeros > 0  % 1 or more non-zeros and non-scalar
        if numNonZeros == 1
            % "(1 nonzero)"
            nonZeroMsg = message('MATLAB:services:printmat:OneNonzero',numNonZeros);
        else
            % Example: "(2 nonzeros)"
            nonZeroMsg = message('MATLAB:services:printmat:PluralNonzeros',numNonZeros);
        end
        out = [char(32) nonZeroMsg.getString];
    else  % Don't display non-zero message if there are 0 non-zeros
        out = '';
    end
end