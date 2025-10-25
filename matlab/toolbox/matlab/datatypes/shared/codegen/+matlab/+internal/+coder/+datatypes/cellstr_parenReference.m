function b = cellstr_parenReference(ain, subs)%#codegen
%CELLSTR_PARENREFERENCE Codegen helper for parenReference on cellstr vectors.

%   Copyright 2020-2023 The MathWorks, Inc.

% This function is for internal use only and will change in a future release.
% Do not use this function.

% Assert that the input is indeed a cellstr vector
coder.internal.assert(iscellstr(ain), 'MATLAB:datatypes:MustBeCellstr'); %#ok<ISCLSTR>
coder.internal.assert(isConstVector(ain) || isempty(ain),'MATLAB:datatypes:MustBeVector'); 

a = ain;
if coder.internal.isConst(size(a))
    coder.varsize('a',[],[0 0]);
end

if islogical(subs)
    len = nnz(subs);
    idx = 1;
    
    [~, szA1, szA2] = isConstVector(a, len);
    b = coder.nullcopy(cell(szA1, szA2));
    
    for i = 1:numel(subs)
        if subs(i)
            b{idx} = a{i};
            idx = idx + 1;
        end
    end
else
    % Only numeric and logical subscripts are supported.
    coder.internal.assert(isnumeric(subs), 'MATLAB:matrix:unableToUseTypeAsIndex', class(subs));
    
    len = numel(subs);
    [~, szA1, szA2] = isConstVector(a, len);
    isVectorSubs = isConstVector(subs, len);
    
    % If subs is known to be a vector at compile time, 'a' will dictate the output
    % size, otherwise subs dictates the output size.
    if isVectorSubs
        b = coder.nullcopy(cell(szA1, szA2));
    else
        % Error if subs turn out to be vector at runtime
        coder.internal.errorIf(size(subs, 1) == 1 || size(subs, 2) == 1, ...
            'Coder:FE:PotentialMatrixMatrix_VM');
        b = coder.nullcopy(cell(size(subs)));
    end

    for i = 1:len
       b{i} = a{subs(i)}; 
    end
end
end

function [tf, sz1, sz2] = isConstVector(a, len)
    % Helper function to check if a is known to be a vector at compile time and
    % returns the size values for a vector whose length is equal to len and
    % orientation matches a. Returning size as a 1x2 double does not preserve
    % the constness of the other dim if len is non-constant, so return the two
    % sizes separately.
    if nargin < 2
        len = numel(a);
    end
    
    if coder.internal.isConst(size(a, 2)) && size(a, 2) == 1
        tf = true;
        sz1 = len;
        sz2 = 1;
    elseif coder.internal.isConst(size(a, 1)) && size(a, 1) == 1
        tf = true;
        sz1 = 1;
        sz2 = len;
    else
        tf = false;
        [sz1, sz2] = size(a);
    end
end
