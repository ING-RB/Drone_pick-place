function [v,d] = cdf2rdf(v,d)
%CDF2RDF Complex diagonal form to real block diagonal form.
%   [V,D] = CDF2RDF(V,D) transforms the outputs of EIG(X) (where X is real)
%   from complex diagonal form to a real diagonal form.  In complex
%   diagonal form, D has complex eigenvalues down the diagonal.  In real
%   diagonal form, the complex eigenvalues are in 2-by-2 blocks on the
%   diagonal.  Complex conjugate eigenvalue pairs are assumed to be next to
%   one another.
%
%   Class support for inputs V,D: 
%      float: double, single
%
%   See also EIG, RSF2CSF.

%   Copyright 1984-2021 The MathWorks, Inc. 

ddiag = diag(d);
dimag = imag(ddiag);
ind = find(dimag);
if ~isempty(ind)
    index = ind(1:2:end);
    if (max(index) == size(d,1)) || any(conj(ddiag(index)) ~= ddiag(index+1))
        error(message('MATLAB:cdf2rdf:invalidDiagonal'));
    end
    A = v(:,index);
    B = v(:,index+1);
    sq2 = sqrt(2);
    v(:,index) = (A+B)/sq2;
    v(:,index+1) = (A-B)/(sq2*1i);
    d = real(d);
    n = numel(dimag);
    d(index*(n+1)) = dimag(index);
    d((index-1)*(n+1)+2) = dimag(index+1);
end