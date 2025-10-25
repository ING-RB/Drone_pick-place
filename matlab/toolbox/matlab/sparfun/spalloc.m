function s = spalloc(m,n,nzmax,typename)
%SPALLOC Allocate space for sparse matrix.
%   S = SPALLOC(M,N,NZMAX) creates an M-by-N all zero sparse matrix
%   with room to eventually hold NZMAX nonzeros.
%

%   S = SPALLOC(M,N,NZMAX,TYPENAME) creates a sparse matrix of data type 
%       TYPENAME. TYPENAME can be "single", "double", or "logical".
%   For example
%       s = spalloc(n,n,3*n);
%       for j = 1:n
%           s(:,j) = (a sparse column vector with 3 nonzero entries);
%       end
%       
%       s = spalloc(n,n,3*n, "single");
%       for j = 1:n
%           s(:,j) = (a sparse column vector with 3 nonzero single entries);
%       end
%   See also SPONES, SPDIAGS, SPRANDN, SPRANDSYM, SPEYE, SPARSE.

%   Copyright 1984-2024 The MathWorks, Inc.

values = [];

if nargin==4
    support = matlab.internal.feature("SingleSparse");
    if support
        % Only "single", "double", and "logical" are accepted typenames.

        if ~((isstring(typename) && isscalar(typename)) || (ischar(typename) && isrow(typename))) ...
                || (~strcmp(typename, "double") && ~strcmp(typename, "single") && ~strcmp(typename, "logical"))
            error(message('MATLAB:spalloc:invalidTypename'))
        end
        values = cast(values, typename);
    else
        % Throw same error as when only 3 inputs were accepted
        error(message('MATLAB:TooManyInputs'));
    end
end

s = sparse([],[],values,m,n,nzmax);
end
