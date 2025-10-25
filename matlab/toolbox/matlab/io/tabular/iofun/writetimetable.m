function writetimetable(TT,filename,varargin)

import matlab.io.internal.interface.suggestWriteFunctionCorrection
import matlab.io.internal.interface.validators.validateWriteFunctionArgumentOrder

if nargin < 2
    timetablename = inputname(1);
    if isempty(timetablename)
        timetablename = "timetable";
    end
    filename = timetablename + ".txt";
else
    for i = 1:2:numel(varargin)
        n = strlength(varargin{i});
        % Write should match to WriteVariableNames
        if n > 5 && strncmpi(varargin{i},"WriteRowNames",n)
            error(message("MATLAB:table:write:WriteRowNamesNotSupported","WRITETIMETABLE"));
        end
    end
end

validateWriteFunctionArgumentOrder(TT, filename, "writetimetable", "timetable", @istimetable);

if ~istimetable(TT)
    suggestWriteFunctionCorrection(TT, "writetimetable");
end

try
    T = timetable2table(TT);
    writetable(T,filename,varargin{:});
catch ME
    throw(ME)
end

end

% Copyright 2012-2024 The MathWorks, Inc.
