function parsedResults = setupInterfaceName(parsedResults)
% Setup interface name

%   Copyright 2024 The MathWorks, Inc.

% Set InterfaceName when only PackageName option
if parsedResults.InterfaceName == "" && isfield(parsedResults,"PackageName") 
    if ~isempty(parsedResults.PackageName) 
        parsedResults.InterfaceName = parsedResults.PackageName;
    end
end

% Infer name of package if PackageName is '' and only one header is provided.
if parsedResults.InterfaceName == ""
    if isscalar(parsedResults.HeaderFiles)
        [~,filename,~] = fileparts(parsedResults.HeaderFiles{1});
        if isvarname(filename)
            parsedResults.InterfaceName = filename;
        else
            error(message('MATLAB:CPP:InferredInvalidPackageName', filename));
        end
    end
end

end
