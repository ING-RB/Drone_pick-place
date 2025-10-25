function [x,r] = deconv(y,h,varargin)
% DECONV Least-squares deconvolution and polynomial division.
%
% [X,R] = DECONV(Y,H) deconvolves the vector H from the vector Y using
% long division. The result is returned in vector X and the remainder in
% vector R.
%
% The outputs satisfy Y = conv(X,H) + R when length(H) <= length(Y);
% otherwise, X = 0 and R = Y. With K = min(length(H),length(Y)), these
% two cases can be written as Y = conv(X,H(1:K)) + R.
%
% If H and Y are vectors of polynomial coefficients, deconvolution is
% equivalent to polynomial division. The result of dividing Y by H is
% quotient X and remainder R.
%
% [X,R] = DECONV(Y,H,SHAPE) deconvolves the vector H from the vector Y,
% yielding an output that satisfies Y = CONV(X,H,SHAPE) + R.
% SHAPE specifies the subsection size of the convolution and must be
% one of the following:
%
%     "full" - (default) Y contains the full convolution of X with H.
%     "same" - Y contains only the central part of the convolution that is the
%              same size as X.
%     "valid" - Y contains only those parts of the convolution that are computed
%               without the zero-padded edges, where 
%               LENGTH(Y) is MAX(LENGTH(X)-MAX(0,LENGTH(H)-1),0).
%
% When using the default deconvolution method ("long-division"), then SHAPE
% must be "full".
%
% [X,R] = DECONV(..., Method=ALG) performs the convolution using the
% specified algorithm.  ALG must be one of the following:
%
%     "long-division" - (default) Deconvolution by polynomial long division.
%     "least-squares" - Deconvolution by least squares.
%                       The output X is computed to minimize the norm of the
%                       remainder R.  That is, X is the solution that minimizes
%                       norm(Y-conv(X,H)).
%
% [X,R] = DECONV(..., RegularizationFactor=alpha) applies Tikhonov
% regularization to the least-squares solution of the deconvolution,
% returning a vector X that minimizes norm(R)^2+norm(alpha*X)^2.
% For ill-conditioned deconvolutions, this gives preference to solutions X 
% with smaller norms.  The regularization factor must be 0 if the deconvolution
% method is "long-division".
%
% See also CONV, RESIDUE, POLYDIV

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin < 3
    if nargout > 1
        [x,r] = polydiv(y,h);
    else
        x = polydiv(y, h);
    end
else
    if nargout > 1
        [x,r] = deconvolve(y, h, varargin{:});
    else
        x = deconvolve(y, h, varargin{:});
    end
end

end

function [x,r] = deconvolve(y, h, shape, NameValueArgs)
arguments
    y { mustBeVector, mustBeNumeric }
    h { mustBeVector, mustBeNumeric }
    shape(1,1) string = "full"
    NameValueArgs.Method = "long-division"
    NameValueArgs.RegularizationFactor(1,1) { mustBeNumeric, mustBeFinite } = 0
end

% Validate the shape.
allShapes = ["full" "same" "valid"];
shapeMatch = matlab.internal.math.partialMatchString(shape, allShapes, 1);
if ~any(shapeMatch)
    error(message('MATLAB:conv2:unknownShapeParameter'));
end

% Validate the method.
allMethods = ["long-division" "least-squares"];
methodMatch = matlab.internal.math.partialMatchString(NameValueArgs.Method, allMethods, 2);
if ~methodMatch
    error(message('MATLAB:deconv:badMethod'));
end

if methodMatch(1)
    if ~shapeMatch(1)
        error(message('MATLAB:deconv:polydivShape'));
    end
    if NameValueArgs.RegularizationFactor ~= 0
        error(message('MATLAB:deconv:polydivRegularizer'));
    end
    if nargout > 1
        [x,r] = polydiv(y,h);
    else
        x = polydiv(y, h);
    end
else
    x = matlab.internal.math.lsq.deconv(y, h, shape, NameValueArgs.RegularizationFactor);
    if anynan(x) && allfinite(y) && allfinite(h)
        % Fast QR failed, fall back to linear system solve.
        n = numel(x);
        I = eye(n);
        T = conv2(I, h(:), shape);
        if NameValueArgs.RegularizationFactor == 0
            x = lsqminnorm(T, y(:));
        else
            [U,s,V] = svd(T, 'econ', 'vector');
            s = s ./ (s.^2 + NameValueArgs.RegularizationFactor^2);
            x = V*(s.*(U'*y(:)));
        end
    end
    shape = allShapes(shapeMatch);
    % Compute the residual if we need it.
    if nargout > 1
        if x == 0
            r = cast(y, superiorfloat(y, x));
        else
            r = y(:) - conv(x(:),h(:),shape);
        end
    end
    % Reshape x to match the expected output shape.
    if isrow(y)
        x = reshape(x, 1, []);
        if nargout > 1
            r = reshape(r, 1, []);
        end
    else
        x = x(:);
    end
end
end
