classdef CoverageReportDataPublisher
    %

    %  Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant, Access=private)
        TemplateRoot = getFolderContainingTemplate;
        CoverageDataFilename =  "OverallCoverageData";
        MessageCatalogStringsFilename = "messageCatalogEntries";
        SourceDataFilenamePrefix =  "sourceData";
        AppliedFilterDataFilename = "appliedFilters"
        FileExtension = ".js";
        Subfoldername = "coverageData"
        ReleaseFolder = "release"
    end
    
    methods (Static)
        function files = listPublishedFiles()
            import matlab.unittest.internal.coverage.CoverageReportDataPublisher

            templateRootFolder = CoverageReportDataPublisher.TemplateRoot;
            templateReleaseFolderContents = dir(fullfile(templateRootFolder, CoverageReportDataPublisher.ReleaseFolder, "**", "*"));
            templateFiles = fullfile(string({templateReleaseFolderContents.folder}), string({templateReleaseFolderContents.name}));
            templateFiles = templateFiles(isfile(templateFiles));
            templateFiles = strrep(templateFiles, fullfile(templateRootFolder, filesep), "");

            covDataFiles = [CoverageReportDataPublisher.CoverageDataFilename CoverageReportDataPublisher.MessageCatalogStringsFilename CoverageReportDataPublisher.SourceDataFilenamePrefix+"*" CoverageReportDataPublisher.AppliedFilterDataFilename] + CoverageReportDataPublisher.FileExtension;
            covDataFiles = fullfile(CoverageReportDataPublisher.ReleaseFolder, CoverageReportDataPublisher.Subfoldername, covDataFiles);

            files = [templateFiles covDataFiles];
        end
    end

    methods
        function publishCoverageReportData(publisher, fileCoverageArray, reportFolder, mainFileName, metricHandler, documentTitleStr, handshakeCommunicationChannelName, publisherChannelName, reportID, appliedFiltersDataStructArray)
            
            % Create the target folder to write the coverage data
            publisher.createReportFoldersAndCopyHTMLTemplate(reportFolder,mainFileName);
            covDataFormatters = arrayfun(@(x) x.getFormatter,metricHandler,'UniformOutput',false);

            % write data needed to populate the landing page of
            % the report
            publisher.exportStringsFromMessageCatalog(reportFolder, metricHandler, handshakeCommunicationChannelName,publisherChannelName, reportID);
            publisher.exportCoverageMetrics(fileCoverageArray,reportFolder, covDataFormatters, documentTitleStr);
            
            % create a sourceData file for each source with file contents,
            % executed line numbers, missed line numbers and hit counts
            publisher.exportCoverageMarkupDataForFiles(fileCoverageArray,reportFolder, covDataFormatters);

            % create a filterData file for the applied filters data
            publisher.exportFilterDataForAppliedFiltersPerSource(appliedFiltersDataStructArray, reportFolder)
        end
        
        function exportStringsFromMessageCatalog(publisher,reportFolder, metricHandler, handshakeCommunicationChannelName, publisherChannelName, reportID)
            catalogStringsStruct = getStringsFromMessageCatalog(metricHandler);
            catalogStringsStruct.HandshakeChannelName = handshakeCommunicationChannelName;    % Channel used for communicating from Report to MATLAB
            catalogStringsStruct.ReceiverChannelName = publisherChannelName;                  % Channel used for communicating from MATLAB to Report
            catalogStringsStruct.ReportID = reportID;  % UUID used for fetching data from the CoverageReportDataManager and communicating with the right Report
            
            % Encode it and write to file
            jsonString = jsonencode(catalogStringsStruct);
            stringToWrite = "var messageCatalogEntries = " + jsonString;
            dataFilename = fullfile(reportFolder,publisher.ReleaseFolder,publisher.Subfoldername,...
                publisher.MessageCatalogStringsFilename + publisher.FileExtension);
            writeToFile(dataFilename,stringToWrite);
        end
        
        function exportCoverageMetrics(publisher,fileCoverageInfoArray,reportFolder, covDataFormatters, documentTitleStr) 
            import matlab.unittest.internal.getSingleLargestRootFromSourceFolders            

            % get the current value of MATLAB theme and use the same for the report.
            s = settings();
            if s.matlab.appearance.CurrentTheme.hasActiveValue
                matlabThemeValue = s.matlab.appearance.CurrentTheme.ActiveValue;
            else
                matlabThemeValue = 'Light';
            end

            %  get a common root from all sourceFolders and their relative
            %  paths
            fullSourceFilenames = string({fileCoverageInfoArray.FullName});
            commonRootFolder = getSingleLargestRootFromSourceFolders(arrayfun(@fileparts,fullSourceFilenames));
            relativeSourceFilenamesCell = arrayfun(@(filename)regexprep(filename,strcat('^',regexptranslate('escape',commonRootFolder)),''),...
                fullSourceFilenames, 'UniformOutput',false);
            relativeSourceFilenamesArray = [relativeSourceFilenamesCell{:}];

            fileCoverageStructPerMetric = struct;
            overallCoverageDataPerMetric = struct;
            collectedMetrics = strings(1,numel(covDataFormatters));
            
            % Collect coverage data for individual files as well as the
            % overall source.
           for formatterIdx = 1: numel(covDataFormatters)
                formatter = covDataFormatters{formatterIdx};
                fieldNameForMetric = formatter.OutputStructFieldName;
                collectedMetrics(formatterIdx) = fieldNameForMetric;
                if isempty(fileCoverageInfoArray)
                    coverageSummaryData = struct('Total',0,...
                        'Executed',0,...
                        'Missed',0,...
                        'PercentCoverage',nan);
                    coverageDataBySource = struct('ExecutableArray',0,...
                        'ExecutedArray',0);
                else
                    coverageSummaryData = formatter.formatSummaryData(fileCoverageInfoArray);
                    coverageDataBySource = formatter.formatBreakdownBySourceData(fileCoverageInfoArray);
                end
                overallCoverageDataPerMetric.(fieldNameForMetric) = coverageSummaryData;                
                fileCoverageStructPerMetric.(fieldNameForMetric) = coverageDataBySource;
            end
           
            % Store the coverage data into a struct format before encoding
            % it in JSON format
            fileCoverageStructArray = struct('FileNameArray',relativeSourceFilenamesArray,...
                'CoverageMetrics',fileCoverageStructPerMetric);
            
            overallCoverageDataStruct = struct('TotalFiles',numel(fileCoverageInfoArray),...
                'BreakDownBySourceData',fileCoverageStructArray,...
                'OverallCoverageMetrics',overallCoverageDataPerMetric,...
                'EnabledMetrics',collectedMetrics,...
                'CommonRootFolder',commonRootFolder, ...
                'MATLABTheme',matlabThemeValue, ...
                'DocumentTitle',documentTitleStr);
            
            % Encode it and write to file
            jsonString = jsonencode(overallCoverageDataStruct);
            stringToWrite = "var overallCoverageData = " + jsonString;
            dataFilename = fullfile(reportFolder,publisher.ReleaseFolder,publisher.Subfoldername,...
                publisher.CoverageDataFilename + publisher.FileExtension);
            writeToFile(dataFilename,stringToWrite);
        end
        
        function exportCoverageMarkupDataForFiles(publisher,fileCoverageInfoArray,reportFolder, covDataFormatters)            
            for idx =1:numel(fileCoverageInfoArray)               
                % read data from the source file. Verify the file exists
                % and is not a .p file before reading it
                [~,~,ext] = fileparts(fileCoverageInfoArray(idx).FullName);
                coverageMetricsStruct = struct;
                hasRawFileContent = ~isempty(fileCoverageInfoArray(idx).RawFileContent);
                if (isfile(fileCoverageInfoArray(idx).FullName) || hasRawFileContent) && ~strcmp(ext,'.p')
                    if hasRawFileContent
                        rawFileContent = fileCoverageInfoArray(idx).RawFileContent;
                    else
                        rawFileContent = matlab.internal.getCode(fileCoverageInfoArray(idx).FullName);
                    end
                    fileLinesString = string(strsplit(rawFileContent,'\n','CollapseDelimiters',false));                    
                   
                    for formatterIdx = 1: numel(covDataFormatters)
                        formatter = covDataFormatters{formatterIdx};
                        fieldNameForMetric = formatter.OutputStructFieldName;
                        coverageMetricsStruct.(fieldNameForMetric) = formatter.formatSourceDetailsData(fileCoverageInfoArray(idx));
                    end                   
                else
                    fileLinesString = string(getString(message('MATLAB:unittest:CoverageReport:UnableToDisplayCoverageMarkupForSource',...
                        fileCoverageInfoArray(idx).FullName)));
                    for formatterIdx = 1: numel(covDataFormatters)
                        formatter = covDataFormatters{formatterIdx};
                        fieldNameForMetric = formatter.OutputStructFieldName;
                        coverageMetricsStruct.(fieldNameForMetric) = struct.empty;
                    end
                end

                % Build a separate filtering data field for the
                % coverageMetricsStruct that is independent of the metrics
                allMetricNames = cellfun(@(x)x.OutputStructFieldName,covDataFormatters);
                metricNamesWithFilterData = ["Function","Statement","Decision"];
                if all(ismember(metricNamesWithFilterData,allMetricNames)) % filter data populated if we have decision coverage.
                    filterDataStructArrayForFile = publisher.createFilterDataStructArray(metricNamesWithFilterData,coverageMetricsStruct);
                else
                    filterDataStructArrayForFile = struct.empty;
                end
                % Store the coverage data per line into a file coverage
                % data struct 
                fileCoverageDataStruct = struct('FileName',fileCoverageInfoArray(idx).FullName,'RawFileContents',fileLinesString,...
                    'CoverageDisplayDataPerLine',coverageMetricsStruct,'FilterData',filterDataStructArrayForFile);
                
                % Encode it to JSON format and write to file
                jsonString = jsonencode(fileCoverageDataStruct);
                stringToWrite = "var sourceData" + (idx-1)+ " = " + jsonString;
                dataFilename =  fullfile(reportFolder,publisher.ReleaseFolder,publisher.Subfoldername,...
                    publisher.SourceDataFilenamePrefix + (idx-1) + publisher.FileExtension);
                writeToFile(dataFilename,stringToWrite);
            end
        end

        function filterDataStructArrayForFile = createFilterDataStructArray(~,metricNamesWithFilterData, coverageMetricsStruct)
            filterDataStructArrayForMetric = cell(1,numel(metricNamesWithFilterData));
            for metricNameIdx = 1:numel(metricNamesWithFilterData)
                coverageDataForMetric = coverageMetricsStruct.(metricNamesWithFilterData(metricNameIdx));
                filterableDataForLine = coverageDataForMetric(arrayfun(@(x)any(x.Filterable),coverageDataForMetric)); % account for multiple statements on a line
                filterDataStructForMetricArray = cell(1,numel(filterableDataForLine));
                for dataIdx = 1:numel(filterableDataForLine)
                    filterDataStruct.LineNumber = filterableDataForLine(dataIdx).LineNumber;
                    filterDataStruct.CoverageElementType = metricNamesWithFilterData(metricNameIdx);
                    filterDataStructOnLineArray = repmat(filterDataStruct,1,nnz(filterableDataForLine(dataIdx).Filterable));  % Create a filterData struct for each Filterable statement on the line.
                    startColNumbersCell = num2cell((filterableDataForLine(dataIdx).StartColumnNumbers(filterableDataForLine(dataIdx).Filterable)));
                    endColNumbersCell = num2cell((filterableDataForLine(dataIdx).EndColumnNumbers(filterableDataForLine(dataIdx).Filterable)));
                    uuidCell = num2cell((filterableDataForLine(dataIdx).FilterDataUUID(filterableDataForLine(dataIdx).Filterable)));
                    [filterDataStructOnLineArray.StartColumnNumber] = startColNumbersCell{:};
                    [filterDataStructOnLineArray.EndColumnNumber] = endColNumbersCell{:};
                    [filterDataStructOnLineArray.FilterUUID] = uuidCell{:};
                    filterDataStructForMetricArray{dataIdx} = filterDataStructOnLineArray;
                end
                filterDataStructArrayForMetric{metricNameIdx} = [filterDataStructForMetricArray{:}];
            end
            filterDataStructArrayForFile = [filterDataStructArrayForMetric{:}];
        end

        function exportFilterDataForAppliedFilters(publisher, appliedFiltersDataStructArray, reportFolder)

            appliedFilterDataStructArrayCell = cell(1,numel(appliedFiltersDataStructArray));
            for filterIdx = 1:numel(appliedFiltersDataStructArray)
                currentAppliedFilter = appliedFiltersDataStructArray(filterIdx);

                appliedFilterDataStruct = struct("SourceFilename",currentAppliedFilter.SourceFilename,...
                    "OutcomeFiltered",currentAppliedFilter.OutcomeFiltered,...
                    "FilterUUID",currentAppliedFilter.FilterUUID,...
                    "StatementType",currentAppliedFilter.StatementType,...
                    "FilterReason",currentAppliedFilter.FilterReason,...
                    "InternalFilterID",currentAppliedFilter.InternalFilterID,...
                    "FilteredFunctionOutcomesCount",0,...   % Need to get this from the propagation data.
                    "FilteredStatementOutcomesCount",currentAppliedFilter.filteredCoverageResults.FilteredStatementsCount,...
                    "FilteredStatementSourcePositions",currentAppliedFilter.filteredCoverageResults.FilteredStatementsSourcePositions,...
                    "FilteredDecisionOutcomesCount",currentAppliedFilter.filteredCoverageResults.FilteredDecisionStatementsCount_False + currentAppliedFilter.filteredCoverageResults.FilteredDecisionStatementsCount_True,...
                    "FilteredDecisionOutcomesSourcePositions_True",currentAppliedFilter.filteredCoverageResults.FilteredDecisionStatementsSourcePositions_True,...
                    "FilteredDecisionOutcomesSourcePositions_False",currentAppliedFilter.filteredCoverageResults.FilteredDecisionStatementsSourcePositions_False,...
                    "FilteredConditionOutcomesCount",currentAppliedFilter.filteredCoverageResults.FilteredConditionStatementsCount_True + currentAppliedFilter.filteredCoverageResults.FilteredConditionStatementsCount_False,...
                    "FilteredConditionOutcomesSourcePositions_False",currentAppliedFilter.filteredCoverageResults.FilteredConditionStatementsSourcePositions_False,...
                    "FilteredConditionOutcomesSourcePositions_True",currentAppliedFilter.filteredCoverageResults.FilteredConditionStatementsSourcePositions_True,...
                    "FilteredMCDCOutcomesCount",currentAppliedFilter.filteredCoverageResults.FilteredMCDCCount,...
                    "FilteredMCDCDecisionStatementSourcesPositions",currentAppliedFilter.filteredCoverageResults.FilteredMCDCDecisionStatementsSourcePositions,...
                    "FilteredMCDCConditionStatementsSourcePositions",currentAppliedFilter.filteredCoverageResults.FilteredMCDCConditionStatementsSourcePositions,...
                    "StatementText","",...    % leaving this blank for now, we might not need it.
                    "ReportID",currentAppliedFilter.ReportID);
                appliedFilterDataStructArrayCell{filterIdx} = appliedFilterDataStruct;
            end
            appliedFilterDataStructArray = [struct.empty appliedFilterDataStructArrayCell{:}];

            % Encode it to JSON format and write to file
            jsonString = jsonencode(appliedFilterDataStructArray);
            stringToWrite = "var appliedFilterDataArray" + " = " + jsonString;
            dataFilename =  fullfile(reportFolder,publisher.ReleaseFolder,publisher.Subfoldername,...
                publisher.AppliedFilterDataFilename + publisher.FileExtension);
            writeToFile(dataFilename,stringToWrite);
        end

        function exportFilterDataForAppliedFiltersPerSource(publisher, appliedFiltersPerSourceDataStructArray, reportFolder)
            appliedFilterDataStructArray = [struct.empty appliedFiltersPerSourceDataStructArray];

            % Encode it to JSON format and write to file
            jsonString = jsonencode(appliedFilterDataStructArray);
            stringToWrite = "var appliedFilterDataArray" + " = " + jsonString;
            dataFilename =  fullfile(reportFolder,publisher.ReleaseFolder,publisher.Subfoldername,...
                publisher.AppliedFilterDataFilename + publisher.FileExtension);
            writeToFile(dataFilename,stringToWrite);
        end
    end
    
    methods(Access = private)
        function createReportFoldersAndCopyHTMLTemplate(publisher, reportFolder,mainFileName)            
            publisher.createReportFolderAndSubfolder(reportFolder);   

            % create the main file and copy contents from the template html
            % file
            templateFileContent = fileread(fullfile(publisher.TemplateRoot,'index.html'));
            [fid, msg] = fopen(fullfile(reportFolder,mainFileName), 'w');
            assert(fid > 0, 'MATLAB:unittest:CoverageReport:OpenFailed', msg);
            cl = onCleanup(@() fclose(fid));
            fprintf(fid, '%s', templateFileContent);            
            
            % copy supporting files
            [copySuccess,msg,msgId] = copyfile(fullfile(publisher.TemplateRoot,publisher.ReleaseFolder,'*'),fullfile(reportFolder,publisher.ReleaseFolder),'f');
            assert(copySuccess,msgId,'%s',msg);
        end
        
        function createReportFolderAndSubfolder(publisher,reportFolder)            
            % First create the main report folder
            folderLocation = reportFolder;
            [status,msg,msgId] = mkdir(folderLocation);
            assert(status,msgId,'%s',msg);
            
            % create the coverageData subfolder to store data files
            folderLocation = fullfile(reportFolder,publisher.ReleaseFolder, publisher.Subfoldername);
            [status,msg,msgId] = mkdir(folderLocation);
            assert(status,msgId,'%s',msg);
        end
    end
