function s = table2struct(t,varargin)  %#codegen
%TABLE2STRUCT Convert table to structure array.
%   S = TABLE2STRUCT(T) converts the table T to a structure array S.  Each
%   variable of T becomes a field in S.  If T is an M-by-N table, then S is
%   M-by-1 and has N fields.
%
%   S = TABLE2STRUCT(T,'ToScalar',true) converts the table T to a scalar
%   structure S.  Each variable of T becomes a field in S.  If T is an
%   M-by-N table, then S has N fields, each of which has M rows.
%
%   S = TABLE2STRUCT(T,'ToScalar',false) is identical to S = TABLE2STRUCT(T).
%
%   See also STRUCT2TABLE, TABLE2CELL, TABLE.

%   Copyright 2019 The MathWorks, Inc.


pnames = {'ToScalar'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);
pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

toScalar = coder.internal.getParameterValue(pstruct.ToScalar,false,varargin{:});

toScalar = matlab.internal.coder.datatypes.validateLogical(toScalar,'ToScalar');

coder.internal.assert(coder.internal.isConst(toScalar), 'MATLAB:table2struct:NonconstantToScalar');
if toScalar
    s = getVars(t);
else
    s = getVarsAsStructArray(t);
end