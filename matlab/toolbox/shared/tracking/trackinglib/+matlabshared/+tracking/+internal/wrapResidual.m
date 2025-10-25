function residual = wrapResidual(residual, bounds, objName)
% This is an internal function and may be modified or removed in a future
% release.
    
%wrapResidual  Wrap a residual
% RESIDUAL = matlabshared.tracking.internal.wrapResidual(RESIDUAL, BOUNDS, OBJNAME)
% wraps the RESIDUAL to the measurement BOUNDS. 
% RESIDUAL is an M-by-N matrix of measurement residuals (z-z_expected),
% where each measurement is a column vector.
% BOUNDS is an M-by-2 matrix, where the first column is the minimum
% measurement bound and the second column is the maximum bound. For
% example, for a measurement vector [az;el;range], where az is bound
% between -180 and 180, el is unbounded and range wraps between 0 and 100,
% use [-180 180; -Inf Inf; 0 100];
% OBJNAME is the name of the calling object.
%
% The wrapping is based on [1].

% [1] David Frederic Crouse, “Cubature / Unscented / Sigma Point Kalman
% Filtering with Angular Measurement Models”, pp. 1550-1557, Proceedings of
% the 18th International Conference on Information Fusion, Washington, DC,
% July 2015.

% Copyright 2021 The MathWorks, Inc.
%#codegen
isf = all(isfinite(bounds),2);
if ~any(isf,1)
    return
end

if coder.target('MATLAB')
    nrows = size(residual,1);
else
    nrows = coder.internal.indexInt(size(residual,1));
end

validateattributes(residual,{'numeric'},{'real'},objName,'value',1);
validateattributes(bounds,{'numeric'},{'real','ncols',2,'nrows',nrows},objName,'bounds',2);

% Make sure that finite bounds are symmetric w.r.t. zero
bounds(isf,:) = bounds(isf,:) - (bounds(isf,2)+bounds(isf,1))/2;

% For numerical stability, limit wrapping to bounds within 3 OOM of the residual
ma = max(abs(residual),[],2);
toWrap = isf & (abs(ma./bounds(:,2))>(1e-3)*ones(1,1,'like',residual));
resToWrap = residual(toWrap,:);

% Wrap the residual and assign back
resToWrap = mod((resToWrap - bounds(toWrap,1)), bounds(toWrap,2)-bounds(toWrap,1))+bounds(toWrap,1);
residual(toWrap,:) = resToWrap;
end