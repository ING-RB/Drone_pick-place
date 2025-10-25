function out = isInternetAccessAvailable()
% ISINTERNETACCESSAVAILABLE - Returns true if internet access is available

% Copyright 2022 The MathWorks, Inc.

if ispc
    pingCmd = 'ping  www.mathworks.com -n 4';
else
    pingCmd = 'ping  www.mathworks.com -c 3';
end

[out, ~] = system(pingCmd);
out = ~logical(out);

end

