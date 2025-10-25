function t = getTimeRange(d)
% Get time range in seconds

%  Copyright 2013 The MathWorks, Inc.
u = d.InputData;
t = [Inf -Inf];
for ku = 1:numel(u)
   uku = u(ku);
   ThisRange = [uku.TimeInfo.Start, uku.TimeInfo.End];
   ThisRange = tunitconv(uku.TimeInfo.Units,'seconds')*ThisRange;
   t = [min(t(1),ThisRange(1)), max(t(2), ThisRange(2))];
end

y = d.OutputData;
for ky = 1:numel(y)
   yky = y(ky);
   ThisRange = [yky.TimeInfo.Start, yky.TimeInfo.End];
   ThisRange = tunitconv(yky.TimeInfo.Units,'seconds')*ThisRange;
   t = [min(t(1),ThisRange(1)), max(t(2), ThisRange(2))];
end
