function [yinterp,ypinterp] = ntrp15s(tinterp,~,~,tnew,ynew,h,dif,k,idxNonNegative)
%NTRP15S  Interpolation helper function for ODE15S.
%   YINTERP = NTRP15S(TINTERP,T,Y,TNEW,YNEW,H,DIF,K,IDX) uses data computed in
%   ODE15S to approximate the solution at time TINTERP. TINTREP may be a
%   scalar or a row vector.   
%   The arguments T and Y do not affect the computations. They are required
%   for consistency of syntax with other interpolation functions. Any values
%   entered for T and Y are ignored.
%    
%   [YINTERP,YPINTERP] = NTRP15S(TINTERP,T,Y,TNEW,YNEW,H,DIF,K,IDX) returns
%   also the derivative of the polynomial approximating the solution. 
%   
%   IDX has indices of solution components that must be non-negative. Negative 
%   YINTERP(IDX) are replaced with zeros and the derivative YPINTERP(IDX) is 
%   set to zero.
%   
%   See also ODE15S, DEVAL.

%   Mark W. Reichelt and Lawrence F. Shampine, 6-13-94
%   Copyright 1984-2022 The MathWorks, Inc.

s = (tinterp - tnew)/h;  % expected to be a row vector

%ynew is expected to be a column vector
ypinterp = [];
if k == 1
    yinterp = ynew + dif(:,1) * s;
    if nargout > 1
        hdif = (1/h)*dif(:,1);
        ypinterp = repmat(hdif, size(tinterp));
    end
else                    % cumprod collapses vectors
    % k >= 2
    kI = (1:k)';
    yinterp = ynew + ...  % ynew + dif(:,1:k) * cumprod((s+kI-1)./kI)
        matlab.internal.math.viewColumns(dif,k) * cumprod((s+kI-1)./kI);
    if nargout > 1
        ypinterp = dif(:,1);
        S  = 1;
        dS = 1;
        for i=2:k
            S = S .* (i-2+s)/i;
            dS = dS .* (i-1+s)/i + S;
            ypinterp = ypinterp + dif(:,i).*dS; % outer product dif(:,i).*dS
        end
        ypinterp = ypinterp/h;
    end
end

% Non-negative solution
if ~isempty(idxNonNegative)
    idx = find(yinterp(idxNonNegative,:)<0); % vectorized
    if ~isempty(idx)
        w = yinterp(idxNonNegative,:);
        w(idx) = 0;
        yinterp(idxNonNegative,:) = w;
        if nargout > 1   % the derivative
            w = ypinterp(idxNonNegative,:);
            w(idx) = 0;
            ypinterp(idxNonNegative,:) = w;
        end
    end
end
