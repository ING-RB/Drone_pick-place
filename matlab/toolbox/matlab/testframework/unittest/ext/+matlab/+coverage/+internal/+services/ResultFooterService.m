%

%   Copyright 2023-2024 The MathWorks, Inc.
classdef ResultFooterService < matlab.coverage.internal.ResultFooterService

    methods
        function footerStr = getFooter(~, resObj, variableName)
            footerStr = getFooterStr(resObj, variableName);
        end
    end

end

%% ------------------------------------------------------------------------
function footerStr = getFooterStr(resObj, variableName)

if isempty(resObj)
    footerStr = '';
    return
end

% The API expects vector but can be lenient for the display then convert to
% column vector
resObj = resObj(:);

% Extract the list of available metrics and the best metric computed out of
% the provided coverage results
[bestMetricLevel, allValidMetricNames] = matlab.coverage.internal.getBestMetricLevel(resObj);

% perform a validation with a license check
[licenseStatus,~] = license('checkout','MATLAB_TEST');

if licenseStatus
    metricLevel = bestMetricLevel;
    validMetricNames = string(allValidMetricNames);
else
    metricLevel = 'statement';
    validMetricNames = string(metricLevel);
end

validMetricNames = ["function", validMetricNames];
idxMetricLevel = find(validMetricNames==metricLevel, 1);

% Display the overall coverage for each valid metric
footerStr = '';
txtBuffer = '';
sep = '';

% Catch and ignore any error to let display still working
try
    for ii = 1 : idxMetricLevel
        % Extract and sum the coverage for this metric
        [cov, numJustif] = coverageSummaryInternal(resObj, validMetricNames(ii), 'OutputNumJustifiedInsteadOfDetail', true);
        cov = sum(cov, 1);
        numJustif = sum(numJustif);

        % Discard unavailable metric
        if isempty(cov) || (isscalar(cov) && cov==0) 
            continue
        end

        % Generate the display for this metric
        metricName = getMetricDisplayLabel(validMetricNames(ii));

        % Display summary data for metrics (as displayed in the
        % HTML report)
        if cov(2)==0
            str = getString(message('MATLAB:coverage:result:DispNoCoverageElementsToShowCoverageSummary'));
            txtBuffer = sprintf('%s%s   %s: %s', txtBuffer, sep, ...
                metricName, str);
        else
            % Compute and truncate the coverage percentage
            pct = floor((cov(1) / cov(2)) * 100 * 100) / 100;
            pctStr = num2str(pct);
            if numJustif==0
                txtBuffer = sprintf('%s%s   %s: %d/%d (%s%%)', txtBuffer, sep, ...
                    metricName, cov(1), cov(2), pctStr);
            else
                txtBuffer = sprintf('%s%s   %s: (%d+%d)/%d (%s%%)', txtBuffer, sep, ...
                    metricName, cov(1)-numJustif, numJustif, cov(2), pctStr);
            end
        end
        sep = newline;
    end
catch Me
    % An error occurred then just don't display the coverage summary
    % section
    txtBuffer = '';
end

% Generate the coverage summary section (if no error)
if strlength(txtBuffer) > 0
    footerStr = [getString(message('MATLAB:coverage:result:DispCovSummary')),...
        generateCovSummarySection(resObj, variableName), ...
        newline, txtBuffer, newline];
end

if ~licenseStatus
    truncatedSummaryStr= [newline, getString(message('MATLAB:coverage:result:TruncatedMetricSummaryWithoutMATLABTestLicense'))];
    footerStr = [footerStr, truncatedSummaryStr , newline,generateCovMethodSection(), newline];
else
    footerStr = [footerStr,newline,generateCovMethodSection(), newline];
end
end

%% ------------------------------------------------------------------------
function text = generateCovSummarySection(resObj, variableName)

if matlab.automation.internal.richFormattingSupported
    % Early return if hyperlinking is not possible (because the variable is
    % not in the base workspace but the caller workspace)
    if isempty(resObj) || isempty(variableName) || ...
            ~evalin('base', sprintf('exist(''%s'', ''var'')', variableName)) || ...
            ~evalin('base', sprintf('isa(%s, ''matlab.coverage.Result'')', variableName))
        text = ':';
        return
    end

    key = matlab.coverage.internal.computeResultDigest(resObj);

    text = [sprintf('<a href="matlab:matlab.coverage.internal.generateHTMLReport(''%s'', ''%s'');">%s</a>', ...
        variableName, key, message('MATLAB:coverage:result:DispGenHTMLReport'))];
else
    text = getString(message('MATLAB:coverage:result:DispGenHTMLMethod'));
end
text = [' (', text, '):'];

end

%% ------------------------------------------------------------------------
function text = generateCovMethodSection()

if matlab.automation.internal.richFormattingSupported
    arg = '<a href="matlab:helpPopup matlab.coverage.Result/coverageSummary">coverageSummary</a>';
else
    arg = 'coverageSummary';
end

text = getString(message('MATLAB:coverage:result:DispCovSummaryMethod', arg));

end

%% ------------------------------------------------------------------------
function label = getMetricDisplayLabel(metricName)

persistent metricLabels;

if ~isfield(metricLabels, metricName)
    switch metricName
        case "function"
            msgCatalog = matlab.internal.Catalog('MATLAB:unittest:CoverageReport');
            label = string(msgCatalog.getString('FunctionCoverage'));
        case "statement"
            msgCatalog = matlab.internal.Catalog('MATLAB:unittest:CoverageReport');
            label = string(msgCatalog.getString('StatementCoverage'));
        case "decision"
            out = getMessageCatalogEntriesForMetrics(matlab.unittest.internal.coverage.metrics.DecisionMetricHandler, struct());
            label = out.DecisionCoverage;
        case "condition"
            out = getMessageCatalogEntriesForMetrics(matlab.unittest.internal.coverage.metrics.ConditionMetricHandler, struct());
            label = out.ConditionCoverage;
        case "mcdc"
            out = getMessageCatalogEntriesForMetrics(matlab.unittest.internal.coverage.metrics.MCDCMetricHandler, struct());
            label = out.MCDCCoverage;
        otherwise
            % Should never happen, just for later when adding a new metric
            assert(false);
    end
    metricLabels.(metricName) = label;
end

label = metricLabels.(metricName);

end

% LocalWords:  mcdc
