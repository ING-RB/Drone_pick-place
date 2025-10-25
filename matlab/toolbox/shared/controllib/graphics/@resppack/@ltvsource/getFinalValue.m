function [yfinal,yinit] = getFinalValue(this,~,r)
% Computes initial and final value for step, impulse, or initial responses.
% For STEP and IMPULSE, the initial value yinit is the output value just
% before the step change or impulse is applied (t=t0+Delay-). For INITIAL, 
% yinit is always zero.

%   Copyright 2022-2023 The MathWorks, Inc.
sys = this.Model;
[ny,nu] = size(sys);
t = r.Data.Time;
p = r.Context.Parameter;
Config = r.Context.Config;

% Compute initial value YINIT
switch r.Context.Type
   case {'step','impulse'}
      if Config.Delay>0
         % When step/impulse is delayed, use last Y value prior to change
         % Note: step/impulse change at sample nDelay+1
         nDelay = round(Config.Delay/(t(2)-t(1)));
         yinit = reshape(r.Data.Amplitude(nDelay,:),[ny nu]);
      else
         % Figure out Y value before step or impulse kicks in at T(1)
         tk0 = ltvpack.tk(t(1),sys.Ts);
         if isLPV(sys)
            if isnumeric(p)
               pinit = p(1,:).';
            else
               pinit = Config.InitialParameter;
            end
            [~,~,C,D,~,~,x0,u0,y0] = sys.DataFunction(tk0,pinit);
         else
            pinit = [];
            [~,~,C,D,~,~,x0,u0,y0] = sys.DataFunction(tk0);
         end
         nx = size(C,2);
         [ny,nu] = size(sys);
         % Resolve 'x0' and 'u0'
         xinit = Config.InitialState;
         if ischar(xinit)
            if isempty(x0)
               xinit = zeros(nx,1);
            else
               xinit = x0;
            end
         end
         uinit = Config.InputOffset;
         if ischar(uinit)
            if isempty(u0)
               uinit = zeros(nu,1);
            else
               uinit = u0;
            end
         end
         % Compute YINIT
         if isempty(xinit)
            % Compute steady-state operating condition
            [op,SINGULAR] = findop(sys,tk0,pinit,u=uinit);
            if SINGULAR
               yinit = NaN(ny,1);
            else
               yinit = op.y;
            end
         else
            if ~isempty(x0)
               xinit = xinit-x0;
            end
            if ~isempty(u0)
               uinit = uinit-u0;
            end
            yinit = C*xinit+D*uinit;
            if ~isempty(y0)
               yinit = yinit+y0;
            end
         end
      end
      % Set YF to last sample value
      yfinal = reshape(r.Data.Amplitude(end,:),[ny nu]);

   case 'initial'
      yinit = zeros(ny,1);
      yfinal = reshape(r.Data.Amplitude(end,:),[ny 1]);
end

