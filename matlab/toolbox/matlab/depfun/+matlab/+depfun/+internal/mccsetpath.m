function tf = mccsetpath(varargin)
% Set mcc path for mcc compiler which used to be done in the requirement.m.
% This function will be called at the beginning of mcc compilation in both
% mex-mcc and non mex-mcc c++ code to set the path and then called in the
% end of mcc compilation in mex-mcc to restore the matlab path.

%   Copyright 2018-2023 The MathWorks, Inc.

persistent savedpath
persistent orgState

if strcmp(varargin{1}, 'HasPathBeenScoped')
    tf = ~isempty(savedpath);
    return
end

if varargin{1}
    % Restore the matlab path and the warning state.
    if ~isempty(savedpath)
        path(savedpath);
        savedpath = {};        
    end
    
    if ~isempty(orgState)
        warning(orgState);
        orgState = [];
    end
else
    if isempty(savedpath)
        savedpath = path;
        
        % Set MATLAB's path to the SearchPath's PathString
        s = matlab.depfun.internal.SearchPath('MCR', varargin{2:end});
        
        % Suppress warnings related to path
        orgState = warning;
        warning('off', 'MATLAB:mpath:packageDirectoriesNotAllowedOnPath');
        warning('off', 'MATLAB:mpath:privateDirectoriesNotAllowedOnPath');
        warning('off', 'MATLAB:mpath:methodDirectoriesNotAllowedOnPath');
        warning('off', 'MATLAB:mpath:resourcesDirectoriesNotAllowedOnPath');
        warning('off', 'MATLAB:mpath:packagesMustBeLastOnPath');
        if ~ismcc
            % These warnings are disabled in matlabrc.m for non mex-mcc and in c++ code
            % for mex-mcc executable. Move them here from the c++ code for mex-mcc executable.
            warning('off', 'MATLAB:dispatcher:nameConflict');
            warning('off', 'MATLAB:predictorNoBuiltinVisible');
            warning('off', 'MATLAB:Java:classLoad');
        end
        path(s.PathString);
    end
end

% LocalWords:  mpath
