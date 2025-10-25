function t = isequaln(varargin)
%

%   Copyright 2013-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isCharStrings

narginchk(2,Inf);

a = varargin{1};
if isa(a,'categorical')
    % Other inputs that are text will be converted to be 'like' a.
else
    % Find the first "real" categorical as a prototype for converting
    % character vectors.
    prototype = varargin{find(cellfun(@(x)isa(x,'categorical'),varargin),1,'first')};
    if isScalarText(a) || isCharStrings(a) % Allow only scalar strings.
        a = strings2categorical(a,prototype);
    else
        t = false; return
    end
end

isOrdinal = a.isOrdinal;
anames = a.categoryNames;
acodes = a.codes;

% Ensure the logic to check equality is consistent between isequaln and
% keyMatch.

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
    elseif isScalarText(b) || isCharStrings(b) % Allow only scalar strings
        [ib,ub] = strings2codes(b);
        bcodes = convertCodes(ib,ub,anames);
    elseif isa(b, 'missing')
        bcodes = zeros(size(b), 'uint8');
    else
        t = false; return
    end
    
    % Undefined elements in a will match undefined elements in b, both
    % codes are 0. Don't need to worry if acodes and bcodes are of different
    % type because isequal accepts any combination of numerics
    t = isequal(bcodes,acodes);
    
    if ~t, break; end
end
