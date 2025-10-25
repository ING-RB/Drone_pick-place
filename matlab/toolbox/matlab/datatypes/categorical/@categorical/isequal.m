function t = isequal(varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isCharStrings

narginchk(2,Inf);

a = varargin{1};
if isa(a,'categorical')
    %Other inputs that are text will be converted to be 'like' a
else
    % Find the first "real" categorical as a prototype for converting
    % text.
    prototype = varargin{find(cellfun(@(x)isa(x,'categorical'),varargin),1,'first')};
    if isScalarText(a) || isCharStrings(a) % only allow scalar string
        a = strings2categorical(a,prototype);
    else
        t = false; return
    end
end

isOrdinal = a.isOrdinal;
anames = a.categoryNames;
acodes = a.codes;
if nnz(acodes) < numel(acodes) % faster than any(acodes(:) == categorical.undefCode)
    t = false; return
end

for i = 2:nargin
    b = varargin{i};
    
    if isa(b,'categorical')
        if b.isOrdinal ~= isOrdinal
            t = false; return
        elseif isequal(b.categoryNames,anames)
            bcodes = b.codes;
        elseif ~isOrdinal
            % Get a's codes for b's data, ignoring protectedness.
            bcodes = convertCodes(b.codes,b.categoryNames,anames);
        else
            t = false; return
        end
    elseif isScalarText(b) || isCharStrings(b)
        [ib,ub] = strings2codes(b);
        bcodes = convertCodes(ib,ub,anames);
    else
        t = false; return
    end
    
    % Already weeded out cases where a.codes contains 0, thus don't need to
    % worry if b.codes does because they'll never match a.codes. Don't need
    % to worry if acodes and bcodes are of different type because isequal
    % accepts any combination of numerics
    t = isequal(bcodes,acodes);
    
    if ~t, break; end
end
