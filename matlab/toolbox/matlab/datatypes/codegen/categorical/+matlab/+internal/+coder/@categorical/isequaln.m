function t = isequaln(varargin) %#codegen
%ISEQUALN True if categorical arrays are equal, treating undefined elements as equal.
%   TF = ISEQUALN(A,B) returns logical 1 (true) if the categorical arrays A
%   and B are the same size and contain the same values or corresponding
%   undefined elements, and logical 0 (false) otherwise.  Either A or B may
%   also be a string scalar or character vector.
%
%   If A and B are both ordinal, they must have the same sets of categories,
%   including their order.  If neither A nor B are ordinal, they need not have
%   the same sets of categories, and the test is performed by comparing the
%   category names of each pair of elements.
%
%   TF = ISEQUALN(A,B,C,...) returns logical 1 (true) if all the input arguments
%   are equal.
%
%   Use ISEQUAL to treat undefined elements as unequal.
%
%   See also ISEQUAL, EQ, CATEGORIES.

%   Copyright 2018-2019 The MathWorks, Inc.

narginchk(2,Inf);

% Number of arrays
numArrays = nargin;

araw = varargin{1};
if isa(araw,'categorical')
    a = araw;
else
    % Find the first "real" categorical as a prototype for converting
    % text.
    prototype = categorical(matlab.internal.coder.datatypes.uninitialized());  % this will be overriden in the FOR loop
    for i = 2:numArrays
        if isa(varargin{i}, 'categorical')
            prototype = varargin{i};
            break;
        end            
    end
    if matlab.internal.coder.datatypes.isScalarText(araw) || ...
            matlab.internal.coder.datatypes.isCharStrings(araw) % only allow scalar string
        a = strings2categorical(araw,prototype);
    else
        t = false; return
    end
end

isOrdinal = a.isOrdinal;
anames = a.categoryNames;
acodes = a.codes;

for i = 2:numArrays
    b = varargin{i};
    
    if isa(b,'categorical')
        if b.isOrdinal ~= isOrdinal
            t = false;
        elseif isequal(b.categoryNames,anames)
            bcodes = b.codes;
            t = isequalCodes(bcodes,acodes);
        elseif ~isOrdinal
            % Get a's codes for b's data, ignoring protectedness.
            bcodes = b.convertCodes(b.codes,b.categoryNames,anames,false,false,...
                b.numCategoriesUpperBound);
            t = isequalCodes(bcodes,acodes);
        else
            t = false;
        end
    elseif matlab.internal.coder.datatypes.isScalarText(b) 
        [ib,ub] = a.strings2codes(b);
        bcodes = a.convertCodes(ib,ub,anames,false,false,1);
        t = isequalCodes(bcodes,acodes);
    elseif matlab.internal.coder.datatypes.isCharStrings(b)
        [ib,ub] = a.strings2codes(b);
        bcodes = a.convertCodes(ib,ub,anames,false,false,numel(b));
        t = isequalCodes(bcodes,acodes);
    elseif isa(b, 'missing')
        % Dead Code: codegen currently does not support missing
        bcodes = zeros(size(b), 'uint8');
        t = isequalCodes(bcodes,acodes);
    else
        t = false;
    end    
    
    if ~t, break; end
end
end

function t = isequalCodes(bcodes, acodes)
    % Undefined elements in a will match undefined elements in b, both
    % codes are 0. Don't need to worry if acodes and bcodes are of different
    % type because isequal accepts any combination of numerics
    coder.inline('always');
    t = isequal(bcodes,acodes);
end