end
function templateRoot = getFolderContainingTemplate
templateRoot = fullfile(matlabroot,'toolbox','matlab','testframework','unittest','codecov');
end
function stringsStruct = getStringsFromMessageCatalog(metricHandlers)
basicCoverageCatalog = matlab.internal.Catalog('MATLAB:unittest:CoverageReport');

stringsStruct = struct('MainTitle',string(basicCoverageCatalog.getString('MainTitle')),...
    'MainDescription',string(basicCoverageCatalog.getString('MainDescription')),...
    'CoverageSummaryTitle',string(basicCoverageCatalog.getString('CoverageSummaryTitle')),...
    'CoverageSummaryDescription',string(basicCoverageCatalog.getString('CoverageSummaryDescription')),...
    'BreakdownBySourceTitle',string(basicCoverageCatalog.getString('BreakdownBySourceTitle')),...
    'BreakDownBySourceDescription',string(basicCoverageCatalog.getString('BreakDownBySourceDescription')),...
    'SummaryToggleButtonText',string(basicCoverageCatalog.getString('SummaryToggleButtonText')),...
    'DetailedToggleButtonText',string(basicCoverageCatalog.getString('DetailedToggleButtonText')),...
    'SourceDetailsTitle',string(basicCoverageCatalog.getString('SourceDetailsTitle')),...
    'SourceDetailsDescription',string(basicCoverageCatalog.getString('SourceDetailsDescription')),...
    'MetricHeader',string(basicCoverageCatalog.getString('MetricHeader')),...
    'StatementCoverage',string(basicCoverageCatalog.getString('StatementCoverage')),...
    'FunctionCoverage',string(basicCoverageCatalog.getString('FunctionCoverage')),...
    'TotalFiles',string(basicCoverageCatalog.getString('TotalFiles')),...
    'FileName',string(basicCoverageCatalog.getString('FileName')),...
    'OverallCoverage',string(basicCoverageCatalog.getString('OverallCoverage')),...
    'TotalExecutable',string(basicCoverageCatalog.getString('TotalExecutable')),...
    'TotalExecuted',string(basicCoverageCatalog.getString('TotalExecuted')),...
    'TotalMissed',string(basicCoverageCatalog.getString('TotalMissed')),...
    'LineNumberText',string(basicCoverageCatalog.getString('LineNumberText')),...
    'HitCountText',string(basicCoverageCatalog.getString('HitCountText')),...
    'CurrentlyViewingText',string(basicCoverageCatalog.getString('CurrentlyViewingText')),...
    'ReturnToTopText',string(basicCoverageCatalog.getString('ReturnToTopText')),...
    'RootLocationText',string(basicCoverageCatalog.getString('RootLocationText')),...
    'SourceFileNamePrefix',string(basicCoverageCatalog.getString('SourceFileNamePrefix')),...
    'InvalidLineRateText',string(basicCoverageCatalog.getString('InvalidLineRateText')),...
    'LabelToToggleCodeHighlightingForCoveredElements',string(basicCoverageCatalog.getString('LabelToToggleCodeHighlightingForCoveredElements')),...
    'LabelToToggleCodeHighlightingForMissedElements',string(basicCoverageCatalog.getString('LabelToToggleCodeHighlightingForMissedElements')),...
    'LabelToToggleCodeHighlightingForPartiallyCoveredElements',string(basicCoverageCatalog.getString('LabelToToggleCodeHighlightingForPartiallyCoveredElements')));

% locate additional catalog entries from metricHandlers
for handler = metricHandlers
    stringsStruct = handler.getMessageCatalogEntriesForMetrics(stringsStruct);
end
end
function writeToFile(filename,stringToWrite)
fid = fopen(filename, 'w','n','UTF-8');
cl = onCleanup(@()fclose(fid));
fprintf(fid,'%s',stringToWrite);
end  