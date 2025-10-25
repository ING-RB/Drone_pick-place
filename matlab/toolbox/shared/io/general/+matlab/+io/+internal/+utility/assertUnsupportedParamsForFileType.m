function assertUnsupportedParamsForFileType(params,supplied,fileType)
% utility to check for unsupported parameters

% Copyright 2019 MathWorks, inc.
    for p = string(params(:))'
        if isfield(supplied,p) && supplied.(p)
            error(message('MATLAB:textio:detectImportOptions:ParamWrongFileType',p,fileType))
        end
    end
end
