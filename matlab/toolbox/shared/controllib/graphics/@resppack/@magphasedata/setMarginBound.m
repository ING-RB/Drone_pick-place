function setMarginBound(this,GM,PM,Ts,Focus)
% Specify data for gain/phase margin bounds
% GM in abs value, PM in radians, Ts in seconds, Focus in rad/s

%   Copyright 1986-2014 The MathWorks, Inc.
Ts = abs(Ts);
f = [1e-20 ; min([1e20,pi/Ts])];
if Focus(1)>f(1) || Focus(2)<f(2)
   if Focus(1)>f(1)
      f = [Focus(1) ; f(f>Focus(1),:)];
   end
   if Focus(2)<f(2)
      f = [f(f<Focus(2),:) ; Focus(2)];
   end
   fMin = 0.9*max(Focus(1),f(1));
   fMax = 1.1*min(Focus(2),f(2));
   DataFocus = [0.1,10];  % default
   Span = min(100,fMax/fMin);
   if DataFocus(1)<fMin
      DataFocus = [fMin fMin*Span];  % Slide right
   elseif DataFocus(2)>fMax
      DataFocus = [fMax/Span fMax];  % Slide left
   end
else
   DataFocus = zeros(0,2);
end
this.Frequency = f;
this.Magnitude = [GM;GM];
this.Phase = [PM;PM];
this.Ts = Ts;
this.Focus = DataFocus;
this.SoftFocus = true;