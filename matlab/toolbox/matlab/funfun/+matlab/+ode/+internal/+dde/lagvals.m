function [Z,implicit_step] = lagvals(tnow,ynow,delays,history,X,Y,YP,varargin)
% For each I, Z(:,I) is the solution corresponding to to the value of
% the Ith delay function evaluated at (TNOW, YNOW). This solution can
% be computed in several ways: the initial history, interpolation of
% the computed solution, extrapolation of the computed solution,
% interpolation of the computed solution plus the tentative solution
% at the end of the current step.  The various ways are set in the
% calling program when X,Y,YP are formed.

%   Copyright 2024 The MathWorks, Inc.

if isempty(ynow)
    % dde23 code
    xint = real(tnow - delays);
    if isempty(delays)
        Z = [];
        return
    end
elseif isnumeric(delays)
    xint = real(tnow - delays);
    xint = min(tnow,xint);
else % function handle
    xint = real(delays(tnow,ynow,varargin{:}));
    xint = min(tnow,xint);
end

% Check whether any argument is determined implicitly in the current step.
if nargout > 1
    if isscalar(X)
        implicit_step = false;
    else
        implicit_step = any(xint > X(end-1));
    end
end

% setup if extending solution so that interpolation can be done on previous
% solution's history. This case comes up only when the history is a
% previous solution, the x to interpolate is before the current solver's
% t0, and xint lies in the range covered by the previous solve.
if isstruct(history) && any(xint < X(1)) && any(xint >= history.x(1))
    % append history
    X = [history.x X];
    Y = [history.y Y];
    YP = [history.yp YP];
end

% NOTE that the delays may not be ordered and that it is necessary to
% preserve their order in Z.
Nxint = numel(xint);
% Find n for which X(n) <= xint(j) <= X(n+1).  xint(j) bigger
% than X(end) are evaluated by extrapolation, so n = end-1 then.
if isscalar(X)
    inds = ones(numel(xint),1);
else
    inds = matlab.internal.math.discretize(xint,X,false);
    % returns nan for values outside range, which indicates we should set
    % n = end-1 to extrapolate
    if anynan(inds)
        tf = isnan(inds);
        inds(tf) = numel(X)-1;
    end
end
if isstruct(history)
    given_history = history.history;
    tstart = history.x(1);
end
neq = numel(Y(:,1));
Z = zeros(neq,Nxint,"like",Y);

for j = 1:Nxint
    if xint(j) < X(1)
        if isnumeric(history)
            temp = history;
        elseif isstruct(history)
            % Is xint(j) in the given history?
            if xint(j) < tstart
                if isnumeric(given_history)
                    temp = given_history;
                else % function handle
                    temp = given_history(xint(j),varargin{:});
                end
            end
        else % function handle
            temp = history(xint(j),varargin{:});
        end
        Z(:,j) = temp(:);
    elseif xint(j) == X(1)   % Special case for initialization.
        Z(:,j) = Y(:,1);
    elseif xint(j) == X(end) % Special case for initialization with extension.
        Z(:,j) = Y(:,end);
    else
        n = inds(j);
        h = X(n+1) - X(n);
        s = (xint(j) - X(n))./h;
        s2 = s .* s;
        s3 = s .* s2;
        y = Y(:,n);
        ynew = Y(:,n+1);
        yp = YP(:,n);
        ypnew = YP(:,n+1);
        slope = (ynew - y)./h; % y must be a column vector
        c = 3*slope - 2*yp - ypnew; % yp must be a column vector
        d = yp + ypnew - 2*slope;
        Z(:,j) = y + (h*d*s3 + h*c*s2 + h*yp*s);
    end
end
end