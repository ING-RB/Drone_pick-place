function Keyword2OptDep = initOptionalKeywordDependencies()
% This function returns a map that contains MATLAB keywords and their
% optional dependencies.

%   Copyright 2016-2020 The MathWorks, Inc.

    Keyword2OptDep = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    if matlab.internal.parallel.isPCTInstalled() ...
            && matlab.internal.parallel.isPCTLicensed()
        % The real entry points for PARFOR and SPMD are, respectively, 
        % parallel_function.m and spmd_feval.m. However, they are currently
        % owned by component matlab_toolbox_lang, which is shipped with
        % mcr_core. We need a hook in toolbox PCT so that dependencies in
        % PCT can be pulled in. (g1413545)
        % g2454972 - parfeval is moved into MATLAB. Use parpool as the hook now.
        Keyword2OptDep('parfor') = {'parpool'};
        Keyword2OptDep('spmd')   = {'spmdlang.spmd_feval_impl'};
    end
end

% LocalWords:  lang parpool spmdlang impl Distrib
