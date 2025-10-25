function tn = datenum(varargin)
%DATENUM convert tall array to serial date number.
%   DATENUM is not recommended. Use datetime to represent points in time,
%   and duration or calendarDuration to represent elapsed times.
%
%   See also DATETIME.

%   Copyright 2015-2024 The MathWorks, Inc.

narginchk(1,6);
[varargin{1:nargin}] = tall.validateType(varargin{:}, mfilename, ...
    {'cellstr', 'char', 'numeric', 'datetime', 'duration', 'string'}, ...
    1:nargin);

% Handle DATEVEC input as a special case. This requires an extra pass, so
% we want to avoid this where possible.
notDatevecClasses = ["cell", "datetime", "duration", "string"];
if nargin == 1 && ~any(tall.getClass(varargin{1}) == notDatevecClasses)
    sz = varargin{1}.Adaptor.getSizeInDim(2);
    if isnan(sz) || any(sz == [3, 6])
        requiresDatevec = aggregatefun(@iCheckForDatevec, @any, varargin{:});
        tn = slicefun(@iDatenumSingleArg, requiresDatevec, varargin{:});
        return;
    end
end

% Handle string input as another special case. In the case of a scalar string
% data argument of length 0, the operation is not slicewise - 
% in other words, datenum("") returns 0x1.
primitive = @slicefun;
if nargin <= 3 && tall.getClass(varargin{1}) == "string"
    arg1Adaptor = matlab.bigdata.internal.adaptors.getAdaptor(varargin{1});
    if ~isKnownNotScalar(arg1Adaptor)
        % Might be scalar, so we must use chunkfun.
        primitive = @chunkfun;
    end
end
tn = primitive(@iDatenum, varargin{:});

end

function tf = iCheckForDatevec(arg1)
% Check if the current chunk requires special handling of datenum to convert
% all inputs from DATEVEC.
sz = size(arg1);
tf = isnumeric(arg1) ...
    && any(sz(2) == [3, 6]) ...
    && any(prod(sz(2 : end)) == [3, 6]) ...
    && any(abs(arg1(:,1) - 2000) < 10000);
end

function x = iDatenumSingleArg(requiresDatevec, varargin)
% If any chunk requires special handling, do special handling for all
% chunks.
if requiresDatevec
    varargin = num2cell(varargin{1}(:, :, 1), 1);
end
x = iDatenum(varargin{:});
end

function n = iDatenum(varargin)
% Invoke datenum, disallowing string input when not a column vector. We do
% this because string datenum does not have consistent behavior when
% applied to a non-vector string array.
if ~iscolumn(varargin{1}) && (isstring(varargin{1}) || iscellstr(varargin{1}))
    error(message('MATLAB:bigdata:array:DatenumNonColumnString'));
end
% This warning is issued on empty chunks. This is disabled as it might
% generate many warnings during a single gather.
warnState = warning('off', 'MATLAB:datenum:EmptyDate');
warnCleanup = onCleanup(@() warning(warnState));
n = datenum(varargin{:});
if isempty(n) && ((nargin == 3) || (nargin == 6)) ...
        && ~any(cellfun(@matlab.internal.datatypes.isScalarText, varargin))
    % The datenum(Y,M,D) and datenum(Y,M,D,H,MN,S) returns zeros(0,1) when
    % all inputs are empty, even when those inputs are a different size
    % empty (E.G. zeros(0,3)).
    n = zeros(size(varargin{1}));
end
end
