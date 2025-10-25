function text = generateTimeString(numSeconds)
% Generate a nice to read string representation of the given number of
% seconds.

%   Copyright 2016-2018 The MathWorks, Inc.

if numSeconds > 10
   numSeconds = round(numSeconds);
else
   % Show at least 1 decimal place, or as many as required to see a value
   numSeconds = round(numSeconds, 2, 'significant');
end

[h, m, s] = hms(seconds(numSeconds));
if numSeconds >= 3600
    text = getString(message('MATLAB:bigdata:executor:ElapsedTimeHM', h, m));
elseif numSeconds >= 60
    text = getString(message('MATLAB:bigdata:executor:ElapsedTimeMS', m, s));
else
    text = getString(message('MATLAB:bigdata:executor:ElapsedTimeS', string(s)));
end
end
