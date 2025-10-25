function e = end(obj,k,n)
%END Overloaded for spatial matrices

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Adding 1s to the end of s below is for syntax like:
% T is 2 x 3 x 4
% T(:,:,:,end,:,:,:)  - this is valid syntax.
% This is the same as T(:,:,:,1,:,:,:). No value other
% than 1 works. So return 1.

    s = size(obj.MInd);
    nds = numel(s);
    s = [ s,ones(1,n - length(s) + 1) ];
    if n==1 && k==1
        e = prod(s);
    elseif n==nds || k<n
        e = s(k);
    else  % k == n || n ~= nds
        e = prod(s(k:end));
    end

end
