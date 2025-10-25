function [yfinal,yinit] = getFinalValue(this,ModelIndex,r)
% Computes initial and final value for step, impulse, or initial responses.
% For STEP and IMPULSE, the initial value yinit is the output value just
% before the step change or impulse is applied (t=t0+Delay-). For INITIAL, 
% yinit is always zero.

%   Copyright 1986-2022 The MathWorks, Inc.

% Default value = Inf (unstable)
D = getModelData(this,ModelIndex);
[ny,nu] = iosize(D);
RespType = r.Context.Type;
Config = r.Context.Config;

% Compute final value
switch RespType
   case {'step','impulse'}
      if strcmp(RespType,'step')
         Stable = isstable(this,ModelIndex);  % Note: will update DC gain value
      else
         % Stable plus integrator
         [~,Stable] = isstable(this,ModelIndex);
      end
      DC = this.Cache(ModelIndex).DCGain;
      Config = validate(Config,nu);
      if Stable==0
         yinit = zeros(ny,nu);  % wrong but immaterial
         yfinal = Inf(ny,nu);
      else
         % RE: Systems with delay dynamics are handled by this branch
         % (too expensive to compute poles even in discrete time)
         [yfinal,yinit] = getFinalValue(D,RespType,Config,DC);
         if Config.Delay>0
            % When step/impulse is delayed, set YINIT to last Y value prior 
            % to step/impulse change
            t = r.Data.Time;
            % Note: step/impulse change at sample nDelay+1
            nDelay = round(Config.Delay/(t(2)-t(1)));
            yinit = reshape(r.Data.Amplitude(nDelay,:),[ny nu]);
         end
      end

   case 'initial'
      % Protect against unstable systems with no inputs
      yinit = zeros(ny,1);
      [~,StablePlusIntegrator] = isstable(this,ModelIndex);
      if StablePlusIntegrator==0
         yfinal = Inf(ny,1);
      else
         yfinal = getFinalValue(D,'initial',Config);
      end
end
