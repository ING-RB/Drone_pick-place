function assertValidDim(dim,allowVectorDims)
%MATLAB Code Generation Private Function

%   Checks that the argument DIM is a valid dimension argument.
%   Calls ASSERT.

%   Copyright 2006-2020 The MathWorks, Inc.
%#codegen

if nargin < 2
    allowVectorDims = false;
end
if isempty(coder.target)
    % Take advantage of built-in validation of DIM inputs.
    if allowVectorDims
        try
            sum([],dim);
        catch ME
            throwAsCaller(ME);
        end
    else
        try
            cat(dim,[]);
        catch
            ME = MException( ...
                'MATLAB:getdimarg:dimensionMustBePositiveInteger', ...
                message('MATLAB:getdimarg:dimensionMustBePositiveInteger'));
            throwAsCaller(ME);
        end
    end
    return
end
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.internal.prefer_const(dim,allowVectorDims)
coder.internal.assert(~isenum(dim), ...
    'Coder:toolbox:eml_assert_valid_dim_1');
coder.internal.assert(~isa(dim,'half'), ...
    'Coder:toolbox:DimCannotBeHalf');
if allowVectorDims
    if isnumeric(dim)
        coder.internal.assert(isvector(dim),'MATLAB:getdimarg:invalidDim');
        coder.internal.assert( ...
            coder.internal.isBuiltInNumeric(dim) && ...
            isreal(dim) && isvector(dim) && ...
            allPosIntScalar(dim), ...
            'MATLAB:getdimarg:invalidDim');
    else
        coder.internal.assert( ...
            coder.internal.isTextRow(dim) && strcmp(dim,'all'), ...
            'MATLAB:getdimarg:invalidDim')
    end
else
    coder.internal.assert( ...
        coder.internal.isConst(size(dim)) && isscalar(dim), ...
        'Coder:toolbox:eml_assert_valid_dim_2');
    coder.internal.assert(coder.internal.isBuiltInNumeric(dim) && ...
        isreal(dim) && ...
        dim >= 1 && dim == floor(dim) && ...
        dim <= intmax(coder.internal.indexIntClass), ...
        'MATLAB:getdimarg:dimensionMustBePositiveInteger');
end

%--------------------------------------------------------------------------

function p = allPosIntScalar(x)
coder.internal.prefer_const(x);
coder.inline('always');
MAXDIM = intmax(coder.internal.indexIntClass);
p = true;
for k = 1:numel(x)
    p = p & ...
        x(k) >= 1 & ...
        x(k) == floor(x(k)) & ...
        x(k) <= MAXDIM;
end

%--------------------------------------------------------------------------
