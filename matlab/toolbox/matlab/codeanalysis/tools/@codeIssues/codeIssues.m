classdef (Sealed) codeIssues < matlab.mixin.CustomDisplay
%

% codeIssues Identifies code issues from one or more files
%
% The codeIssues object stores issues found by the MATLAB Code Analyzer
% in one or more specified files or folders. The issues found can be
% sorted and filtered, either programmatically or interactively
% on the command line.

%   Copyright 2021-2024 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        Date
        Release
    end
    properties (SetAccess = private)
        Files string {mustBeText};
        CodeAnalyzerConfiguration
        Issues
        SuppressedIssues
    end
    properties(Access = {?CodeCompatibilityAnalysis, ?matlab.codeanalyzer.internal.Exporter})
        modelFramework    % backend model framework
        modelMessages     % backend model messages
    end
    methods
        function obj = codeIssues(varargin)
            if nargin == 1 && isa(varargin{1}, 'mf.zero.Model')
                % Undocumented construction from a model.
                model = varargin{:};
            else
                % The publicly documented constructor.
                try
                    model = createModelAndAnalyze(varargin{:});
                catch E
                    throw(E);
                end
            end

            % construct codeIssues object with mf0 model with the message
            % results inside.
            % This assume the analysis is finished and results are saved.
            obj.modelFramework = model;
            obj.modelMessages = model.topLevelElements;
            obj.modelMessages.initialize();
            obj.CodeAnalyzerConfiguration = string(obj.modelMessages.configuration);
            obj.Issues = obj.createActiveIssues();
            obj.SuppressedIssues = obj.createSuppressedIssues();
            obj.Files = obj.modelMessages.analyzedFiles.toArray()'; % return column vector
        end
    end
    methods
        export(obj, filename, options)
    end
    methods
        function [obj, status] = fix(obj, whatToFix, filename)
            arguments
                obj
                whatToFix {validateWhatToFix}
                filename {validateFilename(filename, whatToFix, obj)} = missing;
            end

            % Validators don't have access to nargin.
            % Check if the second input arg is set to "missing" by the user, 
            % and so it isn't the default value.
            if nargin == 3 && isscalar(filename) && ismissing(filename)
                error(message("MATLAB:codeanalyzer:ArgMissingFilename"));
            end

            try
                if isa(whatToFix, 'table')
                    fixByIssueOccurrence(obj, whatToFix);
                else
                    fixByCheckID(obj, whatToFix, filename);
                end
            catch E
                % resolveNames can throw
                throw(E);
            end

            status = obj.createFixStatus();

            if ~isempty(status)
                numFailed = nnz(~status.Success);
                if nargout < 2 && numFailed > 0
                    statusWarning = createWarning(status);
                    warning(statusWarning);
                end
            end

            obj.Issues = obj.createActiveIssues();
            obj.SuppressedIssues = obj.createSuppressedIssues();
        end
    end
    methods(Hidden)
        % Converter method to convert codeIssue object to code analyzer
        % backend Server
        function server = matlab.codeanalyzerreport.internal.Server(obj, options)
            arguments
                obj codeIssues
                options.IsDashboard (1,1) logical = false;
                options.IsCompatibilityReport (1,1) logical = false;
            end
            if height(obj.Issues) + height (obj.SuppressedIssues) > obj.modelMessages.maxNumberOfMessages
                error(message('MATLAB:codeanalyzer:TooManyMessages', obj.modelMessages.maxNumberOfMessages));
            end
            mf0DataModel = obj.modelMessages.clone();
            messagesModel = mf0DataModel.topLevelElements;

            mf0StatusModel = mf.zero.Model();
            statusModel = matlab.codeanalyzer.internal.datamodel.StatusModel(mf0StatusModel);
            statusModel.initialized = true;
            statusModel.numMessages = height(obj.Issues);

            source = 'desktop';
            if options.IsDashboard
                source = 'dashboard';
            end
            if options.IsCompatibilityReport
                statusModel.grouping = "categoryId";
                statusModel.isCompatibilityReport = true;
            end

            server = matlab.codeanalyzerreport.internal.Server(mf0DataModel, messagesModel, mf0StatusModel, statusModel, source);
        end
    end
    methods(Access=private)
        function activeIssues = createActiveIssues(obj)
            msgArray = obj.modelMessages.getActiveMessages();
            activeIssues = createTable(msgArray);
        end

        function suppressedIssues = createSuppressedIssues(obj)
            msgArray = obj.modelMessages.getSuppressedMessages();
            suppressedIssues = createTable(msgArray);
            % Add sspression field;
            Suppression = matlab.codeanalysis.IssueSuppression({msgArray.suppression})';
            suppressedIssues = addvars(suppressedIssues,Suppression,'Before','CheckID');
        end
        function status = createFixStatus(obj)
            actionResults = obj.modelMessages.getAllActionResults();

            actionSuccess = logical([actionResults.success]');
            actionErrorMessage = string({actionResults.errorMessage}');
            actionFullFilename = string({actionResults.filename}');
            actionCheckID = categorical(string({actionResults.checkID}'));
            actionLineStart = double([actionResults.startLine]');
            actionLineEnd = double([actionResults.endLine]');
            actionColumnStart = double([actionResults.startColumn]');
            actionColumnEnd = double([actionResults.endColumn]');
            actionErrorID = string({actionResults.errorID}');

            % Successful actions don't have errors.
            % Show the user that as <missing> instead of as empty strings, "".
            actionErrorMessage(actionSuccess) = missing;
            actionErrorID(actionSuccess) = missing;

            if isempty(actionResults)
                status = table.empty(); % no results to show
            else
                status = table(actionSuccess, actionErrorMessage, actionFullFilename, actionCheckID, actionLineStart, actionLineEnd, actionColumnStart, actionColumnEnd, actionErrorID, ...
                    'VariableNames', ...
                    {'Success', 'ErrorMessage', 'FullFilename', 'CheckID', 'LineStart', 'LineEnd', 'ColumnStart', 'ColumnEnd', 'ErrorID'});
            end
        end
    end
    methods(Hidden, Access=protected)
        function customFooter = getFooter(obj)
            if ~isscalar(obj)
                customFooter = getFooter@matlab.mixin.CustomDisplay(obj);
                return;
            end
            % For scalar objects, use this custom footer.
            if (height(obj.Issues) == 0)
                customFooter = '';
            else
                % Using default values for table.
                areLinksSupported = feature('hotlinks');
                bold = false;
                if areLinksSupported
                    bold = true;
                end
                indent = 4; fullChar = false; nestedLevel = 1;
                numPreviewTableRows = 0;
                % For taller tables, adjust the shown height based on the
                % command window height.
                if (height(obj.Issues) > 20 && areLinksSupported)
                    % Default value for table with over 20 rows.
                    % 5 rows from the top, 5 rows from the bottom.
                    numPreviewTableRows = 10;
                    commandSize = matlab.desktop.commandwindow.size;
                    commandHeight = commandSize(2);
                    commandFormat = format;
                    if (commandFormat.LineSpacing == "compact")
                        numClassHeaderFooterLines = 10;
                        numObjectPropertiesLines = 5;
                        numTableHeaderAndSplitLines = 4;
                    else
                        numClassHeaderFooterLines = 16;
                        numObjectPropertiesLines = 5;
                        numTableHeaderAndSplitLines = 6;
                    end
                    minObjectDisplayLines = numPreviewTableRows + numClassHeaderFooterLines + ...
                        numObjectPropertiesLines + numTableHeaderAndSplitLines;
                    % If command window is tall enough, show more table rows.
                    if (commandHeight > minObjectDisplayLines)
                        numPreviewTableRows = numPreviewTableRows + commandHeight - minObjectDisplayLines;
                        % numPreviewTableRows must be an even number.
                        numPreviewTableRows = numPreviewTableRows - rem(numPreviewTableRows, 2);
                    end

                    % For tables with many rows, the table preview shows a partial table.
                    % Create a link which will show the full table.
                    outputVarName = inputname(1);  % For the link, get name of variable.
                    tableHeight = height(obj.Issues);
                    % For the preview link, create the reference and text
                    msgVarNoExist = getString(message('MATLAB:codeanalyzer:DisplayLinkMissingVariable', (outputVarName + ".Issues")));
                    displayObject = sprintf("displayWholeObj(%s.Issues)", outputVarName);
                    linkReference = sprintf("if exist('%s','var'), %s, else, fprintf('%s\\n');end", outputVarName, displayObject, msgVarNoExist);
                    linkText = getString(message('MATLAB:codeanalyzer:DisplayAllRowsLink', tableHeight));
                    previewLink = char(sprintf('\t<a href="matlab:%s">%s</a>\n', linkReference, linkText));
                else
                    % Since full table is be shown, no link is needed.
                    previewLink = '';
                end
                tableLabel = char(string(message("MATLAB:codeanalyzer:LabelIssueTablePreview")));
                tableLabel = [newline  '    '  tableLabel newline];
                customFooter = [tableLabel newline evalc("disp(obj.Issues, bold, indent, fullChar, nestedLevel, numPreviewTableRows)") previewLink newline];
            end
        end
    end
    methods
        function date = get.Date(obj)
            date = datetime(obj.modelMessages.timeStamp, ConvertFrom="epochtime",TicksPerSecond=1000, TimeZone="UTC");
            date.TimeZone = "local";
        end
        function release = get.Release(obj)
            release = string(obj.modelMessages.MATLABRelease);
        end
        function s = saveobj(obj)
            serializer = mf.zero.io.JSONSerializer;
            s.json = serializer.serializeToString(obj.modelFramework);
            s.version = 1;
        end
    end
    methods(Static)
        function obj = loadobj(s)
            if s.version == 1
                % The first version is a JSON format, so the json field
                % must exist
                parser = mf.zero.io.JSONParser;
                parser.parseString(s.json);
                obj = codeIssues(parser.Model);
            else
                error(message("MATLAB:codeanalyzer:IncompatibleCodeIssues"));
            end
        end
    end
    methods(Access=private)
        function obj = fixByCheckID(obj, checkID, filenames)
            checkID = string(checkID);

            if isempty(checkID)
                return; % nothing to do
            end
            % filenames default is <missing>
            if (isscalar(filenames) && ismissing(filenames)) || isempty(filenames)
                obj.modelMessages.fixAllByCheckID(checkID);
            else
                names = resolveNames(filenames);
                obj.modelMessages.fixByCheckID(checkID, names)
            end
        end
        function obj = fixByIssueOccurrence(obj, issuesTable)
            issueOccurrences = createOccurrencesFromTable(issuesTable);
            obj.modelMessages.fixByOccurrences(issueOccurrences);
        end
    end
end

function model = createModelAndAnalyze(names, options)
    arguments
        names {mustBeNonzeroLengthText} = pwd;
        options.IncludeSubfolders logical = true;
        options.CodeAnalyzerConfiguration {mustBeNonzeroLengthText, mustBeTextScalar} = "active";
    end
    names = resolveNames(names);
    options.CodeAnalyzerConfiguration = matlab.codeanalyzer.internal.resolveConfigurationFilename(options.CodeAnalyzerConfiguration);

    model = mf.zero.Model();
    messages = matlab.codeanalyzer.internal.datamodel.MessagesModel(model);
    messages.topFolderOnly = ~options.IncludeSubfolders;
    messages.configuration = options.CodeAnalyzerConfiguration;
    messages.options.add("-includeSuppression");
    messages.displayWarningEvent.registerHandler(@(~, msg, id) warning(id, '%s', msg));
    prepareModelFileList(messages, names);
    % analyze files
    messages.analyze();
end

function resolvedNames = resolveNames(names)
    if feature("AppDesignerPlainTextFileFormat")
        validExtension = {'.m', '.mlx', '.mlapp', '.mapp'};
    else
        validExtension = {'.m', '.mlx', '.mlapp'};
    end
    % Get fully-qualified path for names
    resolvedNames = matlab.codeanalyzer.internal.resolvePaths(names, validExtension);
end

function prepareModelFileList(modelMessages, names)
    for oneName = names
        if isfolder(oneName)
            modelMessages.folders.add(char(oneName))
        else
            modelMessages.files.add(char(oneName))
        end
    end
end

function ret = createTable(msgArray)
    fullfilename = string({msgArray.filename})';
    lineStart = double([msgArray.startLine]');
    lineEnd = double([msgArray.endLine]');
    columnStart = double([msgArray.startColumn]');
    columnEnd = double([msgArray.endColumn]');
    severity = matlab.codeanalysis.IssueSeverity({msgArray.severityId})';
    fixability = getFixability(msgArray)';
    checkID = categorical({msgArray.tag})';
    description = string({msgArray.message})';

    % Create a hyperlink to a specific line in the file.
    if ~isempty(msgArray)
        [~, filename, fileExtension] = fileparts(fullfilename);
        filename = filename + fileExtension;
        if feature('hotlinks')
            filename = "<a href = ""matlab:opentoline('" + fullfilename + "', " + lineStart + ")"">" + filename + "</a>";
        end
    else
        filename = string.empty(0, 0);
    end
    ret = table(filename, severity, fixability, description, checkID, lineStart, lineEnd, columnStart, columnEnd, fullfilename, ...
                'VariableNames', ...
                {'Location', 'Severity', 'Fixability', 'Description', 'CheckID', 'LineStart', 'LineEnd', 'ColumnStart', 'ColumnEnd', 'FullFilename'});
end

function fixabilityValue = getFixability(msgArray)
    % initialize array to proper size, using manual as the default.
    if isempty(msgArray)
        fixabilityValue = matlab.codeanalysis.IssueFixability.empty();
    else
        fixabilityValue(size(msgArray, 2)) = matlab.codeanalysis.IssueFixability.manual;
        fixabilityValue([msgArray.fixIndex] ~= 0) = matlab.codeanalysis.IssueFixability.auto;
    end
end

function issueOccurrences = createOccurrencesFromTable(subtable)
    if height(subtable)==0
        issueOccurrences = matlab.codeanalyzer.internal.datamodel.Message.empty();
        return;
    end
    issueOccurrences(height(subtable)) = matlab.codeanalyzer.internal.datamodel.Message;
    for row=1:height(subtable)
        issueOccurrences(row).filename = subtable.FullFilename(row);
        issueOccurrences(row).tag = string(subtable.CheckID(row)); % convert from categorical
        issueOccurrences(row).startLine = subtable.LineStart(row);
        issueOccurrences(row).endLine = subtable.LineEnd(row);
        issueOccurrences(row).startColumn = subtable.ColumnStart(row);
        issueOccurrences(row).endColumn = subtable.ColumnEnd(row);
    end
end

function statusMessage = createWarning(status)
    numFailed = nnz(~status.Success);
    numSuccess = numel(status.Success) - numFailed;

    warningSummary = message("MATLAB:codeanalyzer:FixProblemSummary", numSuccess, numFailed);
    warningPrefix = message("MATLAB:codeanalyzer:FixProblemPrefix");
    warningSuffix = message("MATLAB:codeanalyzer:FixProblemSuffix");

    % Only show failed attempts.
    status = status(~status.Success, :);
    statusWarnings = unique(status(:, "ErrorMessage"));

    if height(statusWarnings) < 11
        warningDetails = sprintf("%s\n", statusWarnings{:, "ErrorMessage"});
    else
        detailsTop = sprintf("%s\n", statusWarnings{1:5, "ErrorMessage"});
        detailsBottom = sprintf("%s\n", statusWarnings{end-4:end, "ErrorMessage"});
        warningDetails = sprintf("%s:\n%s", detailsTop, detailsBottom);
    end

    statusMessage = sprintf("%s\n%s\n\n%s\n%s\n", ...
        warningSummary, warningPrefix, warningDetails, warningSuffix);
end

function validateWhatToFix(whatToFix)
    if istable(whatToFix)
        % Validate columns in table
        requiredColumns = {'CheckID', 'FullFilename', 'LineStart', 'LineEnd', 'ColumnStart', 'ColumnEnd'};
        tableColumnNames = whatToFix.Properties.VariableNames;
        foundAllRequiredColumns = all(ismember(requiredColumns, tableColumnNames));
        if ~foundAllRequiredColumns
            error(message("MATLAB:codeanalyzer:TableMissingColumns"));
        end
    elseif (ischar(whatToFix) && isrow(whatToFix)) || iscellstr(whatToFix) || isstring(whatToFix)
        mustBeText(whatToFix)

        % This should be a check ID.
        % In the body of the method, the check ID input is transformed into string.
        checkID = string(whatToFix); % depends on transformation happening, when fix method is invoked.
        % If not all of characters are valid for a check ID, then error.
        if ~all(matches(checkID, regexpPattern('[a-zA-Z0-9.]*')))
            error(message("MATLAB:codeanalyzer:ArgOneInvalid"));
        end

        return;
    else
        error(message("MATLAB:codeanalyzer:ArgOneInvalid"));
    end
end

function validateFilename(filenames, checkID, obj)
    % Look for default value, which is a scalar value missing.
    % This has a max dimension of 1.
    % Using length will not work for tables.
    if isscalar(filenames) && ismissing(filenames)
        % This is just the default value, ignore it.
        return
    end

    if istable(checkID)
        % filename is only allowed with checkID
        error(message("MATLAB:codeanalyzer:ArgFilename"));
    end

    mustBeText(filenames)

    % The input filename must match an existing filename.
    % Also, input filenames cannot be duplicated.
    % Do all of the input filenames match an existing filename?
    names = resolveNames(filenames);
    if length(names) > length(unique(names))
        error(message("MATLAB:codeanalyzer:DuplicateFilename"));
    end
    if ~all(ismember(names, obj.Files))
        error(message("MATLAB:codeanalyzer:UnusedFilename"));
    end
end
