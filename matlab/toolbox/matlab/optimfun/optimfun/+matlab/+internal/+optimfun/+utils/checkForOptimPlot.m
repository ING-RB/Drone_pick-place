function options = checkForOptimPlot(options)
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2024 The MathWorks, Inc.

    % Quick return if no plot fcns
    if ~isfield(options, "PlotFcns") || isempty(options.PlotFcns)
        options.HasOptimPlot = false;
        return
    end

    % Check for use of the optimplot fcn
    options.PlotFcns = matlab.internal.optimfun.utils.createCellArrayOfFunctions(options.PlotFcns,'PlotFcns');
    plotNames = string(cellfun(@func2str, options.PlotFcns, "UniformOutput", false));
    idx = strcmp(plotNames, "optimplot");
    options.HasOptimPlot = any(idx);

    % Remove optimplot from plotfcns cell array
    options.PlotFcns(idx) = [];
end