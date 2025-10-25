function S = turningdist(P, Q)
% TURNINGDIST Find the turning distance of two polyshapes
%
% S = TURNINGDIST(pshape1, pshape2) returns a matrix whose elements are
% non-negative turning distances between pairwise polyshapes in the arrays 
% pshape1 and pshape2. The turning distance is a measure of how closely two
% polyshapes match. When two polyshapes match, the corresponding value of S
% is 0. The more two polyshapes differ, the larger the corresponding value
% of S is. pshape1 and pshape2 must have compatible array sizes.
%
% S = TURNINGDIST(pshape) returns a matrix whose elements are the turning 
% distances between polyshapes in a vector pshape. If pshape has length N, 
% then S is NxN.
%
% See also translate, centroid, overlaps, polyshape

% Copyright 2017-2018 The MathWorks, Inc.

if ~isa(P, 'polyshape')
    error(message('MATLAB:polyshape:polyshapeTypeError'));
end
if nargin == 1
    if ~isvector(P)
        error(message('MATLAB:polyshape:vectorPolyshapeError'));
    end
    Q = P';
elseif ~isa(Q, 'polyshape')
    error(message('MATLAB:polyshape:polyshapeTypeError'));
end

[sz, sP, sQ] = findSize(P, Q);

if numel(P) == 0 || numel(Q) == 0
    S = zeros(sz);
    return;
end
if any(numboundaries(P) > 1)
    if isscalar(P)
        error(message('MATLAB:polyshape:firstOneBoundary'));
    else
        error(message('MATLAB:polyshape:firstOneBoundaryArray'));
    end
end
if any(numboundaries(Q) > 1)
    if isscalar(Q)
        error(message('MATLAB:polyshape:secondOneBoundary'));
    else
        error(message('MATLAB:polyshape:secondOneBoundaryArray'));
    end
end
P2 = repmat(P, sP);
Q2 = repmat(Q, sQ);
S = zeros(sz);
for i=1:numel(P2)
    pshape1 = P2(i);
    pshape2 = Q2(i);
    if ~isEmptyShape(pshape1) && ~isEmptyShape(pshape2)
        R = compare(pshape1.Underlying, pshape2.Underlying);
        S(i) = R(1);
    elseif xor(isEmptyShape(pshape1), isEmptyShape(pshape2))
        S(i) = Inf;
    end
    % Else both are empty shapes so zero is correct.
end
