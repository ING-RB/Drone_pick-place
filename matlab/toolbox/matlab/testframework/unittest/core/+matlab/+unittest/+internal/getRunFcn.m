function runFcn = getRunFcn(options, plugins, suite, artifactsRootFolder)
%

%   Copyright 2022-2024 The MathWorks, Inc.

import matlab.unittest.internal.diagnostics.WrappableStringDecorator

% Run serially by default
runFcn = @run;

if ~options.UseParallel || ~matlab.unittest.internal.isPCTInstalled
    return;
end

% Check that pool is compatible with the plugins and suite before running
% canRunInParallel which might open a pool.

pluginDiagnostic = matlab.unittest.internal.ParallelTestRunStrategy.getBasicParallelPluginDiagnostic(plugins);
if strlength(pluginDiagnostic) > 0
    options.OutputStream.printFormatted(WrappableStringDecorator(pluginDiagnostic + newline));
    return;
end

pool = gcp("nocreate");
strategy = matlab.unittest.internal.getTestRunStrategyFor(pool, artifactsRootFolder);
suiteDiagnostic = strategy.getCompleteSuiteAndPluginParallelSupportDiagnostic(plugins, suite);
if strlength(suiteDiagnostic) > 0
    options.OutputStream.printFormatted(WrappableStringDecorator(suiteDiagnostic + newline));
    return;
end

if canRunInParallel
    runFcn = @runInParallel;
end
end

function tf = canRunInParallel()
import matlab.internal.parallel.canUseParallelPool;
if ~canUseParallelPool()
    tf = false;
    return;
end

% The parallel utility returning true guarantees:
% * PCT is installed
% * PCT is licensed
% * Pool is running
% We still need to check the case if the license can't be checked out
licenseName = 'Distrib_Computing_Toolbox';
[canCheckout, ~] = license('checkout', licenseName);
tf = canCheckout;
end

% LocalWords:  Wrappable strlength gcp nocreate Distrib
