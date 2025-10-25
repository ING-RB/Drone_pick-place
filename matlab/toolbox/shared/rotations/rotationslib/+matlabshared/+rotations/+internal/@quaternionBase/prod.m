function p = prod(q,dim)
%PROD Product of elements
%   S = PROD(X) is the quaternion product of the elements of the vector X.
%   If X is a matrix, S is a row vector with the quaternion product over
%   each column. For N-D arrays, PROD(X) operates on the first
%   non-singleton dimension.
%
%   PROD(X,DIM) works along the dimension DIM.

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

% Permute so dim is first. Handle the case when dim=1 or dim = last dim
a = q.a;
b = q.b;
c = q.c;
d = q.d;

s = size(a);
nd = ndims(a);

if nargin < 2
    dimvector = find(s ~= 1, 1, 'first');
    if isempty(dimvector)
        dim = 1;
    else    
        dim = dimvector(1);
    end
end
pv = zeros(1,nd);
if dim == 1
    pv(:) = 1:nd;
elseif dim == nd
    pv(:) = [dim 1:(dim-1)];
else
    pv(:) = [ dim, 1:(dim-1) (dim+1):nd];
end

mpa = permute(a, pv);
mpb = permute(b, pv);
mpc = permute(c, pv);
mpd = permute(d, pv);



sp = s(pv); % permute the size vector to match mp.
N= prod(sp(2:end)); % compute the number of answers to compute
spfinal = [1 sp(2:end)]; % the size of the final vector. The first (prod)
                         % dimension becomes 1

% Allocate an answer bin for each final output.
% Use a vector for now, reshape later.
oa = ones(1, N, "like", q.a); 
ob = zeros(1, N, "like", q.b); 
oc = zeros(1, N, "like", q.c); 
od = zeros(1, N, "like", q.d); 

for ii=1:N % Number of final products to compute
    offset = sp(1)*(ii-1);  % compute skip offset for next product
    for jj=1:sp(1) % Number of multiplicands in a product
        
        xa = oa(ii);
        xb = ob(ii);
        xc = oc(ii);
        xd = od(ii);
        ya = mpa(jj+offset);
        yb = mpb(jj+offset);
        yc = mpc(jj+offset);
        yd = mpd(jj+offset);
        
        oa(ii) = xa .* ya - xb .* yb - xc .* yc - xd .* yd;
        ob(ii) = xa .* yb + xb .* ya + xc .* yd - xd .* yc;
        oc(ii) = xa .* yc - xb .* yd + xc .* ya + xd .* yb;
        od(ii) = xa .* yd + xb .* yc - xc .* yb + xd .* ya;
        
        
    end
end

% Reshape to an array
oresha = reshape(oa, spfinal); 
oreshb = reshape(ob, spfinal); 
oreshc = reshape(oc, spfinal); 
oreshd = reshape(od, spfinal); 

% Permute back to intended shape.
pa = ipermute(oresha, pv); 
pb = ipermute(oreshb, pv); 
pc = ipermute(oreshc, pv); 
pd = ipermute(oreshd, pv); 

% Replace if sim, construct in codegen.
if isempty(coder.target)
    p = q;
    p.a = pa;
    p.b = pb;
    p.c = pc;
    p.d = pd;
else
    p = quaternion(pa,pb,pc,pd);
end
end
