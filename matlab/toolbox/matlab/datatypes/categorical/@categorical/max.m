function [c,i] = max(a,b,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 2
    for ii = 1:(nargin-2) % ComparisonMethod not supported.
        if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
            error(message('MATLAB:max:InvalidAbsRealType'));
        end
    end
    
    % Check if the last input is 'linear'.
    if matlab.internal.math.checkInputName(varargin{end},{'linear'})
        if nargin > 3
             % If the last input is 'linear', we need to check the second to
             % last input for the undefined flag.
            [omitMissing,varargin{end-1}] = validateMissingOption(varargin{end-1});
        else
            omitMissing = true;
        end
    else
        [omitMissing,varargin{end}] = validateMissingOption(varargin{end});
    end
else
    omitMissing = true;
end

% Unary max
if nargin < 2 ... % max(a)
        || (nargin > 2 && isnumeric(b) && isequal(b,[])) % max(a,[],...) but not max(a,[])
    if ~a.isOrdinal
        error(message('MATLAB:categorical:NotOrdinal'));
    end
    
    acodes = a.codes;
    c = a;
    
    % Undefined elements have code zero, less than any legal code. They will not be
    % the max value unless there's nothing else, which is the correct behavior for
    % 'omitundefined'. For 'includeundefined', set the code value for undefined
    % elements to the largest integer to make sure they will be the max value.
    if ~omitMissing
        tmpCode = invalidCode(acodes);
        acodes(acodes==categorical.undefCode) = tmpCode;
    end
    
    try
        if nargin < 2
            if nargout <= 1
                ccodes = max(acodes);
            else
                [ccodes,i] = max(acodes);
            end
        else % nargin > 2
            if nargout <= 1
                ccodes = max(acodes,[],varargin{:});
            else
                [ccodes,i] = max(acodes,[],varargin{:});
            end
        end
    catch ME
        ME = matlab.internal.datatypes.throwInstead(ME,"MATLAB:max:unknownOption","MATLAB:categorical:unknownOption");
        ME = matlab.internal.datatypes.throwInstead(ME,"MATLAB:max:unknownNaNFlag","MATLAB:categorical:unknownNaNFlag");
        matlab.internal.datatypes.throwInstead(ME,"MATLAB:max:unknownFlag","MATLAB:categorical:UnknownNaNFlagLinearFlag");
    end
    
% Binary max
else % max(a,b) or max(a,b,...)
    % Accept -Inf as a valid "identity element" in the two-arg case. If compared
    % to <undefined> with 'omitundefined', the minimal value will be the result as
    % long as there is at least one category. If compared with 'includeundefined',
    % <undefined> will be the result.
    if isnumeric(a) && isequal(a,-Inf) % && isa(b,'categorical')
        bcodes = b.codes;
        acodes = cast(~isempty(b.categoryNames),'like',bcodes); % minimal value, or <undefined>
        c = b; % preserve subclass
    elseif isnumeric(b) && isequal(b,-Inf) % && isa(a,'categorical')
        acodes = a.codes;
        bcodes = cast(~isempty(a.categoryNames),'like',acodes); % minimal value, or <undefined>
        c = a; % preserve subclass
    else
        [acodes,bcodes,c] = reconcileCategories(a,b,true); % require ordinal
    end
    
    % Undefined elements have code zero, less than any legal code. They will not be
    % the max value unless there's nothing else, which is the correct behavior for
    % 'omitnan'. For 'includenan', set the code value for undefined elements to the
    % largest integer to make sure they will be the max value when present.
    if ~omitMissing
        tmpCode = invalidCode(acodes); % acodes is always correct type by now
        acodes(acodes==categorical.undefCode) = tmpCode;
        bcodes(bcodes==categorical.undefCode) = tmpCode;
    end
    try
        if nargout <= 1
            ccodes = max(acodes,bcodes,varargin{:});
        else
            [ccodes,i] = max(acodes,bcodes,varargin{:});
        end
    catch ME
        matlab.internal.datatypes.throwInstead(ME,"MATLAB:max:unknownNaNFlag","MATLAB:categorical:unknownNaNFlag");
    end
end

if ~omitMissing
    ccodes(ccodes==tmpCode) = categorical.undefCode; % restore undefined code
end

% No need to call castCodes on c, because nothing has been upcast. That's
% because there's either one input, or the two inputs have the exact same
% categories (they're both ordinal), and therefore same codes class.
c.codes = ccodes;
