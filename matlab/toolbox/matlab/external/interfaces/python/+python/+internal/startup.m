function startup
%   FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%   and is intended for use only within the scope of functions and classes
%   in the MATLAB external interface to Python. Its behavior may change, 
%   or the function itself may be removed in a future release.

% Copyright 2017-2020 The MathWorks, Inc.

% STARTUP executes commands when Python starts.

% Redirect stdout to the MATLAB Command Window.
python.internal.redirectstdout;

% Import the buffer module.
try
    folder = fullfile(matlabroot,'bin',computer('arch'));
    p = py.sys.path;

    % Call addsitedir on site-packages folder to trigger .pth files
    size = p.length;
    for i = 1:size
        pstr = string(p{i});
        if pstr.endsWith("site-packages")
            py.site.addsitedir(pstr);
        end
    end

    % Add the bin/<arch> folder to the Python search path
    p.insert(int32(0), folder);
    raii = onCleanup(@()p.remove(folder));
    [~] = py.importlib.import_module('libmwbuffer');
catch
    % Failed to import buffer module. mat2py and py2mat functions won't work.
end

end
