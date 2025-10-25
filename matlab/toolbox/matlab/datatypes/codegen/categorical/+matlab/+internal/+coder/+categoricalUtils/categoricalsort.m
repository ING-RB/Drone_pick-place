function [b,ia] = categoricalsort(a,nCats,varargin) %#codegen
%CATEGORICALSORT   Sort using counting sort method.
% This function is for internal use only and will change in a future release.  Do not
% use this function.

%   Copyright 2020 The MathWorks, Inc.

narginchk(2,4);

coder.internal.prefer_const(nCats,varargin);

coder.internal.assert(isreal(a),'MATLAB:categorical:sort:firstArgType');

coder.internal.assert(isa(a,'uint8') || isa(a,'uint16') || isa(a,'uint32'), ...
    'MATLAB:categorical:sort:firstArgType');

coder.internal.assert(isnumeric(nCats) && isscalar(nCats) && isreal(nCats) && nCats >= 0 && isfinite(nCats), ...
    'MATLAB:categorical:sort:secondArgType');

% Verify that the value of nCats is not fractional.
coder.internal.assert(cast(nCats,class(a)) == nCats,'MATLAB:categorical:sort:secondArgType');

% Parse the optional arguments. The default value for mode is ascend and the
% default value for dim is the first non-singleton dim. For codegen, a varsize
% dim is considered as non-singleton dim.
if nargin == 3
    arg = varargin{1};
    if ischar(arg) || matlab.internal.coder.datatypes.isScalarText(arg)
        dimToSort =  coder.internal.nonSingletonDim(a);
        isAscend = modeParse(arg);
    else
        dimToSort = dimParse(arg);
        isAscend = true;
    end
elseif nargin == 4
    dimToSort = dimParse(varargin{1});
    isAscend = modeParse(varargin{2});
else
    dimToSort = coder.internal.nonSingletonDim(a);
    isAscend = true;
end

if dimToSort <= ndims(a)
    nToSort = size(a,dimToSort);
else
    nToSort = 1;
end

nElem = numel(a);

if nElem <= 1 || nToSort == 1
    % If the third input is greater than ndims, return original array for first
    % output and return ones(size(a)) for second output.
    % This is consistent with other datafuns.
    for i = 1:nElem
        % Check first input a for numbers greater than nCats
        coder.internal.assert(a(i) <= nCats, ...
            'MATLAB:categorical:sort:ElementTooLarge');
    end
    b = a;
    ia = ones(size(a));
    return;
end

% Identify the set of vectors along the dimension to be sorted and then
% individually call countingsort for each one.
ia = zeros(size(a));
b = a;
stride = double(coder.internal.prodsize(a,'below',dimToSort));
npages = double(coder.internal.prodsize(a,'above',dimToSort));
pagesize = nToSort*stride;
currVec = zeros(nToSort,1,'like',b);
for i = 1:npages
    pageoffset = (i - 1)*pagesize;
    for j = 1:stride
        idx0 = pageoffset + j;
        % Copy vector to currVec. Do this to allow varsize ND to become vectors
        % at runtime.
        for k = 1:nToSort
            currVec(k) = b(idx0 + (k - 1)*stride);
        end
        [currVec,currIa] = countingsort(currVec,nToSort,isAscend,nCats);
        % Copy output vectors into the output matrices.
        for k = 1:nToSort
            b(idx0 + (k - 1)*stride) = currVec(k);
            ia(idx0 + (k - 1)*stride) = currIa(k);
        end
    end
end

function isAscend = modeParse(flag)
% Parse the direction flag and check that it is either ascend or descend.
coder.internal.prefer_const(flag);
coder.internal.assert(coder.internal.isConst(flag),'Coder:toolbox:SortDirMustBeConstant');
coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(flag), ...
    'MATLAB:categorical:sort:sortDirection');
isAscend = strncmpi('ascend',flag,max(strlength(flag),1));
coder.internal.assert(isAscend || strncmpi('descend',flag,max(strlength(flag),1)), ...
    'MATLAB:categorical:sort:sortDirection');

function dimToSort = dimParse(dim)
% Check the dim argument to sort.
coder.internal.prefer_const(dim);
coder.internal.assert(isnumeric(dim) && isscalar(dim) && isreal(dim) && (dim > 0) && isfinite(dim),...
    'MATLAB:categorical:sort:notPosInt');
% Verify that the value of dims is not fractional.
coder.internal.assert(cast(dim,'uint32') == dim,'MATLAB:categorical:sort:notPosInt');

dimToSort = dim;

function insertAt = compInsertAt(bins, nToSort, nCats, isAscend)
% Compute the values for insertAt based on the bin values.
insertAt = zeros(nCats+1,1);

if nCats == 0
    insertAt(1) = 1;
    return;
end

if isAscend
    % sort 1 2 3 ... nCats 0
    insertAt(2) = 1;
    for i = 3:nCats+1
        insertAt(i) = insertAt(i-1) + bins(i-1);
    end
    insertAt(1) = insertAt(nCats+1) + bins(nCats+1);
else % descend
    % sort 0 nCats ... 3 2 1
    insertAt(1) = 1;
    insertAt(2) = nToSort - bins(2) + 1;
    for i = 3:nCats+1
        insertAt(i) = insertAt(i-1) - bins(i);
    end
end

function [a,ia] = countingsort(a, nToSort, isAscend, nCats)
% Returns sorted output and indices
bins = zeros(nCats+1,1);
for i = 1:nToSort
    coder.internal.assert(a(i) <= nCats, ...
        'MATLAB:categorical:sort:ElementTooLarge');
    bins(a(i)+1) = bins(a(i)+1) + 1;
end

if nargout == 2
    % Compute ia if requested
    ia = zeros(size(a));
    insertAt = compInsertAt(bins, nToSort, nCats, isAscend);
    for i = 1:nToSort
        j = a(i)+1;
        ia(insertAt(j)) = i;
        insertAt(j) = insertAt(j) + 1;
    end
end

if isAscend
    % sort 1 2 3 ... nCats 0
    i = 1;
    
    for j = 2:nCats+1
        for k = 1:bins(j)
            a(i) = j-1;
            i = i + 1;
        end            
    end
    
    for k = 1:bins(1)
        a(i) = 0;
        i = i + 1;
    end
else
    % sort 0 nCats ... 3 2 1
    i = 1;
    
    for k = 1:bins(1)
        a(i) = 0;
        i = i + 1;
    end
    
    for j = nCats+1:-1:2
        for k = 1:bins(j)
            a(i) = j-1;
            i = i + 1;
        end            
    end
end