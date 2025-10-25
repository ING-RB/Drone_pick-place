function archive = useArchiveDoc
    useReleaseVar = getenv('MW_HELP_USE_RELEASE_URL');
    if ~isempty(useReleaseVar)
        % Follow the environment variable whenever it is present. 
        % Accept either "true" or "1".
        archive = strcmpi(useReleaseVar,"true") || useReleaseVar == "1"; 
    else
        archive = ~matlab.internal.web.isMatlabOnlineEnv;
    end
end

% Copyright 2020 The MathWorks, Inc.
