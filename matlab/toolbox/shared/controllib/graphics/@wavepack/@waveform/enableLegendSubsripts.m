function enableLegendSubsripts(this,Flag)
% Flag is true for enabling subscripts
%         false for disabling subscripts

% Copyright 2013 The MathWorks, Inc.

this.LegendSubsriptsEnabled = Flag;
this.updateGroupInfo
end