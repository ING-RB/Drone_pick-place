function dydt = Ndde(t,y,Z, ...
    ydel,yIdx,ypIdx,ypdIdx,ddefun,IVP,IVP_T0,IVP_YP0,ypdel,DELTA,MINCHANGE,varargin)
    % ddensd helper to evaluate the DE
    Zp = Z(:,ypIdx);
    Zpd = Z(:,ypdIdx);
    Z = Z(:,yIdx);
    ZP = matlab.ode.internal.dde.Nypdel(t,y,Zp,Zpd, ...
    ydel,ypIdx,ypdIdx,IVP,IVP_T0,IVP_YP0,ypdel,DELTA,MINCHANGE,varargin{:});  % approx delayed derivative
    dydt = ddefun(t,y,Z,ZP,varargin{:});
end 
%   Copyright 2024 The MathWorks, Inc.