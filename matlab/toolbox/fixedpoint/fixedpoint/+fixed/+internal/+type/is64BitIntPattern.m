function b = is64BitIntPattern(nameStr,caseSensitive)
% is64BitIntPattern is type name int64 or uin64
%
% Usage
%    b = fixed.internal.type.is64BitIntPattern(nameStr,caseSensitive)

% Copyright 2017-2020 The MathWorks, Inc.

%#codegen
    if nargin < 2
        caseSensitive = true;
    end
    
    sdt = 'int64';
    udt = 'uint64';
    if caseSensitive
        b = strcmp(nameStr,sdt) || strcmp(nameStr,udt);
    else
        b = strcmpi(nameStr,sdt) || strcmpi(nameStr,udt);
    end    
end
