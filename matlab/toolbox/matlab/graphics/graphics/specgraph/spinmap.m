function spinmap(time,inc)
%

%   Copyright 1984-2023 The MathWorks, Inc.

warning(message('MATLAB:graphics:DeprecatedNoReplacement','spinmap'))

if nargin < 1
    time = 3;
end

if nargin < 2
    time = convertStringsToChars(time);
    inc = 2;
end

cm = colormap;
M = cm;

% Generate the rotated index vector; allow for negative inc.
m = size(M,1);
k = rem((m:2*m-1)+inc,m) + 1;

% Use while loop because time might be inf.
t = clock;
while etime(clock, t) < time
   M = M(k,:);
   colormap(M)
   drawnow('expose');
end

colormap(cm)
