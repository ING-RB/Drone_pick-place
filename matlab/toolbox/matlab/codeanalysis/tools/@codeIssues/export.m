function export(obj, filename, options)
%

%
% export a codeIssues object into a JSON, SARIF formatted file
%
% The function takes the properties and Issues table from the codeIssues object
% and builds a struct that corresponds to the necessary SARIF properties,
% before encoding into json.
%
% SuppressedIssues are not included.
%
% Example:
% result = codeIssues;
% export(result, "github.json", FileFormat="sarif", SourceRoot=pwd)
%

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        obj codeIssues
        filename {mustBeTextScalar, mustBeNonzeroLengthText} = "codeIssues.sarif";
        options.FileFormat string {mustBeMember(options.FileFormat, {'auto', 'json', 'sarif', 'sonarqube'})} = "auto";
        options.SourceRoot {matlab.codeanalyzer.internal.validateSourceRoot(options.SourceRoot, obj)} = missing;
    end
    filename = string(filename);

    % If auto, determine what should be the FileFormat.
    if options.FileFormat == "auto"
        [~, filenameStem, fileExtension] = fileparts(filename);
        if strlength(fileExtension) == 0
            options.FileFormat = "sarif";
            filename = filename + ".sarif";
        elseif lower(fileExtension) == ".sarif"
            options.FileFormat = "sarif";
        elseif lower(fileExtension) == ".json"
            % look for ".sarif.json"
            [~, ~, fileSecondExtension] = fileparts(filenameStem);
            if lower(fileSecondExtension) == ".sarif"
                options.FileFormat = "sarif";
            else
                error(message("MATLAB:codeanalyzer:AmbigFileExt", fileExtension));
            end
        else
            error(message("MATLAB:codeanalyzer:UnknownFileExt", fileExtension));
        end
    end

    switch options.FileFormat
        case "sarif"
            exportSarif(obj, filename, options.SourceRoot);
        case "sonarqube"
            exportSonarQube(obj, filename);
        otherwise % json
            exportJson(obj, filename);
    end
end

function exportJson(issues, filename)
    prettyJSON = jsonencode(issues, PrettyPrint=true);
    writelines(prettyJSON, filename);
end

function exportSarif(issues, filename, sourceRoot)
    % Code scanning on GitHub only supports version 2.1.0
    sarifLog.version = "2.1.0";
    % Date, Release, and Code Analyzer Configuration do not have a set
    % property in SARIF, so they are put in a generic property bag
    sarifLog.properties.Date = issues.Date;
    sarifLog.properties.Release = issues.Release;
    sarifLog.properties.CodeAnalyzerConfiguration = issues.CodeAnalyzerConfiguration;

    % The driver name is required, but not the other sub-properties.
    runs.tool.driver = struct("name", "Code Analyzer");

    % The ID name uses for the source root.
    sourceRootBaseId = "SourceRoot";
    if ~ismissing(sourceRoot)
        % originalUriBaseIds is the mapping of uriBaseId to source root file path
        runs.originalUriBaseIds.(sourceRootBaseId).uri = mlreportgen.utils.fileToURI(sourceRoot);
    end

    % In the artifact property, put the list of analyzed files.
    artifactsArray = struct.empty();
    for i = 1:length(issues.Files)
        if ismissing(sourceRoot)
            artifactsArray(i).location.uri = mlreportgen.utils.fileToURI(issues.Files(i));
        else
            artifactsArray(i).location.uriBaseId = sourceRootBaseId;
            artifactsArray(i).location.uri = fileUri(sourceRoot, issues.Files(i));
        end
    end
    % to force an array for jsonencode, wrap in cell array for scalar
    if size(artifactsArray, 2) == 1
        runs.artifacts = {artifactsArray};
    else
        runs.artifacts = artifactsArray;
    end

    % Preallocating results list with structs
    if height(issues.Issues) == 0
        resultsArray = struct.empty();
    else
        resultsArray(height(issues.Issues)) = struct;
        % For each issue, creating a struct that contains
        % rule id, level, message, and location.
        for i = 1:height(issues.Issues)
            resultsArray(i).ruleId = issues.Issues.CheckID(i);

            % Map Code Analyzer severity to SARIF level
            severity = issues.Issues.Severity(i);
            switch severity
                case "error"
                    level = "error";
                case "warning"
                    level = "warning";
                case "info"
                    level = "note";
            end
            resultsArray(i).level = level;
            resultsArray(i).message = struct("text", issues.Issues.Description(i));

            if ismissing(sourceRoot)
                location.physicalLocation.artifactLocation.uri = mlreportgen.utils.fileToURI(issues.Issues.FullFilename(i));
            else
                % The mapping for uriBaseId can be found in originalUriBaseIds
                location.physicalLocation.artifactLocation.uriBaseId = sourceRootBaseId;
                location.physicalLocation.artifactLocation.uri = fileUri(sourceRoot, issues.Issues.FullFilename(i));
            end

            % When issue is a file level error, region should be omitted
            if issues.Issues.LineStart(i) ~= 0
                location.physicalLocation.region.startLine = issues.Issues.LineStart(i);
                location.physicalLocation.region.endLine = issues.Issues.LineEnd(i);
                location.physicalLocation.region.startColumn = issues.Issues.ColumnStart(i);
                % SARIF's end column value is one greater than the column
                % number of the last character in the region
                location.physicalLocation.region.endColumn = issues.Issues.ColumnEnd(i) + 1;
            end

            % locations is an array, even with a single location struct
            resultsArray(i).locations = {location};
        end
    end

    % to force an array for jsonencode, wrap in cell array for scalar
    if size(resultsArray, 2) == 1
        runs.results = {resultsArray};
    else
        runs.results = resultsArray;
    end
    % runs is an array containing a single codeIssues run
    sarifLog.runs = {runs};

    prettyJSON = jsonencode(sarifLog, PrettyPrint=true);
    writelines(prettyJSON, filename);
