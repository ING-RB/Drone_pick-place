function names = getParameterNames(value)
%

% Copyright 2016-2023 The MathWorks, Inc.

import matlab.lang.makeUniqueStrings;

maxLength = inf;
if iscellstr(value) %#ok<ISCLSTR>

    names = cellfun(@(v)reshapeNonEmptyValuesToRowVectors(v), value, ...
        'UniformOutput',false);

    names = cellfun(@replaceEmptyNames, names,'UniformOutput',false);
    maxLength = maximumTextLength;
elseif all(cellfun(@isstring, value))
    % strings 
    names = cellfun(@convertStringsToNames,value,'UniformOutput',false); 
    maxLength = maximumTextLength;
elseif all(cellfun(@(x) isa(x,'logical'), value))
    % logical values
    names = cellfun(@convertLogicalsToNames,value,'UniformOutput',false);
elseif all(cellfun(@(x)isa(x,'function_handle'), value))
    % function handles
    names = cellfun(@convertFunctionsToNames,value,'UniformOutput',false);
elseif all(cellfun(@isnumeric, value))
    % numerical values
    names = cellfun(@convertNumericalsToNames,value,'UniformOutput',false);
elseif any(cellfun(@nonScalarValues, value))
    % Non-scalar values of other types or mixed types
    names = cellfun(@getNamesFromHeterogenousArray, value, 'UniformOutput',false);
else
    % heterogenous cell array of scalar values of custom objects, other
    % datatypes, or mixed types
    names = cellfun(@getNamesFromHeterogenousArrayOfScalars,value,'UniformOutput',false);    
end
names = filterInvalidCharactersAndUniquify(names,maxLength);
end

function n = maximumTextLength
n = 63;
end

function bool = nonScalarValues(value)
bool = ~ischar(value) && numel(value) ~= 1;
end

function sizeAndClassStr = getSizeAndClassName(value)
% return a string in the pattern "<size>_<classname>" where the size could
% have N dimensions.
sizeVal = size(value);
if ~isnumeric(sizeVal)
    sizeVal = builtin('size',value);
end
sizeAndClassStr = char(join(string(sizeVal), "x") + "_" + class(value));
end

function name = convertFunctionsToNames(value)
if numel(value) ~= 1
    name = getSizeAndClassName(value);
else
    nameStr = func2str(value);
    if startsWith(nameStr,'@')  % anonymousFcn
        name = class(value);
    else
        name = strcat('@', nameStr);
    end
end
end

function name = convertNumericalsToNames(value)
if numel(value) ~= 1  % non scalar
    name = getSizeAndClassName(value);
else
    name = getValueStrForNumericals(value);
    if ~isa(value,'double')
        name = strcat(class(value),'_',name);
    end
end
end

function name = convertStringsToNames(value)
if numel(value) ~= 1 || (numel(value) == 1 && strlength(value) == 0)
    name = getSizeAndClassName(value);
else
    name = convertScalarStringToChar(value);
end
end

function name = convertLogicalsToNames(value)
if numel(value) ~= 1
    name = getSizeAndClassName(value);
else
    name = mat2str(value);
end
end

function name= getNamesFromHeterogenousArrayOfScalars(value)
% return a name in the pattern "<classname>_<valueString>" where the
% "_<valueString>" part is added if its possible to extract a value string
% based on type and size of the parameter value.
name = class(value);
name = attachParamValueIfApplicable(name,value);
end


function name= getNamesFromHeterogenousArray(value)
% return a name in the pattern "<size>_<classname>_<valueString>" where the
% "_<valueString>" part is added if its possible to extract a value string
% based on type and size of the parameter value.
name = getSizeAndClassName(value);
name = attachParamValueIfApplicable(name,value);
end


function name = attachParamValueIfApplicable(name,value)
if (isstring(value)&& isscalar(value))
    name = strcat(name,'_', convertScalarStringToChar(value));
    name = truncateNameToMaxLength(name);
elseif (ischar(value) && numel(value) > 0) % non-empty char vector
    value = reshape(permute(value, [2, 1, 3:ndims(value)]), 1, []);
    name = strcat(name,'_', value);
    name = truncateNameToMaxLength(name);
elseif isa(value,'logical') && isscalar(value) % scalar logical
    name = strcat(name,'_', mat2str(value));
elseif isa(value,'function_handle') && isscalar(value) % scalar function handle
    nameStr = func2str(value);
    if ~startsWith(nameStr,'@')
        name = strcat(name,'_', strcat('@', nameStr));
    end
elseif isnumeric(value) && isscalar(value) % scalar numerical value
     name = strcat(name,'_', getValueStrForNumericals(value));
end
end

function filteredName = filterInvalidCharactersAndUniquify(name,maxLength)
% Replace everything other than the following characters with underscores-
%   "@" for displaying function handles
%   "." for displaying classnames or doubles
%   "+", "-" for displaying higher or lower order numbers
%   alphanumeric characters
%
% Also, uniquify the names and truncate them if a maxLength is provided
import matlab.lang.makeUniqueStrings;

regexpPattern = '[^\@\-\+\.a-zA-Z_0-9]'; 
filteredName = regexprep(name,regexpPattern,"_");
filteredName = makeUniqueStrings(filteredName, {},maxLength);
end

function charOut = convertScalarStringToChar(stringIn)
if ismissing(stringIn)
    charOut = 'missing';
else   % valid string
    charOut = char(stringIn);
end
end

function valueStr = getValueStrForNumericals(value)
formatSpec = '%.15g';
if ~isreal(value) % complex number
    addStr = '+';
    realPart = num2str(real(value), formatSpec);
    imagValue = imag(value);
    if imagValue < 0  % negative imaginary values
        addStr = '';
    end
    valueStr = strcat(realPart, addStr,num2str(imagValue, formatSpec),'i');

elseif issparse(value) % sparse double
    valueStr = strcat(num2str(value, formatSpec),'_sparse');
else
    valueStr = num2str(value, formatSpec);
end
end

function name = replaceEmptyNames(name)
if isempty(name)
    name = getSizeAndClassName(name);
end
end

function value = reshapeNonEmptyValuesToRowVectors(value)
if ~isempty(value)
    value = reshape(permute(value, [2, 1, 3:ndims(value)]), 1, []);
end
end

function truncatedName = truncateNameToMaxLength(name)
truncatedName = extractBefore(name, 1 + min(maximumTextLength, strlength(name)));
end


% LocalWords:  lang
