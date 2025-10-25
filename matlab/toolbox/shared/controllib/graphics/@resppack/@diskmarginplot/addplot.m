function r = addplot(this,w,gm,pm,Ts,Focus,REAL)
% Add data plot.
% GM is in abs units and PM in rad.

%  Copyright 2020 The MathWorks, Inc.
r = addresponse(this,1,1,1);
r.Data.Frequency = w;
r.Data.Magnitude = gm;
r.Data.Phase = pm;
r.Data.Ts = Ts;
r.Data.Focus = Focus;
r.Data.Real = REAL;