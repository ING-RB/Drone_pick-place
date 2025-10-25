function [a,b,c,d] = zp2ss(z,p,k)
%ZP2SS  Zero-pole to state-space conversion.
%   [A,B,C,D] = ZP2SS(Z,P,K)  calculates a state-space representation:
%       .
%       x = Ax + Bu
%       y = Cx + Du
%
%   for a system given a set of pole locations in column vector P,
%   a matrix Z with the zero locations in as many columns as there are
%   outputs, and the gains for each numerator transfer function in
%   vector K.  The A,B,C,D matrices are returned in block diagonal
%   form.
%
%   The poles and zeros must correspond to a proper system. If the poles
%   or zeros are complex, they must appear in complex conjugate pairs,
%   i.e., the corresponding transfer function must be real.
%
%   See also SS2ZP, ZP2TF, TF2ZP, TF2SS, SS2TF.

%   Thanks to G.F. Franklin
%   Copyright 1984-2020 The MathWorks, Inc.
%#codegen
narginchk(3,3);
[zCol,pCol,kCol,isSIMO] = parse_input(z,p,k);
if isSIMO
    % If it's multi-output, we can't use the nice algorithm
    % that follows, so use the numerically unreliable method
    % of going through polynomial form, and then return.
    [num,den] = zp2tf(zCol,pCol,kCol); % Suppress compile-time diagnostics
    [a,b,c,d] = tf2ss(num,den);
    return
end

% Strip infinities and throw away.
pf = pCol(isfinite(pCol));
zf = zCol(isfinite(zCol));

% Group into complex pairs
np = length(pf);
nz = length(zf);
ONE  = ones(1,1,class(pCol));
ZERO = zeros(1,1,class(pCol)); 
isSingle = isa(pCol,'single');
if coder.target('MATLAB')
    try
        % z and p should have real elements and exact complex conjugate pair.
        pf = cplxpair(pf,ZERO);
        zf = cplxpair(zf,ZERO);
    catch
        % If fail, revert to use the old default tolerance.
        % The use of tolerance in checking for real entries and conjugate pairs
        % may result in misinterpretation for edge cases. Please review the
        % process of how z and p are generated.
        if isSingle
            pf = cplxpair(pf,100*eps('single'));
            zf = cplxpair(zf,100*eps('single'));
        else
            pf = cplxpair(pf,1e6*np*norm(pf)*eps + eps);
            zf = cplxpair(zf,1e6*nz*norm(zf)*eps + eps);
        end
    end
else
    [pf,isPolePairable] = coder.internal.cplxpair(pf,ZERO);
    if ~isPolePairable
        if isSingle
            pf = cplxpair(pf,100*eps('single'));
        else
            pf = cplxpair(pf,1e6*np*norm(pf)*eps + eps);
        end
    end
    [zf,isZeroPairable] = coder.internal.cplxpair(zf,ZERO);
    if ~isZeroPairable
        if isSingle
            zf = cplxpair(zf,100*eps('single'));
        else
            zf = cplxpair(zf,1e6*nz*norm(zf)*eps + eps);
        end
    end
end

% Initialize state-space matrices
a = zeros(np,class(pCol));
b = zeros(np,1,class(pCol));
c = zeros(1,np,class(pCol));
d = ONE;

oddPoles = false;
oddZerosOnly = false;
% If odd number of poles AND zeros, convert the pole and zero
% at the end into state-space.
% H(s) = (s-z1)/(s-p1) = (s + num(2)) / (s + den(2))
if rem(np,2) && rem(nz,2)
    a(1,1) = real(pf(np,1));
    b(1) = ONE;
    c(1) = real(pf(np,1) - zf(nz,1));
    d = ONE;
    np = np - 1;
    nz = nz - 1;
    oddPoles = true;
elseif rem(np,2)
    % If odd number of poles only, convert the pole at the
    % end into state-space.
    % H(s) = 1/(s-p1) = 1/(s + den(2))
    a(1,1) = real(pf(np,1));
    b(1) = ONE;
    c(1) = ONE;
    d = ZERO;
    np = np - 1;
    oddPoles = true;
elseif rem(nz,2)
    % If odd number of zeros only, convert the zero at the
    % end, along with a pole-pair into state-space.
    % H(s) = (s+num(2))/(s^2+den(2)s+den(3))
    num = real(poly(zf(nz,1)));
    den = real(poly(pf(np-1:np,1)));
    wn = sqrt(prod(abs(pf(np-1:np,1))));
    if wn == ZERO
        wn = ONE;
    end
    t = diag([ONE ONE./wn]); % Balancing transformation
    a(1:2,1:2) = t\[-den(2) -den(3); ONE ZERO]*t;
    b(1:2) = t\[ONE; ZERO];
    c(1:2) = [ONE num(2)]*t;
    d = ZERO;
    nz = nz - 1;
    np = np - 2;
    oddZerosOnly = true;
