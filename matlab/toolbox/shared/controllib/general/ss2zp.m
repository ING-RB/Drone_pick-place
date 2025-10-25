function [z,p,k] = ss2zp(a,b,c,d,iu)
%SS2ZP  State-space to zero-pole conversion.
%   [Z,P,K] = SS2ZP(A,B,C,D,IU)  calculates the transfer function in
%   factored form:
%
%                     -1          (s-z1)(s-z2)...(s-zn)
%       H(s) = C(sI-A) B + D =  k ---------------------
%                                 (s-p1)(s-p2)...(s-pn)
%   of the system:
%       .
%       x = Ax + Bu
%       y = Cx + Du
%
%   from the single input IU.  The vector P contains the pole
%   locations of the denominator of the transfer function.  The
%   numerator zeros are returned in the columns of matrix Z with as
%   many columns as there are outputs y.  The gains for each numerator
%   transfer function are returned in column vector K.
%
%   See also ZP2SS,PZMAP,TZERO, EIG.

%   Copyright 1984-2020 The MathWorks, Inc.
%#codegen
narginchk(4,5)
[msg,a,b,c,d] = abcdchk(a,b,c,d);

isMatlab = coder.target('MATLAB');

if isMatlab
    error(msg);
end

[nx,~] = size(a);
if nargin < 5
    if nx > 0
        [~,nu] = size(b);
    else
        [~,nu] = size(d);
    end

    coder.internal.errorIf(nu > 1,'Controllib:general:NeedIU');
    iu = 1;
end


%Validate iu
validateattributes(iu,{'numeric'},{'real','integer','positive','scalar'},'ss2zp','IU',5)
if ~isempty(b)
    coder.internal.errorIf(iu(1) > size(b,2),'Controllib:general:IncorrectIU');
end

%Checking for single precision
if isa(a,'single') || isa(b,'single') || isa(c,'single') || isa(d,'single')
    as = single(a);
    bs = single(b);
    cs = single(c);
    ds = single(d);
else
    as = a;
    bs = b;
    cs = c;
    ds = d;
end

% Remove relevant input:
if ~isempty(bs)
    b1 = bs(:,iu(1));
else
    b1 = bs;
end
if ~isempty(ds)
    d1 = ds(:,iu(1));
else
    d1 = ds;
end


% Do poles first
p = eig(a);

% Compute zeros and gains
[ny,nu] = size(d1);

isReal = isreal(a) && isreal(b) && isreal(c) && isreal(d);

if isReal
    k = coder.nullcopy(zeros(ny,nu,class(as)));
else
    k = coder.nullcopy(complex(zeros(ny,nu,class(as))));
end

if isMatlab
    ztemp = inf(nx,ny,class(as));
else
    ztemp = coder.nullcopy(complex(zeros(nx,ny,class(as))));
end

mz = 0;
if nu ==1
    for i = 1:ny
        % Note: Codegen version of ltipack.sszeroCG may pad zi with inf's
        [zi,gi] = ltipack.sszeroCG(as,b1,cs(i,:),d1(i,:),[]);
        ztemp(1:numel(zi),i) = zi;
        if isReal
            k(i) = real(gi);
        else
            k(i) = gi;
        end
        mz = max(mz,sum(isfinite(zi)));
    end
end
z = ztemp(1:mz,1:ny);
