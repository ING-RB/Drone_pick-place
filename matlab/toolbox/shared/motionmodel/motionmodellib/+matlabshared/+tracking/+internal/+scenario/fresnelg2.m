function z = fresnelg2(x,dk,k,theta)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELG2 Generalized Fresnel integral.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   Z = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FRESNELG2(L, DK, K, THETA)
%   returns the complex Fresnel integral:
%
%              /L
%              |
%        Z  =  |  exp(1i * ((DK/2)*s.^2 + K*s + THETA)) ds
%              |
%              /0
%    
%   evaluated over corresponding elements of L, DK, K, and THETA.  
%   L, DK, K and THETA must all have the same dimensions.

%#codegen

%   Copyright 2017-2020 The MathWorks, Inc.

assert(isequal(size(x),size(dk)) && isequal(size(x),size(k)) && isequal(size(x), size(theta)));

thresh = dk ./ (k .* k);

igt = find(thresh >  1e-6);
ilt = find(thresh < -1e-6);
ism = find(-1e-6 <= thresh & thresh <= 1e-6);
izero = find(abs(dk).*x.^2 < 1e-3 & abs(k.*x) < 1e-3);

z = complex(zeros(size(x)));

if ~isempty(igt)
    z1 = matlabshared.tracking.internal.scenario.fresnel(sqrt(dk(igt)/pi).*x(igt)+k(igt)./sqrt(pi.*dk(igt)));
    z0 = matlabshared.tracking.internal.scenario.fresnel(k(igt)./sqrt(pi.*dk(igt)));
    z(igt) = sqrt(pi./dk(igt)).*exp(1i*(theta(igt)-k(igt).*k(igt)./(2*dk(igt)))).*(z1-z0);
end

if ~isempty(ilt)
    z1 = matlabshared.tracking.internal.scenario.fresnel(sqrt(-dk(ilt)/pi).*x(ilt)-k(ilt)./sqrt(-pi*dk(ilt)));
    z0 = matlabshared.tracking.internal.scenario.fresnel(-k(ilt)./sqrt(-pi.*dk(ilt)));
    z(ilt) = conj(sqrt(-pi./dk(ilt)).*exp(-1i*(theta(ilt)-k(ilt).*k(ilt)./(2.*dk(ilt)))).*(z1-z0));
end

if ~isempty(ism)
    z(ism) = fresnelgsma(x(ism),dk(ism),k(ism),theta(ism));
end

if ~isempty(izero)
    z(izero) = fresnelgzero(x(izero),dk(izero),k(izero),theta(izero));
end


function z = fresnelgsma(x,dk,k,theta)
% Evaluate:
%              /x
%              |
%        z  =  |   exp(i * ((dk/2)*s.^2 + k*s + theta)) ds
%              |
%              /0
%
% by Maclaurin series expansion about dk=0.

nikx = -1i*k .* x;
nhikx = nikx/2;

C = 0.5i*dk ./ k.^2;
m2C = -2*C;
hidkxx = 0.5i*dk.*x.^2;

e = exp(-nikx);

% t = int( (0.5i*dk.*s.^2).^0./factorial(0).*exp(1i*k*s), s, 0, x)/x;
t = (1-e)./nikx;

p = -e;
z = t;

for n=1:20
    % t = int( (0.5i*dk.*s.^2).^n./factorial(n).*exp(1i*k*s), s, 0, x)/x;
    t = m2C .* ((2*n-1).*t + p.*(n+nhikx));
    z = z + t;
    p = p.*hidkxx./(n+1);
end

z = x .* z .* exp(1i*theta);

function z = fresnelgzero(x,dk,k,theta)
% Evaluate:
%              /x
%              |
%        z  =  |   exp(i * ((dk/2)*s.^2 + k*s + theta)) ds
%              |
%              /0
%
% by polynomial expansion where abs(dk*x^2/2) and abs(k*x) are both small

N = 5;

% expand exp(i*(dk/2).*x^2)
% assume A(:,0) = 1.
% A(:,k) = (1i*(dk/2)*x.^2))^k/k!
a = 0.5i*dk.*x.^2;
A = repmat(a,1,N);
A = bsxfun(@rdivide,A,1:N);
A = cumprod(A,2);

% expand exp(i*k.*x)
% assume B(:,0) = 1.
% B(:,k) = (1i*k.*x)^k/k!
b = 1i*k.*x;
B = repmat(b,1,N);
B = bsxfun(@rdivide,B,1:N);
B = cumprod(B,2);

z = ones(length(x),1,'like',complex(x(1)));
for i=1:N
    z = z + A(:,i)./(2*i+1);
end

for j=1:N
    z = z + B(:,j)./(j+1);
end

% do cross terms
for i=1:N-1
    for j=1:N-2*i
        z = z + A(:,i).*B(:,j)./(2*i+j+1);
    end
end

z = z .* x .* exp(1i*theta);
