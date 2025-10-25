function b = median(a,varargin)
%

% Copyright 2014-2024 The MathWorks, Inc.

narginchk(1, 5);

% Convert 'omitundefined' to 'omitmissing' if it is the last argument.
% Rely on core median to throw errors for incorrect inputs.
if nargin > 1
    [~,varargin{end}] = validateMissingOption(varargin{end});
end

% Check to make sure the categorical is ordinal
if ~isordinal(a)
    error(message('MATLAB:categorical:median:NotOrdinal'));
end

acodes = a.codes;

% Rely on built-in's NaN handling if input contains any <undefined> elements.
acodes = categorical.castCodesForBuiltins(acodes);

% Rely on median's behavior with dim vs. without, especially for empty input
try
    if nargin == 1
        bcodes = median(acodes);
    elseif nargin > 2 ...
            && matlab.internal.datatypes.isScalarText(varargin{end-1}) ...
            && strncmpi(varargin{end-1},'Weights',max(1,strlength(varargin{end-1})))
        bcodes = median(double(acodes),varargin{:});
    else
        bcodes = median(acodes,varargin{:});
    end
catch ME
    matlab.internal.datatypes.throwInstead(ME,"MATLAB:median:unknownOption","MATLAB:categorical:median:UnknownOption");
end

if isfloat(bcodes)
    % Cast back to integer codes, including NaN -> <undefined>
    bcodes = categorical.castCodes(bcodes,length(a.categoryNames));
end
b = a; % preserve subclass
b.codes = bcodes;
