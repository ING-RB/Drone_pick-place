function out = usingWebFigures
%

%   Copyright 2020 The MathWorks, Inc.

persistent b;

if isempty(b)
    s = settings;
    try
        b = s.matlab.ui.internal.figuretype.webfigures.ActiveValue || feature('webui');
    catch ME
        b = false;
    end
end

out = b;
