function [singularBVP,ode,jac,solinit,PBC] = ...
    bvpsingular(solver_name,solinit,odefun,jacfun,options,neqn,nparam,nregions)
%BVPSINGULAR  Helper function for dealing with singular BVP.
%  
%   See also BVP4C, BVP5C, BVPSET.

%   Copyright 2007-2022 The MathWorks, Inc.

% Handle multipoint BVP
if nargin < 8
    nregions = 1;
end

singularBVP = false;
ode = odefun;
jac = jacfun;
PBC = [];

ST = bvpget(options,'SingularTerm',[]);
if ~isempty(ST)
    if (solinit.x(1) ~= 0) || (solinit.x(end) <= solinit.x(1))
        error(message('MATLAB:bvpsingular:SingBVPInvalidInterval'))
    end
    if ~isnumeric(ST) || any( size(ST)~=neqn)
        error(message('MATLAB:bvpsingular:SingBVPInvalidS'))
    end

    singularBVP = true;
    % Compute matrix for imposing necessary BC, Sy(0) = 0,
    % and impose on guess for solution.
    PBC = eye(size(ST)) - pinv(ST)*ST;
    solinit.y(:,1) = PBC*solinit.y(:,1);

    if nparam == 0 || solver_name == "bvp4c"
        S = ST;
    else
        % pad with zeros for additional equations
        S = zeros(neqn+nparam);
        S(1:neqn,1:neqn) = ST;
    end
    PImS = pinv(eye(size(S)) - S);
    vectorized = bvpget(options,'Vectorized','off') == "on";
    switch solver_name
    case 'bvp5c'
        if nregions == 1
            if vectorized
                ode = @(x,y)odeSingular_vectorized(x,y,odefun,PImS,S);
            else
                ode = @(x,y)odeSingular(x,y,odefun,PImS,S);
            end
        else
            % ode(x,y,k)
            if vectorized
                ode = @(x,y,varargin)odeSingular_varargin_vectorized(x,y,odefun,PImS,S,varargin{:});
            else
                ode = @(x,y,varargin)odeSingular_varargin(x,y,odefun,PImS,S,varargin{:});
            end
        end
        if ~isempty(jac)
            if nregions == 1
                % dF = jac(x,y)
                jac = @(x,y)jacSingular(x,y,jacfun,PImS,S);
            else
                % dF = jac(x,y,k)
                jac = @(x,y,k)jacSingular_in3(x,y,k,jacfun,PImS,S,neqn);
            end
        end

    case 'bvp4c'
        if (nparam == 0) && (nregions == 1)
            % ode(x,y)
            if vectorized
                ode = @(x,y)odeSingular_vectorized(x,y,odefun,PImS,S);
            else
                ode = @(x,y)odeSingular(x,y,odefun,PImS,S);
            end
        else
            % ode(x,y,k), ode(x,y,p), ode(x,y,k,p)
            if vectorized
                ode = @(x,y,varargin)odeSingular_varargin_vectorized(x,y,odefun,PImS,S,varargin{:});
            else
                ode = @(x,y,varargin)odeSingular_varargin(x,y,odefun,PImS,S,varargin{:});
            end
        end
        if ~isempty(jac)
            if nparam == 0
                if nregions == 1
                    % dF = jac(x,y)
                    jac = @(x,y)jacSingular(x,y,jacfun,PImS,S);
                else
                    % dF = jac(x,y,k)
                    jac = @(x,y,k)jacSingular_in3(x,y,k,jacfun,PImS,S,neqn);
                end
            else
                if nregions == 1
                    % [dF,dp] = jac(x,y,p)
                    jac = @(x,y,p)jacSingular_in3_out2(x,y,p,jacfun,PImS,S);
                else
                    % [dF,dp] = jac(x,y,k,p)
                    jac = @(x,y,k,p)jacSingular_in4_out2(x,y,k,p,jacfun,PImS,S,neqn,nparam);
                end
            end
        end
    end  % switch solver_name
end

end  % bvpsingular

