function str = mat2str(matrix, varargin)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1,3);

precision = 15;
precisionSpecified = false;
useclass  = false;

for i = 1:numel(varargin)
    
    if ischar(varargin{i})
        switch lower(varargin{i})
        case 'class'
            useclass = true; 
        otherwise
            error(message('MATLAB:mat2str:InvalidOptionString', varargin{ i }));
        end
    elseif isnumeric(varargin{i})

        precision = varargin{i};
        
        if ~isscalar(precision) || ~isreal(precision) || ~isfinite(precision) || floor(precision) ~= precision || precision < 1
            error(message('MATLAB:mat2str:InvalidPrecision'));   
        end
        
        precisionSpecified = true;
    else
        error(message('MATLAB:mat2str:InvalidOptionType'));    
    end
end

if ~ismatrix(matrix)
    error(message('MATLAB:mat2str:TwoDInput'));
end

enumerationFlag = isenumeration(matrix);

if ~(isnumeric(matrix) || ischar(matrix) || islogical(matrix) || enumerationFlag || isstring(matrix))
    error(message('MATLAB:mat2str:NumericInput'));
end

if enumerationFlag || isstring(matrix) || ischar(matrix)
    useclass = false;
end

[rows, cols] = size(matrix);

if issparse(matrix)
    [i,j,s] = find(matrix);
    str = ['sparse(' mat2str(i) ', ' mat2str(j), ', '];
    if useclass
        str = [str mat2str(s, precision, 'class')];
    else
        str = [str mat2str(s, precision)];
    end
    str = [str ', ' mat2str(rows) ', ' mat2str(cols) ')'];
    return;
end

if ischar(matrix) && ~isempty(matrix)
    values = cell(rows,1); 
    for row=1:rows
        values{row} = matrix(row,:);
    end
    needsConcatenation = rows > 1;

    dangerousPattern  =  '[\0\n-\r]';
    hasDangerousChars = regexp(values, dangerousPattern, 'once');

    needsConcatenation = needsConcatenation | ~isempty([hasDangerousChars{:}]);

    values = replace(values, "'", "''");
    if ~isempty([hasDangerousChars{:}])
        values = regexprep(values, dangerousPattern, "' ${sprintf('char(%d)',$0)} '");
    end

    if needsConcatenation
        str = '[';
    else
        str = '';
    end

    str = [str '''' values{1} ''''];

    for row = 2:rows
        str = [str ';''' values{row} '''']; %#ok 
    end

    if needsConcatenation
        str = [str ']'];
    end

    return;
elseif isstring(matrix)
    
    specialValues  = ["\0"; "\n"; "\v"; "\f"; "\r"];
    
    needsEscape = contains(matrix, compose(specialValues));
    needsEscape = any(needsEscape,'all');
    
    if needsEscape
        specialValues = [specialValues; "\\"];
    else
        specialValues = [];
    end
    
    finalValues = [specialValues; '""'];
    composedValues = compose([specialValues; '"']);
    
    matrix = replace(matrix, composedValues, finalValues);
    matrix = '"' + matrix + '"';
    
    matrix(ismissing(matrix)) = "string(missing)";
    
    if isempty(matrix)
        matrix = "strings(" + join(string(size(matrix)),',') + ")"; 
    elseif ~isscalar(matrix)
        matrix = join(matrix,' ',2);
        matrix = join(matrix,';',1);
        matrix = "[" + matrix + "]"; 
    end
    
    if needsEscape
       matrix = "compose(" + matrix + ")"; 
    end
    
    str = char(matrix);
    return; 
end

if isempty(matrix)
    if enumerationFlag
        str = [class(matrix) '.empty(' int2str(rows) ',' int2str(cols) ')'];
    elseif (rows==0) && (cols==0)
        if ischar(matrix)
            str = '''''';
        else
            str = '[]';
        end
    else
        str = ['zeros(' int2str(rows) ',' int2str(cols) ')'];
    end
    if useclass
        str =  [class(matrix), '(', str, ')'];
    end
    return;
end

if isfloat(matrix) && ~enumerationFlag
    matrix = 0+matrix;  % Remove negative zero
end

numericFormat = "%." + precision + "g";
if class(matrix) == "uint64" && formatNotPreciseEnough(matrix, precision, precisionSpecified)
    numericFormat = "%u";
elseif class(matrix) == "int64" && formatNotPreciseEnough(matrix, precision, precisionSpecified)
    numericFormat = "%d";
end

hasConversion = false;

if enumerationFlag
    values = class(matrix) + "." + string(matrix);
elseif islogical(matrix)
    values = string(matrix);
elseif isreal(matrix)
    [values, hasConversion] = composeNumber(numericFormat, matrix, useclass);
else
    realVal = real(matrix);
    imagVal = imag(matrix);

    isFinite = isfinite(imagVal);
    isImagNegative = imagVal < 0;
    isImagNegativeInf = ~isFinite & isImagNegative;

    anyImagNegativeInf = any(isImagNegativeInf,'all');

    if anyImagNegativeInf
        imagVal(isImagNegativeInf) = inf; 
    end

    [realPartStr, realHasConversion] = composeNumber(numericFormat, realVal, useclass);
    [imagPartStr, imagHasConversion] = composeNumber(numericFormat, imagVal, useclass);

    hasConversion = realHasConversion | imagHasConversion;

    imagStr = imagPartStr;

    imagStr( isFinite) = imagStr(isFinite) + "i";
    imagStr(~isFinite) = "1i*" + imagStr(~isFinite);

    imagStr(~isImagNegative)   = "+" + imagStr(~isImagNegative);

    if anyImagNegativeInf
        imagStr(isImagNegativeInf) = "-" + imagStr(isImagNegativeInf);
    end

    imagStr(imagVal == 0) = "";
    
    values = realPartStr + imagStr;

    if any(hasConversion,'all')
        values(hasConversion) = "complex(" + realPartStr(hasConversion) + "," + imagPartStr(hasConversion) + ")";
    end
end

values = join(values,' ',2);
str    = join(values,';',1);

% clean up the end of the string
if ~isscalar(matrix)
    str = "[" + str + "]";
end

if useclass

    isScalarWithConversion = isscalar(matrix) && hasConversion;
    
    if ~isScalarWithConversion
        str =  class(matrix) + "(" + str + ")";
    end
end

str = char(str);

end

function b = isenumeration(m)
    b = ~isempty(enumeration(class(m)));
end

function n = getNumOfDigits(x)
    % Workaround because log10 doesn't support integers
    pows = uint64(10).^uint64(1:20);
    n = find(x <= pows, 1);
end

function tf = formatNotPreciseEnough(matrix, precision, precisionSpecified)
    tf = ~precisionSpecified || precision >= getNumOfDigits(max(abs([real(matrix);imag(matrix)]),[],'all'));
end

function [result, requiresConversion] = composeNumber(fmt, matrix, useclass)

    requiresConversion = (matrix >= flintmax | matrix <= -flintmax) & isinteger(matrix);

    result = compose(fmt,matrix);

    if useclass && any(requiresConversion,'all') && (isa(matrix,'uint64') || isa(matrix,'int64'))
        result(requiresConversion) = class(matrix) + "(" + result(requiresConversion) + ")";
    end
end
