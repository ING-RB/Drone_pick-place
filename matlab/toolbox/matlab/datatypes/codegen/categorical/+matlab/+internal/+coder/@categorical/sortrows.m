function [b,varargout] = sortrows(a,varargin) %#codegen
%SORTROWS Sort rows of a categorical array.

%   Copyright 2020 The MathWorks, Inc. 

coder.internal.prefer_const(varargin);

% Explicitly check for nargout to avoid internal errors later on.
coder.internal.assert(nargout < 3,'MATLAB:TooManyOutputs');

acodes = a.codes;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),...
        'MATLAB:sort:InvalidAbsRealType',class(a));
end

[col, ~, nanflag] = coder.internal.parseSortrowsOptions(size(acodes,2),varargin{:});
if nanflag == 'A' % 'auto'
    % Same as above: Make sure <undefined> sorts to the end when calling builtin SORT
    acodes(acodes == categorical.undefCode) = categorical.invalidCode(acodes);
    [bcodes,varargout{1:nargout-1}] = sortrows(acodes,varargin{:});
    bcodes(bcodes == categorical.invalidCode(bcodes)) = a.undefCode;
else
    % 'first' treats <undefined> as 0 for 'ascend' and intmax for 'descend'
    % 'last' treats <undefined> as intmax for 'ascend' and 0 for 'descend'
    [~,colind] = unique(abs(col),'stable'); % legacy repetead COL behavior
    col = col(colind);
    undefmask = acodes == categorical.undefCode;
    if nanflag == 'F' % 'first'
        undefmask(:,abs(col(col > 0))) = 0;
    else % 'last'
        undefmask(:,abs(col(col < 0))) = 0;
    end
    bcodes = acodes;
    acodes(undefmask) = categorical.invalidCode(acodes);
    [~,ndx] = sortrows(acodes,varargin{:});
    bcodes = bcodes(ndx,:);
    if nargout > 1
        varargout{1} = ndx;
    end
end

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isProtected = a.isProtected;
b.isOrdinal = a.isOrdinal;
b.categoryNames = a.categoryNames;
b.codes = bcodes;
