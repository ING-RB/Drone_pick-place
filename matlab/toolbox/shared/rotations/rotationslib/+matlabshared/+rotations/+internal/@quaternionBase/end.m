function e = end(obj,k,n)
%END Overloaded for quaternions

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 


%Adding 1s to the end of s below is for syntax like:
% q is 2 x 3 x 4
% q(:,:,:,end,:,:,:)  -valid syntax.
%This is the same as q(:,:,:,1,:,:,:). No value other
%than 1 works. So return 1.

s = size(obj.a);
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
