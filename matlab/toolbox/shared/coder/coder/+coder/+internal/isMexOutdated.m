function [result, isCodeCov] = isMexOutdated(mexFcnName)
    %

    %   Copyright 2017-2024 The MathWorks, Inc.

    mexFcnFile = which(mexFcnName);

    % mexFcnName can be a symbol on the path OR
    % an absolute path of a function not on the path
    if isempty(mexFcnFile) && isfile(mexFcnName)
        mexFcnFile = mexFcnName;
    end

    isCodeCov = strcmp(getenv('TESTCOVERAGE'), 'PROFILER');

    if exist('coder.internal.Project', 'class') ~= 8
        if ~isCodeCov
            warning(message('EMLRT:runTime:ProfilingNoCoder'));
        end
        result = true;
        return
    end

    project = coder.internal.Project;
    props = project.getMexFcnProperties(mexFcnFile);

    if isempty(props) || ~isfield(props, 'ResolvedFunctions') ...
            || ~isfield(props, 'EntryPoints')
        result = true;
        return
    end

    ep = props.EntryPoints;

    % Check all entry point time stamp is ok
    for i = 1:numel(ep)
        D = dir(ep(i).ResolvedFilePath);
        % file does not exist or timestamps do not match.
        if isempty(D) || ~isequal(D.datenum, ep(i).TimeStamp)
            result = true;
            return
        end
    end

    % Verify non-entrypoint resolved functions. Entry points are verified
    % above. Unfortunately codegen's EML path could be different to the MEX
    % runtime resulting in different resolution.
    resolvedFunctions = props.ResolvedFunctions;
    entryPointIdx = arrayfun(@(x) isempty(x.context) && endsWith(x.resolved, [".m" ".p" ".mlx"], IgnoreCase=true), resolvedFunctions);
    nonEntryPointResolvedFunctions = resolvedFunctions(~entryPointIdx);
    outOfDateIdx = project.verifyResolvedFunction(nonEntryPointResolvedFunctions);

    % Don't complain about toolbox functions.
    for idx = 1:numel(outOfDateIdx)
        if ~isToolboxFcn(nonEntryPointResolvedFunctions(idx).resolved)
            result = true;
            return
        end
    end
    result = false;

end

function ret = isToolboxFcn(path)
    exp = {'matlab[\\/]toolbox'};
    if ismac
        exp{end+1} = 'MATLAB_R\d{4}[ab].app/toolbox';
    end
    match = regexp(path, exp, 'once');
    ret = any(cellfun(@any, match));
end
