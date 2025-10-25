function [origIdx, prdIdx] = findOriginalIndex(prd, v)
%This function is for internal use only. It may be removed in the future.
%FINDORIGINALINDEX Find indices contributing to nonzero elements 
%   IV = FINDORIGINALINDEX(PRD,V) returns the linear indices in V that
%   contribute to the nonzero elements of PRD. PRD is usually the result of
%   some singleton/implicit expansion operation on V.
%
%   [IV,IP] = FINDORIGINALINDEX(PRD,V) additionally returns the linear
%   indices of the nonzero elements in PRD in the variable IP.

%   Copyright 2018 The MathWorks, Inc.    

% Caveats:
% This does not support codegeneration.

psize = size(prd);
vsize = size(v);
assert(isCompatible(vsize, psize), message('MATLAB:dimagree'));

prdIdx = reshape(find(prd), [],1); % linear index of condition. Make column.
if isempty(prdIdx)
    origIdx = prdIdx;
    return;
end
c = cell(1, ndims(prd));

[c{:}] = ind2sub(psize, prdIdx);  %convert to subscripts.

idxmat = cell2mat(c); % Each row is a set of indices in prd that matches condition


% v may have fewer dimensions than prd. Need to fill in missing dimension with 1s.
% Any dimensions v has is missing, 1, or the same as in prd.

vdims = ones(1,ndims(prd));
vdims(1:numel(vsize)) = vsize;

% Using min here basically subs in 1s where there were missing dimensions
% in vdims.
vidx = min(idxmat, vdims);
vidxc = num2cell(vidx, 1); % Break columns into cells for making a csl
origIdx = sub2ind(size(v), vidxc{:});
end

function tf = isCompatible(origSize, newSize)
% Check if origSize and newSize are compatible. newSize must be 1 or the same as 
% origSize in every location. newSize can be longer than origSize.

if numel(origSize) > numel(newSize)
    tf = false;
else
    tf = true;
    
    for ii=1:numel(origSize)
        tf = tf && ( (origSize(ii) == 1) || (newSize(ii) == origSize(ii)));
    end
end    
end