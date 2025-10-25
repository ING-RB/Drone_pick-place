function varargout = datevec(varargin)
%DATEVEC convert tall array to date components.
%   Using DATEVEC to represent points in time is not recommended. 
%   Use datetime instead. To extract date and time components from a datetime,
%   use the ymd, hms, or datevec functions or the datetime properties:
%   Year, Month, Day, Hour, Minute, or Second.
%
%   See also DATETIME/DATEVEC, DATEVEC.

%   Copyright 2015-2022 The MathWorks, Inc.

narginchk(1,3);
nargoutchk(0,6);
% We must allow: datetime/calendarDuration/duration/cellstr as the primary data
% arguments, char/string for flags, and numeric for PivotYear argument.
[varargin{1:nargin}] = tall.validateType(varargin{:}, mfilename, {...
    'datetime', 'calendarDuration', 'duration', ...
    'cellstr', 'char', 'numeric', 'string'}, 1:nargin);

stringClasses = ["char", "cell", "string"];
if nargin > 1 && ~any(tall.getClass(varargin{1}) == stringClasses)
    % Throw warning ignoring all optional arguments when the input is not
    % char, string or cellstr. Remove optional arguments to avoid invalid
    % chunk sizes.
    warning(message('MATLAB:datevec:Inputs'));
    args = varargin(1);
else
    args = varargin;
end

% datevec implicitly colonizes its inputs, so we must insist that all input
% arguments are data columns, or character row-vectors.
args = cellfun(@iValidateDatevecArg, args, 'UniformOutput', false);

% Handle string input as another special case. In the case of a scalar
% string data argument of length 0, the operation is not slicewise - 
% in other words, datevec("") returns 0x6 empty double matrix.
primitive = @slicefun;
if tall.getClass(args{1}) == "string"
    arg1Adaptor = matlab.bigdata.internal.adaptors.getAdaptor(args{1});
    if ~isKnownNotScalar(arg1Adaptor)
        % Might be scalar, so we must use chunkfun.
        primitive = @chunkfun;
    end
end
[varargout{1:max(nargout,1)}] = primitive(@iDatevec, args{:});
[varargout{:}] = setKnownType(varargout{:}, 'double');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iValidDatevecArg checks whether a given argument is 
function arg = iValidateDatevecArg(arg)

messageId = 'MATLAB:bigdata:array:DatevecInputsColumn';

% Valid arguments are either column vectors (including scalars for 
% PivotYear) or character 2D arrays, where each row is a date. The
% validateType checks above have already eliminated completely invalid 
% types. We also allow non-column empties through for no really 
% particularly good reason.
predicate = @(x) (ischar(x) && ismatrix(x)) || iscolumn(x) || isempty(x);

if istall(arg)
    arg = lazyValidate(arg, {predicate, messageId});
elseif ~predicate(arg)
    error(message(messageId));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iDateVec invokes datevec disabling this warning
function varargout = iDatevec(varargin)
    % This warning is issued on empty chunks. This is disabled as it might
    % generate many warnings during a single gather.
    warnState = warning('off', 'MATLAB:datevec:EmptyDate');
    warnCleanup = onCleanup(@() warning(warnState));
    
    [varargout{1:max(nargout,1)}] = datevec(varargin{:});

end