% ------------------------------
% Local functions
% ------------------------------
function f = odeSingular(x,y,odefun,PImS,S)
% Incorporate singular term - scalar case
f = odefun(x,y);
if x == 0  % singular point
    f = PImS*f;
else       % regular point
    f = f + S*y/x;
end
end  % odeSingular

% ------------------------------
function f = odeSingular_vectorized(x,y,odefun,PImS,S)
% Incorporate singular term - vectorized case
f = odefun(x,y);
% singular point
idx = find(x == 0);
if ~isempty(idx)
    f(:,idx) = PImS*f(:,idx);
end
% regular points
idx = find(x ~= 0);
if ~isempty(idx)
    f(:,idx) = f(:,idx) + (S*y(:,idx)) * ...
        spdiags(1./x(idx)',0,length(idx),length(idx));
end
end  % odeSingular_vectorized

% ------------------------------
function f = odeSingular_varargin(x,y,odefun,PImS,S,varargin)
% Incorporate singular term - scalar case
f = odefun(x,y,varargin{:});
if x == 0  % singular point
    f = PImS*f;
else       % regular point
    f = f + S*y/x;
end
end  % odeSingular_varargin

% ------------------------------
function f = odeSingular_varargin_vectorized(x,y,odefun,PImS,S,varargin)
% Incorporate singular term - vectorized case
f = odefun(x,y,varargin{:});
% singular point
idx = find(x == 0);
if ~isempty(idx)
    f(:,idx) = PImS*f(:,idx);
end
% regular points
idx = find(x ~= 0);
if ~isempty(idx)
    f(:,idx) = f(:,idx) + (S*y(:,idx)) * ...
        spdiags(1./x(idx)',0,length(idx),length(idx));
end
end  % odeSingular_varargin_vectorized

% ------------------------------
function dFdy = jacSingular(x,y,jacfun,PImS,S)
% Incorporate singular term into the Jacobian
if isnumeric(jacfun)
    dFdy = jacfun;
else
    dFdy = jacfun(x,y);
end
if x == 0  % singular point
    dFdy = PImS*dFdy;
else       % regular point
    dFdy = dFdy + S/x;
end
end  % jacSingular

% ------------------------------
function dFdy = jacSingular_in3(x,y,k,jacfun,PImS,S,neqn)
% Incorporate singular term into the Jacobian
if isnumeric(jacfun)
    cols = neqn*(k-1)+1 : neqn*k;
    dFdy = jacfun(:,cols);
else
    dFdy = jacfun(x,y,k);
end
if x == 0  % singular point
    dFdy = PImS*dFdy;
else       % regular point
    dFdy = dFdy + S/x;
end
end  % jacSingular_in3

% ------------------------------
function [dFdy,dFdp] = jacSingular_in3_out2(x,y,p,jacfun,PImS,S)
% Incorporate singular term into the Jacobian
if iscell(jacfun)
    dFdy = jacfun{1};
    dFdp = jacfun{2};
else
    [dFdy,dFdp] = jacfun(x,y,p);
end
if x == 0  % singular point
    dFdy = PImS*dFdy;
    dFdp = PImS*dFdp;
else       % regular point
    dFdy = dFdy + S/x;
end
end  % jacSingular_in3_out2

% ------------------------------
function [dFdy,dFdp] = jacSingular_in4_out2(x,y,k,p,jacfun,PImS,S,neqn,nparam)
% Incorporate singular term into the Jacobian
if iscell(jacfun)
    cols_y = neqn*(k-1)+1   : neqn*k;
    cols_p = nparam*(k-1)+1 : nparam*k;
    dFdy = jacfun{1}(:,cols_y);
    dFdp = jacfun{2}(:,cols_p);
else
    [dFdy,dFdp] = jacfun(x,y,k,p);
end
if x == 0  % singular point
    dFdy = PImS*dFdy;
    dFdp = PImS*dFdp;
else       % regular point
    dFdy = dFdy + S/x;
end
end  % jacSingular_in4_out2

