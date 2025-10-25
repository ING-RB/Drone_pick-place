function outcls = unsignedClass(incls)
%MATLAB Code Generation Private Function

%   Returns the unsigned integer class with the same size as incls.

%   Copyright 2006-2014 The MathWorks, Inc.
%#codegen
coder.allowpcode('plain');
coder.inline('always');
switch incls
    case {'int32','uint32'}
        outcls = 'uint32';
    case {'int16','uint16'}
        outcls = 'uint16';
    case {'int8','uint8'}
        outcls = 'uint8';
    case {'int64','uint64'}
        outcls = 'uint64';
    case 'coder.internal.indexInt'
        outcls = coder.internal.indexIntClass;
    otherwise
        eml_invariant(false, ...
            'Coder:toolbox:eml_unsigned_class_1', ...
            'IfNotConst','Fail');
end

