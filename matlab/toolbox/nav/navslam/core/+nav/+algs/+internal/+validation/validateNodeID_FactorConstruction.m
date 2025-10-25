function validateNodeID_FactorConstruction(ids, dim, funcName, varName, varargin)
%This function is for internal use only. It may be removed in the future.

%validateNodeID_FactorConstruction Validate node IDs at factor construction
%   validateNodeID(ID, DIM, FUNCNAME, VARNAME) validates whether the input, ID,
%   is a valid node ID number when the factor object is constructed. A node
%   ID is expected to be a nonnegative n-by-DIM row vector with NO duplicate
%   entries.
%
%   FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to construct the
%   error ID and message.
%
%   validateNodeID_FactorConstruction(___, VARARGIN) allows the user to specify 
%   additional attributes supported in VALIDATEATTRIBUTES in a cell array, 
%   VARARGIN.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen
    if strcmp(funcName, 'factorIMU')
        validateattributes(ids, 'numeric', ...
            {'size', [1,dim], 'integer', 'nonnegative', 'nonsparse', varargin{:}}, funcName, varName);
    else
        validateattributes(ids, 'numeric', ...
            {'ncols', dim, 'integer', 'nonempty', 'nonnegative', 'nonsparse', varargin{:}}, funcName, varName);
    end
    if dim>1
        % Check duplicate node IDs
        d = diff(sort(ids,2),1,2);
        coder.internal.errorIf(any(d==0,"all"),'nav:navalgs:factors:NoDuplicateNodeIDs');
    end
end

