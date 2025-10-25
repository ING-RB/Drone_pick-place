classdef CoberturaFormatter < matlab.unittest.internal.coverage.CoverageFormatter
    % Class is undocumented and may change in a future release.

    %  Copyright 2017-2023 The MathWorks, Inc.

    methods
        function publishCoverageReport(formatter, fileName, coverageInfo, sourceFolders)
            % Create a new DOM element.
            document =  matlab.io.xml.dom.Document('coverage');

            % Run through the children of the coverage instance. Pass the
            % doc for them to create new nodes.
            coverageInfo.formatCoverageData(formatter,document, sourceFolders);

            % Write the DOM to an XML.
            matlab.unittest.internal.writeXML(fileName,document);
        end

        function coverageElement = formatOverallCoverageData(formatter,overallCoverageInfo,document, sourceFolders)
            % Get the coverage element with the attributes
            coverageElement = document.getDocumentElement;
            formatter.addAttributesToCoverageElement(coverageElement,overallCoverageInfo);

            % Create the sources element with the individual source
            % elements
            sourcesElement = createSourcesElement(document,sourceFolders);

            % Add a packages element and run through the coverageList of
            % the overallCoverage class to add individual package elements
            % to the packages element.
            packagesElement = document.createElement('packages');
            for coverageInfo = overallCoverageInfo.SourceCoverageInfoList
                packageElement = coverageInfo.formatCoverageData(formatter,document,sourceFolders);
                packagesElement.appendChild(packageElement);
            end

            % Add sources and packages elements to the coverage element
            coverageElement.appendChild(sourcesElement);
            coverageElement.appendChild(packagesElement);
        end

        function packageElement = formatNamespaceCoverageData(formatter,namespaceCoverageInfo,document,sourceFolders)
            % Create a new package element with the right attributes
            packageElement = formatter.createPackageElement(document,namespaceCoverageInfo);

            % Create classes element for the package. Run through all the
            % files (classes) that are in the package and append them
            % under the classes element
            classesElement = document.createElement('classes');
            for coverageInfo = namespaceCoverageInfo.SourceCoverageInfoList
                classElement = coverageInfo.formatCoverageData(formatter,document,sourceFolders);
                classesElement.appendChild(classElement);
            end

            % Append the classes element as a child to the package element
            packageElement.appendChild(classesElement);
        end

        function classElement = formatFileCoverageData(formatter,fileCoverageInfo,document,sourceFolders)
            % Create a class element for each file.
            classElement = formatter.createClassElement(document,fileCoverageInfo,sourceFolders);

            % Add a methods element and run through each method in the
            % class and append them under it.
            methodsElement = document.createElement('methods');
            for methodCoverage = fileCoverageInfo.MethodCoverageInfoList
                methodElement = formatter.createMethodElement(document,methodCoverage);
                methodsElement.appendChild(methodElement);
            end

            % Create lines element and add class lines under it.
            linesElement = formatter.createLinesElement(document,fileCoverageInfo);

            % Append the methods and lines element under the class element.

            classElement.appendChild(methodsElement);

            classElement.appendChild(linesElement);
        end

    end
    methods (Access = protected)
        function linesElement = createLinesElement(formatter,document,coverageInfo)
            linesElement = document.createElement('lines');
            lineMetrics = formatter.getLineCoverageData(coverageInfo);
            branchMetrics = formatter.getBranchCoverageData(coverageInfo);
            exelines = lineMetrics.ExecutableLines;
            hitcount = lineMetrics.HitCount;
            N = numel(exelines);
            linesWithBranches = getFirstLinesForDecisionStatements(branchMetrics);

            strnum = num2str([exelines hitcount]);
            strnum = strsplit(string(strnum)," ");
            number = strnum(1:N);
            hits = strnum(N+1:end);

            prototypicalElement = document.createElement('line');
            prototypicalElement.setAttribute('hits','0');
            

            for idx = 1:N
                lineElement = prototypicalElement.cloneNode(false);
                lineElement.setAttribute('number',number(idx));
                if hitcount(idx) > 0
                    % Update only if necessary
                    lineElement.setAttribute('hits',hits(idx));
                end

                if ~isempty(branchMetrics) % include branch related attributes on lines only when branch metrics are available
                    containsBranchMask = ismember(linesWithBranches,exelines(idx));
                    if any(containsBranchMask) 
                        lineElement.setAttribute('branch','true');
                        conditionsElement = document.createElement('conditions');
                        conditionsElement = createConditionElementsForBranchLine(conditionsElement,document,containsBranchMask,branchMetrics);
                        lineElement.appendChild(conditionsElement);
                    else
                        lineElement.setAttribute('branch','false');
                    end
                end
                linesElement.appendChild(lineElement);
            end
        end
        function methodElement = createMethodElement(formatter,document,methodCoverageInfo)
            methodElement = document.createElement('method');
            methodElement.setAttribute('branch-rate',num2str(formatter.getBranchRate(methodCoverageInfo)));
            methodElement.setAttribute('line-rate',num2str(formatter.getLineRate(methodCoverageInfo)));
            methodElement.setAttribute('name',methodCoverageInfo.Name);
            methodElement.setAttribute('signature',methodCoverageInfo.Signature);

            linesElement = formatter.createLinesElement(document,methodCoverageInfo);
            methodElement.appendChild(linesElement);
        end

        % Get Line coverage data
        function lineMetrics = getLineCoverageData(~,coverageInfo)
            lineMetrics = coverageInfo.getCoverageData('matlab.unittest.internal.coverage.metrics.LineMetric');
        end

        function executableLineCount = getExecutableLineCount(formatter,coverageInfo)
            lineMetrics = formatter.getLineCoverageData(coverageInfo);
            if isempty(lineMetrics)
                executableLineCount = NaN;
            else
                executableLineCount = sum([lineMetrics.ExecutableLineCount]);
            end
        end

        function executedLineCount = getExecutedLineCount(formatter,coverageInfo)
            lineMetrics = formatter.getLineCoverageData(coverageInfo);
            if isempty(lineMetrics)
                executedLineCount = NaN;
            else
                executedLineCount = sum([lineMetrics.ExecutedLineCount]);
            end
        end

        function rate = getLineRate(formatter, coverageInfo)
            lineMetrics = formatter.getLineCoverageData(coverageInfo);
            if isempty(lineMetrics)
                rate = NaN;
            else
                rate = sum([lineMetrics.ExecutedLineCount])/sum([lineMetrics.ExecutableLineCount]);
            end
        end

        % Get Branch coverage data
        function metrics = getBranchCoverageData(~,coverageInfo)
            metrics = coverageInfo.getCoverageData('matlab.unittest.internal.coverage.metrics.DecisionMetric');
        end

        function executableBranchCount = getExecutableBranchCount(formatter,coverageInfo)
            branchMetrics = formatter.getBranchCoverageData(coverageInfo);
            if isempty(branchMetrics)
                executableBranchCount = NaN;
            else
                executableBranchCount = sum([branchMetrics.ExecutableDecisionOutcomeCount]);
            end
        end

        function executedBranchCount = getExecutedBranchCount(formatter,coverageInfo)
            branchMetrics = formatter.getBranchCoverageData(coverageInfo);
            if isempty(branchMetrics)
                executedBranchCount = NaN;
            else
                executedBranchCount = sum([branchMetrics.ExecutedDecisionOutcomeCount]);
            end
        end

        function rate = getBranchRate(formatter, coverageInfo)
            branchMetrics = formatter.getBranchCoverageData(coverageInfo);
            if isempty(branchMetrics)
                rate = NaN;
            else
                rate = sum([branchMetrics.ExecutedDecisionOutcomeCount])/sum([branchMetrics.ExecutableDecisionOutcomeCount]);
            end
        end
    end

    methods(Access = private)
        function addAttributesToCoverageElement(formatter,coverageElement,overallCoverageInfo)
            coverageElement.setAttribute('branch-rate',num2str(formatter.getBranchRate(overallCoverageInfo)));
            coverageElement.setAttribute('branches-covered',num2str(formatter.getExecutedBranchCount(overallCoverageInfo)));
            coverageElement.setAttribute('branches-valid',num2str(formatter.getExecutableBranchCount(overallCoverageInfo)));
            coverageElement.setAttribute('complexity',num2str(overallCoverageInfo.Complexity));
            coverageElement.setAttribute('version',"");
            coverageElement.setAttribute('line-rate',num2str(formatter.getLineRate(overallCoverageInfo)));
            coverageElement.setAttribute('lines-valid',num2str(formatter.getExecutableLineCount(overallCoverageInfo)));
            coverageElement.setAttribute('lines-covered',num2str(formatter.getExecutedLineCount(overallCoverageInfo)));
            coverageElement.setAttribute('timestamp',num2str(posixtime(datetime('now'))));
        end

        function packageElement = createPackageElement(formatter,document,namespaceCoverageInfo)
            packageElement = document.createElement('package');
            packageElement.setAttribute('branch-rate',num2str(formatter.getBranchRate(namespaceCoverageInfo)));
            packageElement.setAttribute('complexity',num2str(namespaceCoverageInfo.Complexity));
            packageElement.setAttribute('line-rate',num2str(formatter.getLineRate(namespaceCoverageInfo)));
            packageElement.setAttribute('name',namespaceCoverageInfo.Namespace);
        end

        function classElement = createClassElement(formatter,document,fileCoverageInfo,sourceFolders)
            mask = arrayfun(@(x)startsWith(fileCoverageInfo.FullName,x),sourceFolders);
            sourceFolder = sourceFolders(mask);
            relativeFileName = regexprep(fileCoverageInfo.FullName,"^" + regexptranslate('escape',sourceFolder),'');

            classElement = document.createElement('class');
            classElement.setAttribute('branch-rate',num2str(formatter.getBranchRate(fileCoverageInfo)));
            classElement.setAttribute('complexity',num2str(fileCoverageInfo.Complexity));
            classElement.setAttribute('name',fileCoverageInfo.FileIdentifier);
            classElement.setAttribute('filename',relativeFileName);
            classElement.setAttribute('line-rate',num2str(formatter.getLineRate(fileCoverageInfo)));
        end
    end
