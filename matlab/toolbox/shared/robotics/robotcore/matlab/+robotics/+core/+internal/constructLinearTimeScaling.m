function scaling = constructLinearTimeScaling(timeInterval, time)
%This function is for internal use only. It may be removed in the future.

%CONSTRUCTLINEARTIMESCALING Construct default time scaling, s(t) = (t - t0)/(tF - t0)

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Ensure that time is a row
m = length(time);
t = reshape(time, 1, m);

% Use interval to compute position values
linearScaling = 1 / (timeInterval(2) - timeInterval(1));
s = linearScaling*(t - timeInterval(1));
sd = linearScaling*ones(1,m);
sdd = zeros(1,m);

% Saturate position and velocity outside the time interval
s(t < timeInterval(1)) = 0;
s(t > timeInterval(2)) = 1;
sd(t < timeInterval(1)) = 0;
sd(t > timeInterval(2)) = 0;

% Build output
scaling = [s; sd; sdd];

end