end
% Now we have an even number of poles and zeros, although not
% necessarily the same number - there may be more poles.
% H(s) = (s^2+num(2)s+num(3))/(s^2+den(2)s+den(3))
% Loop through rest of pairs, connecting in series to build the model.
i = 1;
while i < nz
    index = i:i+1;
    num = real(poly(zf(index,1)));
    den = real(poly(pf(index,1)));
    wn = sqrt(prod(abs(pf(index,1))));
    if wn == ZERO
        wn = ONE;
    end
    t = diag([ONE ONE./wn]); % Balancing transformation
    a1 = t\[-den(2) -den(3); ONE ZERO]*t;
    b1 = t\[ONE; ZERO];
    c1 = [num(2)-den(2) num(3)-den(3)]*t;
    d1 = ONE;
    % [a,b,c,d] = series(a,b,c,d,a1,b1,c1,d1);
    % Next lines perform series connection
    if oddPoles
        % when number of poles is odd, the first element of a,b and c are already
        % assigned. Now start the assignment from second index
        j = i-1;
    elseif oddZerosOnly
        % when number of zeros alone is odd, the first 2x2 portion of a and
        % first two elements of b and c are already assigned. Now start the assignment
        %from third index
        j = i;
    else
        % when the number of zeros and poles are even, none of the elements of
        % a,b or c is assigned, so start assignment from first index.
        j = i-2;
    end
    
    if  j == -1
        a(1:2,1:2) = a1;
    else
        a(j+2:j+3,1:j+1) = b1*c(1:j+1);
        a(j+2:j+3,j+2:j+3) = a1;
    end
    b(j+2:j+3) = b1*d;
    c(j+2:j+3) = c1;
    d = d1*d;
    i = i+2;
end

% Take care of any left over unmatched pole pairs.
%   H(s) = 1/(s^2+den(2)s+den(3))
while i < np
    den = real(poly(pf(i:i+1,1)));
    wn = sqrt(prod(abs(pf(i:i+1,1))));
    if wn == ZERO
        wn = ONE;
    end
    t = diag([ONE ONE./wn]); % Balancing transformation
    a1 = t\[-den(2) -den(3); ONE ZERO]*t;
    b1 = t\[ONE; ZERO];
    c1 = [ZERO ONE]*t;
    d1 = ZERO;
    % [a,b,c,d] = series(a,b,c,d,a1,b1,c1,d1);
    % Next lines perform series connection
    % Adjust the indices here depending on the number of poles and
    % zeros such that the correct portions of the matrices are assigned
    % as in the previous loop.
    if oddPoles
        j = i-1;
    elseif oddZerosOnly
        j = i;
    else
        j = i-2;
    end
    
    if j == -1
        a(1:2,1:2) = a1;
        c(1:2) = c1;
    else
        a(j+2:j+3,1:j+1) = b1*c(1:j+1);
        a(j+2:j+3,j+2:j+3) = a1;
        c(1:j+1) = d1*c(1:j+1);
        c(j+2:j+3) = c1;
    end
    b(j+2:j+3) = b1*d;
    d = d*d1;
    i = i + 2;
end

% Apply gain k:
c = c*kCol(1);
d = d*kCol(1);
end

%----------------------------------------------------------------------------
function [zCol,pCol,kCol,isSIMO] = parse_input(z,p,k)
%PARSE_INPUT   Make sure input args are valid.

validateattributes(z,{'numeric'},{'2d'},'zp2ss','Z',1);
validateattributes(k,{'numeric'},{'vector'},'zp2ss','K',3);
if ~isempty(p)
    validateattributes(p,{'numeric'},{'vector'},'zp2ss','P',2);
else
    validateattributes(p,{'numeric'},{},'zp2ss','P',2);
end
if isa(z,'single') || isa(p,'single') || isa(k,'single')
    zs = single(z);
    ps = single(p);
    ks = single(k);
else
    zs = z;
    ps = p;
    ks = k;
end
% Columnize p
pCol = ps(:);

% Columnize k
kCol = ks(:);
% Check size of z
if (isempty(zs) || isvector(zs))
    % z is a vector or an empty, columnize it
    zCol = zs(:);
else
    % z is a matrix
    zCol = zs;
end

% Check for properness
coder.internal.errorIf(size(zCol,1) > length(pCol),'Controllib:general:improperSystem');

% Check for the appropriate length of k
coder.internal.errorIf(length(kCol) ~= size(zCol,2) && (~isempty(zCol)),'Controllib:general:zkLengthMismatch');

isSIMO = length(kCol) > 1;
end

% LocalWords:  Cx Controllib Columnize columnize zk
