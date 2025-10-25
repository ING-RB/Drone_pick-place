function sft = sourceFileType(fullPath)
    sft = typeFromNargin(fullPath);
    if sft == ""
        % sometimes nargin errors because it's a previously
        % accessible file. Try one more time.
        sft = typeFromNargin(fullPath);
        if sft == ""
            if endsWith(fullPath, ".m", "IgnoreCase", true)
                sft = typeFromParser(fullPath);
            else
                sft = "Unknown";
            end
        end
    end
end

function sft = typeFromNargin(fullPath)
    try
        nargin(fullPath);
        sft = "Function";
    catch e
        if e.identifier == "MATLAB:nargin:isScript"
            sft = "Script";
        else
            sft = "";
        end
    end
end

function sft = typeFromParser(fullPath)
    fileType = internal.matlab.codetools.reports.matlabType.findType(char(fullPath));
    switch (fileType)
    case internal.matlab.codetools.reports.matlabType.Script
        sft = "Script";
    case internal.matlab.codetools.reports.matlabType.Function
        sft = "Function";
    case internal.matlab.codetools.reports.matlabType.Class
        sft = "Class";
    otherwise
        sft = "Unknown";
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.
