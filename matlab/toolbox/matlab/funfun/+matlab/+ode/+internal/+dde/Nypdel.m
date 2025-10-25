function ypdel = Nypdel(t,y,ydel1,ydeld, ...
    ydel,ypIdx,ypdIdx,IVP,IVP_T0,IVP_YP0,ypdel,DELTA,MINCHANGE,varargin)
    % ddensd helper to pproximate yp(del) with (y(del)-y(del-d))/d
    D = matlab.ode.internal.dde.Ndelays(t,y, ...
        ydel,ypdel,IVP,IVP_T0,DELTA,MINCHANGE,varargin{:});
    del = D(ypIdx);
    deld = D(ypdIdx);
    d = del - deld;
    ypdel = (ydel1 - ydeld)*diag(1./d);
    if IVP
        % If perturbed argument is less than IVP_T0, use
        % IVP_YP0 instead of difference quotient for derivative.
        ndx = (deld <= IVP_T0);
        ypdel(:,ndx) = repmat(IVP_YP0,1,nnz(ndx));
    end
end
%   Copyright 2024 The MathWorks, Inc.