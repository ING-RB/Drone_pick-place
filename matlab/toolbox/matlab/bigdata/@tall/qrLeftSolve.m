function [R,x] = qrLeftSolve(A,b)
% Use the economy Q-R decomposition of tall array A to find x and R such
% that [Q,R] = qr(A,0) and x = R\(Q'*b). Note that for each chunk we use
% the economy decomposition so both R and b returned to client are small.

% Copyright 2017-2024 The MathWorks, Inc.

inAdapA = matlab.bigdata.internal.adaptors.getAdaptor(A);
inAdapB = matlab.bigdata.internal.adaptors.getAdaptor(b);

% Treat logicals and chars as doubles
A = iCharLogical2Double(A, inAdapA);
b = iCharLogical2Double(b, inAdapB);

% Reduce down to an in-memory problem
[R,b] = reducefun(@iChunkQR, A, b);

% Solve, requires to know the maximum size of A.
maxSizeA = max(size(A));
x = clientfun(@iSolve, R, b, maxSizeA);

% If n=size(A,2), R is nxn and x is nx1.
if isSizeKnown(inAdapA, 2)
    n = getSizeInDim(inAdapA, 2);
    R.Adaptor = setKnownSize(R.Adaptor, [n n]);
    if isSizeKnown(inAdapB, 2)
        m = getSizeInDim(inAdapB, 2);
        x.Adaptor = setKnownSize(x.Adaptor, [n m]);
    else
        x.Adaptor = setTallSize(x.Adaptor, n);
    end
end
end

function x = iCharLogical2Double(x, xAdap)
% Convert char or logical inputs to doubles

if ismember(xAdap.Class, ["", "char", "logical"])
    if istall(x)
        % Convert tall input
        x = elementfun(@iApplyCharLogical2Double, x);
    else
        % Convert in-memory input
        x = iApplyCharLogical2Double(x);
    end
end
end

function y = iApplyCharLogical2Double(y)
% Convert one block or one in-memory char or logical inputs to doubles
if ischar(y) || islogical(y)
    y = double(y);
end
end

function [R,b] = iChunkQR(A,b)
% Perform QR on one chunk of A and B, returning the economy R and reduced
% b. We also need to take care if A turns out to be scalar since QR does
% not support integers but divide does.

if isscalar(A)
    % If A is scalar then Q=1 and R=A. b is therefore unmodified.
    R = A;
else
    ws = warning('off','all');
    c = onCleanup( @() warning(ws) );
    [Q,R] = qr(A,0);
    b = Q'*b;
end
end

function x = iSolve(R,b,maxSizeA)
% Solve R*x=b for x with warnings off.
ws = warning('off','all');
c = onCleanup( @() warning(ws) );
[isRSingular, tol] = iIsRSingular(R, maxSizeA);
if isRSingular
    % Use QR with the right tolerance to solve R\b because R is singular.
    % Happens when A is rank-deficient.
    R = decomposition(R, 'qr', 'RankTolerance', tol);
end
x = mldivide(R,b);
end

function [isRSingular, tol] = iIsRSingular(R, maxSizeA)
% Returns true if R is numerically singular. Also returns the tolerance
% that is used, it matches exactly what in-memory would use for A.

% The tolerance formula requires the minimum and maximum absolute values of
% the diagonal entries.
if isvector(R)
    % Diagonal entry of a vector is always the first one.
    minAbsDiagR = abs(R(1, 1));
    maxAbsDiagR = minAbsDiagR;
else
    absDiagR = abs(diag(R));
    minAbsDiagR = min(absDiagR);
    maxAbsDiagR = max(absDiagR);
end

% Use the same tolerance as in-memory would do for A. It is slightly
% different for real and complex.
if isreal(R)
    tol = min(maxSizeA*eps(class(R)), sqrt(eps(class(R)))) * maxAbsDiagR;
else
    tol = min(10*maxSizeA*eps(class(R)), sqrt(eps(class(R)))) * maxAbsDiagR;
end
isRSingular = minAbsDiagR < tol;
end