end

function sourcesElement = createSourcesElement(document,sourceFolders)
sourcesElement = document.createElement('sources');
for idx = 1:numel(sourceFolders)
    sourceElement = document.createElement('source');
    textNode = document.createTextNode(sourceFolders(idx));
    sourceElement.appendChild(textNode);
    sourcesElement.appendChild(sourceElement);
end
end

function linesSet = getFirstLinesForDecisionStatements(decisionMetric)
linesSet = [];
if ~isempty(decisionMetric)
    linesSet = cellfun(@(x)x(1,1),decisionMetric.SourcePositionData);
    linesSet = double(linesSet');
end
end

function conditionsElement = createConditionElementsForBranchLine(conditionsElement,document,branchIdxMask,branchMetrics)
% create one condition element for each of the two outcomes for a branch
% statement
trueOutcomeCoverage = "0%";
if (branchMetrics.TrueCount(branchIdxMask))
    trueOutcomeCoverage = "100%";
end
falseOutcomeCoverage = "0%";
if (branchMetrics.FalseCount(branchIdxMask))
    falseOutcomeCoverage = "100%";
end

conditionElementTrue = createConditionElement(document,1,trueOutcomeCoverage);
conditionsElement.appendChild(conditionElementTrue);

conditionElementFalse = createConditionElement(document,2,falseOutcomeCoverage);
conditionsElement.appendChild(conditionElementFalse);
end

function conditionElement = createConditionElement(document, conditionNumber,coverage)
conditionElement = document.createElement('condition');
conditionElement.setAttribute('number',num2str(conditionNumber));
conditionElement.setAttribute('type',"jump");
conditionElement.setAttribute('coverage',coverage);
end

% LocalWords:  DOM dom exelines hitcount strnum posixtime
