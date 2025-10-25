function preValidateFactorIDs(id, funcName, varName)
%This function is for internal use only. It may be removed in the future.

%preValidateFactorIDs Validate ONLY the basic attributes of factorID input. 
%
%   preValidateFactorIDs(ID, FUNCNAME, VARNAME) checks whether the input,
%   IDs, is a nonnegative, nonsparse, nonempty integer row vector. It
%   however does not verify if the factorID exists in the factor definition
%   or in the factor graph.
%
%   FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to construct the
%   error ID and message.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

validateattributes(id, 'numeric', ...
        {'vector', 'integer', 'nonnegative', 'nonsparse', 'nonempty'}, funcName, varName);

% Check duplicate factor IDs
d = diff(sort(id));
coder.internal.errorIf(any(d==0),'nav:navalgs:factorgraph:NoDuplicateFactorIDs');
end

