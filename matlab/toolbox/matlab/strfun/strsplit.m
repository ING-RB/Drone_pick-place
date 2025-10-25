function [c, matches] = strsplit(str, aDelim, varargin)
%

%   Copyright 2012-2023 The MathWorks, Inc.

% Initialize default values.
collapseDelimiters = true;
delimiterType = 'Simple';

% Check input arguments.
if nargin < 1
    narginchk(1, Inf);
elseif ~ischar(str) && ~(isstring(str) && isscalar(str))
    error(message('MATLAB:strsplit:InvalidStringType'));
end
if nargin < 2
    delimiterType = 'RegularExpression';
    aDelim = {'\s'};
elseif ischar(aDelim)
    aDelim = {aDelim};
elseif isstring(aDelim)
    aDelim(ismissing(aDelim)) = [];
    aDelim = cellstr(aDelim);
elseif ~iscellstr(aDelim)
    error(message('MATLAB:strsplit:InvalidDelimiterType'));
end
if nargin > 2
    funcName = mfilename;
    p = inputParser;
    p.FunctionName = funcName;
    p.addParameter('CollapseDelimiters', collapseDelimiters);
    p.addParameter('DelimiterType', delimiterType);
    p.parse(varargin{:});
    collapseDelimiters = verifyScalarLogical(p.Results.CollapseDelimiters, ...
        funcName, 'CollapseDelimiters');
    delimiterType = validatestring(p.Results.DelimiterType, ...
        {'RegularExpression', 'Simple'}, funcName, 'DelimiterType');
end

% Handle DelimiterType.
if strcmp(delimiterType, 'Simple')
    % Handle escape sequences and translate.
    aDelim = strescape(aDelim);
    aDelim = regexptranslate('escape', aDelim);
else
    % Check delimiter for regexp warnings.
    regexp('', aDelim, 'warnings');
end

% Handle multiple delimiters.
aDelim = char(join(aDelim, '|'));

% Handle CollapseDelimiters.
if collapseDelimiters
    aDelim = ['(?:', aDelim, ')+'];
end

% Split.
[c, matches] = regexp(str, aDelim, 'split', 'match');

end
%--------------------------------------------------------------------------
function tf = verifyScalarLogical(tf, funcName, parameterName)

if isscalar(tf) && (islogical(tf) || (isnumeric(tf) && any(tf == [0, 1])))
    tf = logical(tf);
else
    validateattributes(tf, {'logical'}, {'scalar'}, funcName, parameterName);
end

end
