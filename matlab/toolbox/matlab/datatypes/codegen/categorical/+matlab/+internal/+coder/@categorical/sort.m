function [b,varargout] = sort(a,varargin) %#codegen
%SORT Sort a categorical array.

%   Copyright 2020 The MathWorks, Inc. 

coder.internal.prefer_const(varargin);

% Explicitly check for nargout to avoid internal errors later on.
coder.internal.assert(nargout < 3,'MATLAB:TooManyOutputs');

acodes = a.codes;
nCategories = numel(a.categoryNames);

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),...
        'MATLAB:sort:InvalidAbsRealType',class(a));
end

% SORT(A), SORT(A,DIM), SORT(A,DIRECTION), SORT(A,DIM,DIRECTION):
noNVPairs = (nargin <= 2) || (nargin <= 3 && isnumeric(varargin{1}));

if nCategories <= 5e5 && noNVPairs
    % Do faster CATEGORICALSORT for fewer than 500,000 categories:
    if nargin == 1
        [bcodes,varargout{1:nargout-1}] = matlab.internal.coder.categoricalUtils.categoricalsort(acodes,nCategories);
    else
        [bcodes,varargout{1:nargout-1}] = matlab.internal.coder.categoricalUtils.categoricalsort(acodes,nCategories,varargin{:});
    end
else % Otherwise, dispatch to builtin SORT:
    defaultMissingPlace = true;
    if ~noNVPairs
        defaultMissingPlace = checkMissingPlacement(varargin{:});
    end
    if defaultMissingPlace
        % Make sure <undefined> sorts to the end when calling builtin SORT
        acodes(acodes == categorical.undefCode) = categorical.invalidCode(acodes);
        if nargin == 1
            [bcodes,varargout{1:nargout-1}] = sort(acodes);
        else
            [bcodes,varargout{1:nargout-1}] = sort(acodes,varargin{:});
        end
        bcodes(bcodes == categorical.invalidCode(bcodes)) = a.undefCode; % set invalidCode back to <undefined> code
    else
        % Treat <undefined> as 0 for 'descend'-'last' and 'ascend'-'first'
        % because the codes are unsigned integers.
        [bcodes,varargout{1:nargout-1}] = sort(acodes,varargin{:});
    end
end

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isProtected = a.isProtected;
b.isOrdinal = a.isOrdinal;
b.categoryNames = a.categoryNames;
b.codes = bcodes;

%--------------------------------------------------------------------------
function defaultMissingPlace = checkMissingPlacement(varargin)
%CHECKMISSINGPLACEMENT Check for non-default case of 'descend' and
% 'MissingPlacement' 'last', or 'ascend' and 'MissingPlacement' 'first'.

% SORT(A,VARARGIN) calls checkMissingPlacement(varargin{:}) and supports:
%   SORT(A,DIM,'MissingPlacement',V)
%   SORT(A,DIRECTION,'MissingPlacement',V)
%   SORT(A,DIM,DIRECTION,'MissingPlacement',V)
%   SORT(A,'MissingPlacement',V)

coder.internal.prefer_const(varargin);
% varargin always has at least 1 element when we call this function
dimOffset = isnumeric(varargin{1});
doDescend = (1+dimOffset <= nargin) && ...
    matlab.internal.coder.datatypes.checkInputName(varargin{1+dimOffset},{'descend'});
dirOffset = doDescend || ((1+dimOffset <= nargin) && ...
    matlab.internal.coder.datatypes.checkInputName(varargin{1+dimOffset},{'ascend'}));
doFirst = false;
doLast = false;
for ii = (1+dimOffset+dirOffset):2:(nargin-1)
    if matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'MissingPlacement'})
        doFirst = matlab.internal.coder.datatypes.checkInputName(varargin{ii+1},{'first'});
        doLast = matlab.internal.coder.datatypes.checkInputName(varargin{ii+1},{'last'});
    end
end
defaultMissingPlace = ~( (doDescend && doLast) || (~doDescend && doFirst) );