function getBoundData(src,r)
%  Computes bound data for SIGMA plot bounds

%   Copyright 1986-2013 The MathWorks, Inc.

% sigma from @ltisource
[sv,w,FocusInfo] = sigmaresp(getPrivateData(src.Model),0,[],true);
Data = r.Data;
Data.Frequency = w*funitconv('rad/TimeUnit','rad/s',src.Model.TimeUnit);
Data.SingularValues = sv';
Data.Ts = src.Model.Ts*tunitconv(src.Model.TimeUnit,'seconds');
Data.FreqUnits = 'rad/s';
Data.Focus = FocusInfo.Focus*funitconv('rad/TimeUnit','rad/s',src.Model.TimeUnit);
Data.SoftFocus = FocusInfo.Soft;

f = Data.Frequency;
Focus = src.Focus;
if Focus(1)>f(1) || Focus(2)<f(end)
   % Clip and interpolate to show true edges
   if Focus(1)>f(1)
      f = [Focus(1) ; f(f>Focus(1),:)];
   end
   if Focus(2)<f(end)
      f = [f(f<Focus(2),:) ; Focus(2)];
   end
   % Note: Use log-log interpolation to preserve slope of gain asymptotes
   Data.SingularValues = exp(utInterp1(log(Data.Frequency),log(Data.SingularValues),log(f)));
   Data.Frequency = f;
   % Slide data focus to lie inside frequency band where constraint is active
   DataFocus = Data.Focus;
   if all(isnan(DataFocus))
      DataFocus = [0.1 10];
   end
   fMin = 0.9*max(Focus(1),f(1));
   fMax = 1.1*min(Focus(2),f(end));
   Span = min(DataFocus(2)/DataFocus(1),fMax/fMin);
   if DataFocus(1)<fMin
      DataFocus = [fMin fMin*Span];  % Slide right
   elseif DataFocus(2)>fMax
      DataFocus = [fMax/Span fMax];  % Slide left
   end
   Data.Focus = DataFocus;
end
if ~src.UseFocus
   Data.Focus = [NaN,NaN];
end