end

function exportSonarQube(issues, filename)
    engineId = "Code Analyzer";

    % Preallocating results list with structs
    if height(issues.Issues) == 0
        resultsArray = struct.empty();
    else
        resultsArray(height(issues.Issues)) = struct;
        for i = 1:height(issues.Issues)
            resultsArray(i).engineId = engineId;
            resultsArray(i).ruleId = issues.Issues.CheckID(i);

            % Based on Code Analyzer check severity and check category,
            % determine SonarQube check severity and check type.
            CAseverity = issues.Issues.Severity(i);
            switch CAseverity
                case "error"
                    severity = "BLOCKER";
                    type = "BUG";
                case "warning"
                    severity = "MAJOR";
                    type = "CODE_SMELL";
                case "info"
                    severity = "MINOR";
                    type = "CODE_SMELL";
                otherwise
                    severity = "MINOR";
                    type = "CODE_SMELL";
            end

            % checks in this category are always severity INFO
            if issues.modelMessages.isCheckMemberOfCategory(string(issues.Issues.CheckID(i)), ...
                    "MINFO")
                severity = "INFO";
            end
            resultsArray(i).severity = severity;

            % checks in these categories are always type BUG
            if issues.modelMessages.isCheckMemberOfCategory(string(issues.Issues.CheckID(i)), ...
                    ["BUGS", "SYNTAX", "INTRN", "LANER"])
                type = "BUG";
            end
            resultsArray(i).type = type;

            resultsArray(i).primaryLocation.message = issues.Issues.Description(i);

            resultsArray(i).primaryLocation.filePath = issues.Issues.FullFilename(i);

            % For SonarQube, file level messages can omit textRange
            % When issue is a file level error, region should be omitted
            if issues.Issues.LineStart(i) ~= 0
                resultsArray(i).primaryLocation.textRange.startLine = issues.Issues.LineStart(i);
                resultsArray(i).primaryLocation.textRange.endLine = issues.Issues.LineEnd(i);

                % SonarQube columns are 0 indexed. Code Analyzer is 1 indexed.
                resultsArray(i).primaryLocation.textRange.startColumn = issues.Issues.ColumnStart(i) - 1;
                % SARIF's end column value is one greater than the column
                % number of the last character in the region.
                % For Code Analyzer, the net is to add 0.
                resultsArray(i).primaryLocation.textRange.endColumn = issues.Issues.ColumnEnd(i);
            end
        end
    end

    % if resultsArray is length 1, force "issues" as array in JSON
    if isscalar(resultsArray)
        prettyJSON = jsonencode(resultsArray, PrettyPrint=true);
        prettyJSON = sprintf('{ "issues": [\n%s\n]}\n', prettyJSON);
    else
        sonarQubeLog.issues = resultsArray;
        prettyJSON = jsonencode(sonarQubeLog, PrettyPrint=true);
    end

    writelines(prettyJSON, filename);
end

function relativeFilename = fileUri(sourceRoot, fullFilename)
    % Before calling this function, should have checked for default value of missing.
    assert(~(isscalar(sourceRoot) && ismissing(sourceRoot)));

    % URIs must conform to [RFC 3986](https://tools.ietf.org/html/rfc3986)
    uriFullFilename = mlreportgen.utils.fileToURI(fullFilename);
    % The source root has already been validated.
    uriSourceRoot = mlreportgen.utils.fileToURI(sourceRoot);

    % After source root validation, expecting source root to be at the start of file path.
    assert(all(startsWith(uriFullFilename, uriSourceRoot)));

    % Remove source root from full file path.
    relativeFilename = replaceBetween(uriFullFilename, 1, strlength(uriSourceRoot), "");
end

