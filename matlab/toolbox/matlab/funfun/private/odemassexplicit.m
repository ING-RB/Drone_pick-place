function [odeFcn,odeArgs] = odemassexplicit( FcnHandlesUsed,massType,odeFcn,...
                                             odeArgs,massFcn,massM)  
%ODEMASSEXPLICIT  Helper function for handling the mass matrix
%   For explicit ODE solvers -- incorporate the mass matrix into the ODE
%   function.   
%
%   See also ODE113, ODE23, ODE45.

%   Jacek Kierzenka
%   Copyright 1984-2021 The MathWorks, Inc.

if FcnHandlesUsed
    switch massType
      case 1  % use LU factors of constant M 
        if issparse(massM) 
            [massL,massU,massP,massQ,massR] = lu(massM);
            odeArgs = [{odeFcn,massL,massU,massP,massQ,massR},odeArgs];    
            odeFcn = @ExplicitSolverHandleMass1sparse;       
        else % M full
            [massL,massU,massp] = lu(massM,'vector');
            odeArgs = [{odeFcn,massL,massU,massp},odeArgs];    
            odeFcn = @ExplicitSolverHandleMass1;
        end  
      case 2
        odeArgs = [{odeFcn,massFcn},odeArgs];    
        odeFcn = @ExplicitSolverHandleMass2;
      otherwise % case {3,4}
        odeArgs = [{odeFcn,massFcn},odeArgs];    
        odeFcn = @ExplicitSolverHandleMass34;
    end
else % ode-file:  F(t,y,'mass',p1,p2...)    
    if massType == 1   % use LU factors of constant M 
        if issparse(massM) 
            [massL,massU,massP,massQ,massR] = lu(massM);
            odeArgs = [{odeFcn,massL,massU,massP,massQ,massR},odeArgs];    
            odeFcn = @ExplicitSolverHandleMass1sparse;       
        else % M full
            [massL,massU,massp] = lu(massM,'vector');
            odeArgs = [{odeFcn,massL,massU,massp},odeArgs];    
            odeFcn = @ExplicitSolverHandleMass1;
        end  
    else  
        odeArgs = [{odeFcn},odeArgs];  
        odeFcn = @ExplicitSolverHandleMassOld;   
    end
end

% --------------------------------------------------------------------------

function yp = ExplicitSolverHandleMass1(t,y,odeFcn,L,U,p,varargin)
  ode = odeFcn(t,y,varargin{:});
  yp = U \ (L \ ode(p));

% --------------------------------------------------------------------------

function yp = ExplicitSolverHandleMass1sparse(t,y,odeFcn,L,U,P,Q,R,varargin)
  yp = Q *( U \ (L \ (P * (R \ odeFcn(t,y,varargin{:})))));
 
% --------------------------------------------------------------------------
  
function yp = ExplicitSolverHandleMass2(t,y,odeFcn,massFcn,varargin)
  yp = massFcn(t,varargin{:}) \ odeFcn(t,y,varargin{:});
  
% --------------------------------------------------------------------------  

function yp = ExplicitSolverHandleMass34(t,y,odeFcn,massFcn,varargin)
  yp = massFcn(t,y,varargin{:}) \ odeFcn(t,y,varargin{:});

% --------------------------------------------------------------------------  
  
function yp = ExplicitSolverHandleMassOld(t,y,odeFcn,varargin)
  yp = odeFcn(t,y,'mass',varargin{2:end}) \ ...
       odeFcn(t,y,varargin{:});
  
% --------------------------------------------------------------------------  
