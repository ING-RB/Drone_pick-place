function [z,p,k] = tf2zp(num,den)
%TF2ZP  Transfer function to zero-pole conversion.
%   [Z,P,K] = TF2ZP(NUM,DEN)  finds the zeros, poles, and gains:
%
%                 (s-z1)(s-z2)...(s-zn)
%       H(s) =  K ---------------------
%                 (s-p1)(s-p2)...(s-pn)
%
%   from a SIMO transfer function in polynomial form:
%
%               NUM(s)
%       H(s) = --------
%               DEN(s)
%
%   Vector DEN specifies the coefficients of the denominator in
%   descending powers of s.  Matrix NUM indicates the numerator
%   coefficients with as many rows as there are outputs.  The zero
%   locations are returned in the columns of matrix Z, with as many
%   columns as there are rows in NUM.  The pole locations are returned
%   in column vector P, and the gains for each numerator transfer
%   function in vector K.
%
%   For discrete-time transfer functions, it is highly recommended to
%   make the length of the numerator and denominator equal to ensure
%   correct results.  You can do this using the function EQTFLENGTH in
%   the Signal Processing Toolbox.  However, this function only handles
%   single-input single-output systems.
%
%   See also ZP2TF.

%   Copyright 1984-2020 The MathWorks, Inc.

%#codegen

[nn,mn] = size(num);
[nd,md] = size(den);

% Denominator must be a row vector
coder.internal.errorIf(nd>1, 'Controllib:general:denominatorNotRowVector');
% Transfer function must be proper
coder.internal.errorIf(mn>md, 'Controllib:general:improperTransferFunction');

% Cast to enforce precision
if (isa(num,'single') || isa(den,'single'))
    numIn = single(num);
    denIn = single(den(:).');
    linf = single(inf);
else
    numIn = num;
    denIn = den(:).';
    linf = inf;
end

if ~isempty(denIn)
    coef = denIn(1);
else
    coef = ones(1,'like',denIn);
end

if coef == 0
    coder.internal.error('Controllib:general:DenomZeroLeadCoef')
end

% Remove leading columns of zeros from numerator
n = 1; % Column index of 'num'
if ~isempty(numIn)
    while(n<=mn && all(numIn(:,n)==0))
        n = n+1;
    end
end
numT = numIn(:,n:end);

[ny,np] = size(numT);

% Poles
p = roots(denIn);

% Zeros and Gain
if ~coder.target('MATLAB')
    % for code generation
    k = complex(zeros(ny,1,'like',numT));
    z = complex(linf(ones(np-1,1),ones(ny,1)));
else
    % for execution in MATLAB
    k = zeros(ny,1,'like',numT);
    z = linf(ones(np-1,1),ones(ny,1));
end

for i=1:ny
    zz = roots(numT(i,:));
    if ~isempty(zz)
        z(1:length(zz), i) = zz;
    end
    ndx = find(numT(i,:)~=0);
    if ~isempty(ndx)
        k(i,1) = numT(i,ndx(1))./coef;
    end
end