function preValidateNodeIDs(id, funcName, varName)
%This function is for internal use only. It may be removed in the future.

%preValidateNodeIDs Validate ONLY the basic attributes of nodeID input. 
%
%   preValidateNodeIDs(ID, FUNCNAME, VARNAME) checks whether the input,
%   IDs, is a nonnegative, nonsparse, nonempty integer row vector. It
%   however does not verify if the nodeID exists in the factor definition
%   or in the factor graph.
%
%   FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to construct the
%   error ID and message.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

validateattributes(id, 'numeric', ...
        {'vector', 'integer', 'nonnegative', 'nonsparse', 'nonempty'}, funcName, varName);

% Check duplicate node IDs
d = diff(sort(id));
coder.internal.errorIf(any(d==0),'nav:navalgs:factors:NoDuplicateNodeIDs');
end

