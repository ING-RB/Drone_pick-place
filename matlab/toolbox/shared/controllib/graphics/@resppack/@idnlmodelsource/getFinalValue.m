function yf = getFinalValue(this,ModelIndex,~)
%GETFINALVALUE  Computes final value for step, impulse, or initial responses.

%   Copyright 2010 The MathWorks, Inc.

% Default value = Inf (unstable)
Size = getsize(this);
yf = nan(Size([1 2]));
%yf = this.Cache(ModelIndex).DCGain;

%{
% Compute final value
switch RespInfo.Type
   case 'step'
      Stable = isstable(this,ModelIndex);  % Note: will update DC gain value
      if Stable~=0
         % RE: Systems with delay dynamics are handled by this branch
         % (too expensive to compute poles even in discrete time)
         yf = this.Cache(ModelIndex).DCGain;
      end   
end
%}
