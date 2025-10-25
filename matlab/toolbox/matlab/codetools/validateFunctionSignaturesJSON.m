function T = validateFunctionSignaturesJSON(filenames)
% VALIDATEFUNCTIONSIGNATURESJSON  Validate functionSignatures.json files.
%
%   VALIDATEFUNCTIONSIGNATURESJSON() validates a functionSignatures.json file
%   in the current folder or a "resources" subfolder.
%
%   VALIDATEFUNCTIONSIGNATURESJSON(filenames) validates filenames. filenames
%   can be a string array, character vector, or cell array of character
%   vectors.
%
%   T = VALIDATEFUNCTIONSIGNATURESJSON(___) returns a table of results.

%   Copyright 2018-2021 The MathWorks, Inc.

if nargin<1
    filenames = "functionSignatures.json";
end

filenames=convertCharsToStrings(filenames);
log([]);
T = log();

for i=1:numel(filenames)

    filename = filenames(i);
    result = validateOneJsonFile(filename);
    T = [T;result]; %#ok<AGROW>

    if nargout==0 && ~isempty(result)
        disp(filename);
        disp(repmat('=', [1, strlength(filename)]));
        for j = 1:size(result,1)
            cols = result{j,'ColumnExtents'};
            if matlab.internal.display.isHot
                location = compose("<a href=""matlab:opentoline('%s', %d, %d)"">L %d</a> (C %d-%d)", ...
                    result{j,'Filename'}, result{j,'LineNumber'}, cols(1), ...
                    result{j,'LineNumber'}, cols(1), cols(2));
            else
                location = compose("L %d (C %d-%d)", result{j,'LineNumber'}, cols(1), cols(2));
            end
            outputMessage = location + ": " + result{j,'Message'};
            disp(outputMessage);
        end
        fprintf('\n')
    end
end

if nargout==0
    if isempty(T)
        disp(getString(message("MATLAB:validateFunctionSignaturesJSON:noOutputAtCompletion")));
    end
    clear T;
else
    T(:,'MessageId')=[];
end

end

function T = validateOneJsonFile(filename)
log([]);
filename = checkResourcesFolder(filename);
txt = string(readUTF8(char(filename)));
isShadowed = ~isempty(log());

try
    jsondecode(char(txt));
    json = tokenJSON(filename, char(txt));
catch e

    % Note that this relies on scraping the error string for line number and column information.
    % It is risky in that some translation could place these numbers (holes) in a different order.
    % However, the order is thus far the same for all languages we translate to (English, Chinese,
    % Korean, and Japanese, as-of this writing).

    matchedNumbers = double(string(regexp(e.message, '[0-9]+', 'match')));
    if numel(matchedNumbers) ~= 3
        % Report error at end of file
        endOfLines = find(char(txt)==newline);
        lineNumber = numel(endOfLines)+1;

        if isempty(endOfLines)
            endOfLines = 0;
        end

        columnNumber = strlength(txt) - endOfLines(end) + 1;
        matchedNumbers = [lineNumber, columnNumber];
    end

    s = newToken(string(filename), 'error', e.message, matchedNumbers(1), [matchedNumbers(2) matchedNumbers(2)+1]);
    if ~isShadowed
        log([]);
    end
    log(s, "jsonParsingError", e.message);
    json = [];
end

if exist('json', 'var') && ~isempty(json)

    if json(1).name ~= "leftCurlyBrace"
        log(json(1), "objectExpected");
    else
        functionInfo = struct;
        functionInfo.m = containers.Map();
        fileInfo = dir(json(1).file);
        functionInfo.inToolboxFolder = startsWith(fileInfo.folder, fullfile(matlabroot, 'toolbox'));
        json = processAttributesWithUnderscores(json);
        idx = 2;
        while idx+1 < numel(json)
            [json, idx, functionInfo.name] = validateName(json, idx);
            if json(idx).name=="comma" || json(idx).name=="rightCurlyBrace"
                idx = idx + 1;
            else
                [functionInfo, json, idx] = validateSignature(functionInfo, json, idx);
            end
            if json(idx).name=="comma"
                idx = idx + 1;
            end

        end
        validateSignatures(functionInfo);
    end
end

T = log();
T = sortrows(T, {'Filename', 'LineNumber', 'ColumnExtents', 'MessageId'});

end

function p = processAttributesWithUnderscores(p)

ranges = zeros(0,2);
i = 1;

while i < numel(p)
    if p(i).name=="string" && ~isempty(p(i).token) && p(i).token(1)=='_'
        e = findEndOfValue(p, i);
        if p(e+1).name=="comma"
            e = e + 1;
        end
        ranges(end+1, :) = [i, e]; %#ok<AGROW>
        i = e;
    end
    i = i + 1;
end

for i=1:size(ranges,1)
    validateSchema(p, ranges(i,1));
end

for i=size(ranges,1):-1:1
    p(ranges(i,1):ranges(i,2))=[];
end

end

function validateSchema(p, idx)
if p(idx).token=="_schemaVersion"

    if idx>2
        log(p(idx), "schemaUnexpectedLocation");
    end

    [p, newIdx] = validateExpectString(p, idx+2);
    if newIdx==idx+2
        knownSchemaVersions = ["1.0.0", "1.1.0"]; % Update message catalog when this changes.
        if ~any(knownSchemaVersions == p(newIdx).token)
            log(p(newIdx), "schemaUnexpectedValue");
        end
    end
end
end

function i = findEndOfValue(p, i, maxDepth, messageId, varargin)

if nargin < 3
    maxDepth = inf;
end

if p(i+1).name ~= "colon"
    return
end

depth = 0;
done = false;
reportedDepthError = false;
i = i + 2;

while ~done
    switch p(i).name
        case {'leftCurlyBrace', 'leftSquareBrace'}
            depth = depth + 1;
            if depth > maxDepth && ~reportedDepthError
                log(p(i), messageId, varargin{:});
                reportedDepthError = true;
            end
        case {'rightCurlyBrace', 'rightSquareBrace'}
            depth = depth - 1;
        otherwise
    end

    done = depth==0;
    if ~done
        i = i + 1;
    end
end

end

function [p, idx, functionInfo] = validateName(p, idx)

functionInfo = p(idx);
name = p(idx).token;

lastDot = find(name=='.', 1, 'last');
if isempty(lastDot)

    if isempty(name)
        log(p(idx), "emptyString")
    elseif isempty(safeWhich(name))
        log(p(idx), "functionNotFound", name);
    end

else

    className = name(1:lastDot-1);
    methodName = name(lastDot+1:end);
    if name(lastDot+1)=='_'

        if ~(endsWith(name, "_parenReference") || endsWith(name, "_parenAssign") || ...
                endsWith(name, "_curlyBraceReference") || endsWith(name, "_curlyBraceAssign") || ...
                endsWith(name, "_dotAssign"))
        log(p(idx), "methodNameInvalid", methodName, className);
        end

    else

        metadata = meta.class.fromName(className);
        if isempty(metadata)
            if  isempty(which(name))
                log(p(idx), "classWithoutMetadata", name);
            end
        else
            methods = string({metadata.MethodList.Name});
            methodIdx = find(methods==methodName, 1);
            if isempty(methodIdx)
                log(p(idx), "methodWithoutMetadata", methodName, className);
            elseif ~strcmp(metadata.MethodList(methodIdx).DefiningClass.Name, metadata.Name)
                log(p(idx), "methodGivenForWrongOverload", ...
                    name, [metadata.MethodList(methodIdx).DefiningClass.Name '.' methodName], ...
                    methodName, metadata.MethodList(methodIdx).DefiningClass.Name, className);
            end
        end
    end
end

if isLiveTaskFile(p(idx).file)
    try
        if ~inheritsFrom(name, 'matlab.task.LiveTask')
            log(p(idx), "expectedIsA", name, 'matlab.task.LiveTask');
        end
    catch
        log(p(idx), "classWithoutMetadata", name);
    end
end
idx = idx+2;
end

function tf = inheritsFrom(className, possibleParent)
tf = false;
md = meta.class.fromName(className);
if isempty(md)
    return
end
if any(possibleParent==string({md.SuperclassList.Name}))
    tf = true;
else
    for i = 1:numel(md.SuperclassList)
        if inheritsFrom(md.SuperclassList(i).Name, possibleParent)
            tf = true;
        end
    end
end
end

function validateSignatures(functionInfo)

crossSignaturesValidations = { ...
    };
crossSignaturesValidations = [crossSignaturesValidations; validateFunctionSignaturesJSON_privateCrossSignatureValidations()];

for i=1:numel(crossSignaturesValidations)
    crossSignaturesValidations{i}(functionInfo, @log);
end
end

function [functionInfo, p, idx] = validateSignature(functionInfo, p, idx)

if ~strcmp(p(idx).name, 'leftCurlyBrace')
    log(p(idx), "objectExpected");
    idx = skipValue(p, idx);
    return
end
idx = idx+1;

nonInputOutputValidations = { ...
    @(p, idx) validateNotEmptyName(p, idx), ...
    @(p, idx) validateSignatureNotUsingSetsAns(p, idx), ...
    @(p, idx) validateNotUsingPlatform(p, idx) ...
    @(p, idx) validatePlatforms(p, idx) ...
    @(p, idx) validateSupportDotMethodInvocation(p, idx) ...
    @(p, idx) validateNotUsingPurpose(p, idx) ...
    @(p, idx) validateDescription(p, idx) ...
    @(p, idx) validateDocLink(p, idx) ...
    @(p, idx) validateRole(p, idx) ...
    @(p, idx) validateTaskMetadataString(p, idx) ...
    @(p, idx) validateLiveTaskMessageCatalogEntries(p, idx, functionInfo) ...
    @(p, idx) validateLiveTaskIcon(p, idx) ...
    @(p, idx) validateTaskInfo(p, idx) ...
    @(p, idx) validateNotUsingAppName(p, idx) ...
    @(p, idx) validateAppName(p, idx) ...
    @(p, idx) validateKeywords(p, idx) ...
    @(p, idx) validateEmbeddable(p, idx) ...
    };

inputsInfo = cell(0);
outputsInfo = cell(0);
while ~strcmp(p(idx).name, 'rightCurlyBrace')
    switch p(idx).token
        case ','
            idx = idx+1;
        case 'inputs'
            [functionInfo, p, idx, inputsInfo] = validateInputsOrOutputs(true, functionInfo, p, idx+2);
        case 'outputs'
            [functionInfo, p, idx, outputsInfo] = validateInputsOrOutputs(false, functionInfo, p, idx+2);
        otherwise

            done = false;
            for i=1:numel(nonInputOutputValidations)
                if done
                    break
                end

                [p, newIdx] = nonInputOutputValidations{i}(p, idx);

                if newIdx ~= idx
                    idx = newIdx;
                    done = true;
                end
            end

            if ~done
                log(p(idx), "nameInvalid", p(idx).token);
                idx = skipValue(p, idx+1);
            end
    end
end
idx=idx+1;

crossInputsAndOutputsValidations = { ...
    @(inputsInfo, outputsInfo) validateInferredFrom(inputsInfo, outputsInfo)
    @(inputsInfo, outputsInfo) validateFromPrototypeOrClassname(inputsInfo, outputsInfo)
    };

for i=1:numel(crossInputsAndOutputsValidations)
    crossInputsAndOutputsValidations{i}(inputsInfo, outputsInfo);
end

end

function [p, idx] = validateExpectString(p, idx)
if p(idx).name ~= "string"
    log(p(idx), "stringExpected")
    idx = skipValue(p, idx);
end
end

function [p, idx] = validateExpectTrueFalse(p, idx)
if p(idx).name ~= "true" && p(idx).name ~= "false"
    log(p(idx), "trueOrFalseExpected")
    idx = skipValue(p, idx);
end
end

function [p, idx] = validateExpectObject(p, idx)
if p(idx).name ~= "leftCurlyBrace"
    log(p(idx), "objectExpected")
    idx = skipValue(p, idx);
end
end

function [p, idx] = validateNotEmptyName(p, idx)
if isempty(p(idx).token)
    log(p(idx), "emptyString");
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateSignatureNotUsingSetsAns(p, idx)
if p(idx).token == "setsAns"
    log(p(idx), "nameRemoved", "setsAns");
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateNotUsingPlatform(p, idx)
if p(idx).token == "platform"
    log(p(idx), "nameRenamed", "platform", "platforms");
    p(idx).token = 'platforms';
end
end

function [p, idx] = validatePlatforms(p, idx)
if p(idx).token == "platforms"
    if p(idx+2).name == "string"
        knownPlatforms = ["win64", "maci64", "glnxa64"]; % Update message catalog if this list changes
        platforms = string(split(p(idx+2).token, ','));
        for i=1:numel(platforms)
            platform = strip(platforms(i));
            if startsWith(platform, '-')
                platform = extractAfter(platform, 1);
            end
            if ~any(knownPlatforms==platform)
                log(p(idx+2), "valueInvalid", "platforms", platform);
            end
        end
        idx = skipValue(p, idx+1);
    else
        [p, idx] = validateExpectString(p, idx+2);
    end
end
end

function [p, idx] = validateSupportDotMethodInvocation(p, idx)
if p(idx).token == "supportDotMethodInvocation"
    validateExpectTrueFalse(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateNotUsingPurpose(p, idx)
if p(idx).token == "purpose"
    log(p(idx), "nameRenamed", "purpose", "description");
    p(idx).token = 'description';
end
end

function [p, idx] = validateDescription(p, idx)
if p(idx).token == "description"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateDocLink(p, idx)
if p(idx).token == "docLink"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateRole(p, idx)
if p(idx).token == "role"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateTaskMetadataString(p, idx)
if p(idx).token == "category" || p(idx).token == "uniqueId"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateLiveTaskMessageCatalogEntries(p, idx, functionInfo)
if p(idx).token == "messageCatalog"
    validateExpectString(p, idx+2);
    taskName = strsplit(functionInfo.name.token, '.');
    messageSuffixes = {'_Label' '_Description'};
    for suffix = messageSuffixes
        try
            messageId = [p(idx+2).token ':Tool_' taskName{end} suffix{1}];
            message(messageId).getString();
        catch
            log(p(idx+2), 'invalidMessageId', messageId);
        end
    end
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateLiveTaskIcon(p, idx)
if p(idx).token == "icon" || p(idx).token == "quickAccessIcon"
    validateExpectString(p, idx+2);
    baseFolder = fileparts(p(idx+2).file);
    if strlength(baseFolder) == 0
        baseFolder = ".";
    end
    relativePath = p(idx+2).token;
    iconFileName = strjoin([baseFolder relativePath], "/");
    if ~isfile(iconFileName)
        log(p(idx+2), 'pathToFileInvalid', relativePath, baseFolder);
    end
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateNotUsingAppName(p, idx)
if p(idx).token == "appName"
    log(p(idx), "nameRenamed", "appName", "name");
    p(idx).token = 'name';
end
end

function [p, idx] = validateAppName(p, idx)
if p(idx).token == "name"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateKeywords(p, idx)
if p(idx).token == "keywords"
    validateExpectString(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateEmbeddable(p, idx)
if p(idx).token == "embeddable"
    validateExpectTrueFalse(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateTaskInfo(p, idx)
if p(idx).token == "taskInfo"
    validateExpectObject(p, idx+2);
    idx = skipValue(p, idx+1);
end
end

function validateInferredFrom(inputsInfo, outputsInfo)
for outputIdx = 1:numel(outputsInfo)
    if ~isfield(outputsInfo{outputIdx}, 'type')
        continue;
    end

    for attribute=find(cellfun(@(x) startsWith(x, 'inferredFrom'), {outputsInfo{outputIdx}.type.token}))
        parts = strtrim(strsplit(outputsInfo{outputIdx}.type(attribute).token, '='));
        if numel(parts) > 1
            parts = strtrim(strsplit(parts{2}, ','));
            for i=1:numel(parts)
                if isempty(findName(parts{i}, inputsInfo))
                    log(outputsInfo{outputIdx}.type(attribute), "inferredFromNameDoesNotExist", parts{i});
                end
            end
        end
    end
end
end

function validateFromPrototypeOrClassname(inputsInfo, outputsInfo)
for outputIdx = 1:numel(outputsInfo)
    if ~isfield(outputsInfo{outputIdx}, 'type')
        continue;
    end

    for attributes=find(cellfun(@(x) strcmp(x, 'fromPrototypeOrClassname'), {outputsInfo{outputIdx}.type.token}))
        expectedInputArgumentNames = ["classname", "typename", "'like'"];
        if isempty(findName(expectedInputArgumentNames, inputsInfo))
            log(outputsInfo{outputIdx}.type(attributes), "prototypeArgumentDoesNotExist");
        end
    end
end
end

function N = findName(name, args)
for i = 1:numel(args)
    if isfield(args{i}, 'name') && any(strcmp(name, args{i}.name.token))
        N = args{i};
        return
    elseif isfield(args{i}, 'mutuallyExclusiveGroup')
        for j=1:numel(args{i}.mutuallyExclusiveGroup)
            N = findName(name, args{i}.mutuallyExclusiveGroup{j});
            if ~isempty(N)
                return
            end
        end
    end
end

N = [];
end

% Checks for "inputs"

function [functionInfo, p, idx, s] = validateInputsOrOutputs(isInput, functionInfo, p, idx)

s = cell(0);
if ~strcmp(p(idx).name, 'leftSquareBrace')
    log(p(idx), "listExpected");
    idx = skipValue(p, idx);
    return
end

idx = idx+1;

while ~strcmp(p(idx).name, 'rightSquareBrace')
    [functionInfo, p, idx, d] = validateInputOrOutput(isInput, functionInfo, p, idx);
    s{end+1} = d;  %#ok<AGROW>
    if p(idx).name=="comma"
        idx = idx+1;
    end
end

crossInputsValidations = { ...
    @(s, idx) validateInputsNotUsedForIndexing(s)
    @(s, idx) validateInputsExpectedOrder(s)
    @(s, idx) validateInputsNameValueNotUsedInsideAndOutsideGroup(s)
    };

for i=1:numel(crossInputsValidations)
    crossInputsValidations{i}(s);
end

functionInfo = updateFunctionInfo(functionInfo, isInput, s);
idx = idx+1;

end

function functionInfo = updateFunctionInfo(functionInfo, isInput, s)
if isInput
    field = 'inputArgs';
else
    field = 'outputArgs';
end
if isKey(functionInfo.m, functionInfo.name.token)
    theStruct = functionInfo.m(functionInfo.name.token);
    if isfield(theStruct, field)
        theStruct.(field) = [functionInfo.m(functionInfo.name.token).(field) s];
    else
        theStruct.(field) = s;
    end
else
    theStruct = struct;
    theStruct.functionInfo = functionInfo.name;
    theStruct.(field) = s;
end
functionInfo.m(functionInfo.name.token) = theStruct;
end

function validateInputsNotUsedForIndexing(s)
for i=1:numel(s)
    if isfield(s{i}, "name")
        for j=i:numel(s)
            if isfield(s{j}, "type") && isvarname(s{i}.name(1).token)
                match = findTypeWithRegexp(s{j}.type, ['^choices.*\W' s{i}.name(1).token '\(']);
                if ~isempty(match)
                    log(match, "argumentIsIndexed", s{i}.name(1).token, match.token);
                end
            end
        end
    end
end
end

function validateInputsExpectedOrder(s)
foundNamedArg  = false;
foundSeparator = false;

for i=1:numel(s)

    if isempty(s{i})
        continue
    elseif isfield(s{i}, 'kind')
        k = s{i}.kind(1).token;
        f = s{i}.kind(1);
    elseif isfield(s{i}, 'mutuallyExclusiveGroup') || isfield(s{i}, 'tuple')
        continue
    else
        k = 'required';
        names = fieldnames(s{i});
        f = s{i}.(names{1});
    end

    switch k
        case {'required', 'ordered', 'positional'}

            if foundNamedArg
                log(f, "notAfterNameValueOrFlag", k);
            end

            if foundSeparator
                log(f, "notAfterSeparator", k);
            end

        case {'namevalue', 'flag'}
            foundNamedArg = true;

        case {'varargin', 'properties'}
            if i ~= numel(s)
                log(f, "propertiesMustBeLast");
            end

        case 'separator'
            foundSeparator = true;

        otherwise
            log(f, "valueInvalid", 'kind', k);
    end
end
end

function validateInputsNameValueNotUsedInsideAndOutsideGroup(s)

[foundNameValue, foundFlag] = findNamesAndFlags(s);

for i=1:numel(s)

    if isempty(s{i})
        continue
    elseif isfield(s{i}, 'mutuallyExclusiveGroup')
        for j=1:numel(s{i}.mutuallyExclusiveGroup)
            [foundNameValueInGroup, foundFlagInGroup] = findNamesAndFlags(s{i}.mutuallyExclusiveGroup{j});
            if ~isempty(foundNameValue) && ~isempty(foundNameValueInGroup)
                log([foundNameValue foundNameValueInGroup], "MATLAB:TabCompletion:NamesAndGroupsMisuse")
            elseif ~isempty(foundFlag) && ~isempty(foundFlagInGroup)
                log([foundFlag foundFlagInGroup], "MATLAB:TabCompletion:FlagsAndGroupsMisuse")
            elseif ~isempty(foundFlag) && ~isempty(foundNameValueInGroup)
                log([foundFlag foundNameValueInGroup], "MATLAB:TabCompletion:FlagsAndNamesInGroupsMisuse")
            end
        end
    end
end
end

function [foundNameValue, foundFlag] = findNamesAndFlags(s)

foundFlag = [];
foundNameValue = [];

for i=1:numel(s)

    if isempty(s{i})
        continue
    elseif isfield(s{i}, 'kind')
        switch s{i}.kind(1).token
            case {'flag'}
                if isempty(foundFlag)
                    foundFlag = s{i}.kind(1);
                end
            case {'namevalue', 'properties'}
                if isempty(foundNameValue)
                    foundNameValue = s{i}.kind(1);
                end
        end
    end
end
end

function [functionInfo, p, idx, s] = validateInputOrOutput(isInput, functionInfo, p, idx)

if ~strcmp(p(idx).name, 'leftCurlyBrace')
    log(p(idx), "objectExpected");
    idx = skipValue(p, idx);
    s = struct([]);
    return;
end

nonTypeArgumentValidations = { ...
    @(p, idx) validateNotEmptyName(p, idx), ...
    @(p, idx) validateNotUsingPlatform(p, idx), ...
    @(p, idx) validatePlatforms(p, idx), ...
    @(p, idx) validateInputNotUsingTerminal(p, idx), ...
    @(p, idx) validateInputNotUsingSeparator(p, idx), ...
    @(p, idx) validateInputNotUsingMultiplicity(p, idx) ...
    @(p, idx) validateInputNotUsingVarargin(p, idx) ...
    @(p, idx) validateInputNotUsingOptional(p, idx) ...
    @(p, idx) validateOutputNotUsingKind(p, idx, isInput) ...
    };

idx = idx+1;
s = struct;
while ~strcmp(p(idx).name, 'rightCurlyBrace')

    if p(idx).name=="comma"
        idx = idx+1;
        continue;
    end

    done = false;
    for i=1:numel(nonTypeArgumentValidations)
        if done
            continue
        end

        [p, newIdx] = nonTypeArgumentValidations{i}(p, idx);

        if newIdx ~= idx
            idx = newIdx;
            done = true;
        end
    end

    if ~done
        [functionInfo, p, idx, s] = updateInputStruct(functionInfo, p, idx, s);
    end
end

if isfield(s, 'kind') || isfield(s, 'name')
    if isfield(s, 'type')
        validateInputType(isInput, s);
    end
elseif isfield(s, 'mutuallyExclusiveGroup') || isfield(s, 'tuple')
    % No (further) action
else
    log(p(idx), "requireInputAttributeMissing");
    s = struct([]);
end

idx = idx+1;
end

function [functionInfo, p, idx, s] = updateInputStruct(functionInfo, p, idx, s)
if isfield(s, p(idx).token)
    log(p(idx), "nameDuplicated", p(idx).token);
end

switch p(idx).token
    case {'name', 'kind', 'repeating', 'platforms', 'default', 'promotion', 'display', 'purpose', 'valueSummary', 'docLink'}
        if p(idx).token == "repeating"
            [p, newIdx] = validateExpectTrueFalse(p, idx+2);
        else
            [p, newIdx] = validateExpectString(p, idx+2);
        end

        if newIdx==idx+2
            s.(p(idx).token) = p(idx+2);
            idx = idx+3;
        else
            idx = newIdx;
        end
    case 'type'
        [p, idx, s] = updateInputStructWithType(p, idx, s);

    case 'mutuallyExclusiveGroup'
        [functionInfo, p, idx, megS] = validateMutuallyExclusiveGroup(functionInfo, p, idx+2);
        if ~isfield(s, 'mutuallyExclusiveGroup')
            s.mutuallyExclusiveGroup = megS;
        else
            s.mutuallyExclusiveGroup{end+1} = megS;
        end

    case 'tuple'
        [functionInfo, p, idx, tupleS] = validateInputsOrOutputs(true, functionInfo, p, idx+2);
        if ~isfield(s, 'tuple')
            s.tuple = {tupleS};
        else
            s.tuple{end+1} = tupleS;
        end

    case ','
        % No action

    otherwise
        log(p(idx), "nameInvalid", p(idx).token);
        idx = skipValue(p, idx+1);
end
end

function [p, idx, s] = updateInputStructWithType(p, idx, s)
e = findEndOfValue(p, idx, 2, "listsNestedTooDeeply");
idx = idx + 2;  % skip "name" and colon
s.type = p(idx:e);
idx = e+1;
end

function [functionInfo, p, idx, s] = validateMutuallyExclusiveGroup(functionInfo, p, idx)
s = cell(0);
if ~strcmp(p(idx).name, 'leftSquareBrace')
    log(p(idx), "listExpected");
    idx = skipValue(p, idx);
    return
end
idx = idx+1;

while p(idx).name~="rightSquareBrace"
    switch p(idx).name
        case 'leftSquareBrace'
            [functionInfo, p, idx, s{end+1}] = validateInputsOrOutputs(true, functionInfo, p, idx); %#ok<AGROW>
        case 'leftCurlyBrace'
            [functionInfo, p, idx, s{end+1}] = validateInputOrOutput(true, functionInfo, p, idx); %#ok<AGROW>
            s{end} = s(end);
            functionInfo = updateFunctionInfo(functionInfo, true, s{end});
        case 'comma'
            idx = idx+1;
        otherwise
            log(p(idx), "objectOrListExpected");
            idx = skipValue(p, idx);
    end
end

idx = idx+1;

end

function [p, idx] = validateInputNotUsingSeparator(p, idx)
if p(idx).token=="kind" && p(idx+2).token=="separator"
    log(p(idx:idx+3), "separatorRemoved");
end
end

function [p, idx] = validateInputNotUsingVarargin(p, idx)
if p(idx).token=="kind" && p(idx+2).token=="varargin"
    log(p(idx+2), "nameRenamed", "varargin", "properties");
    p(idx+2).token='properties';
end
end

function [p, idx] = validateInputNotUsingOptional(p, idx)
if p(idx).token=="kind" && p(idx+2).token=="optional"
    log(p(idx+2), "nameRenamed", "optional", "ordered");
    p(idx+2).token='ordered';
end
end

function [p, idx] = validateInputNotUsingTerminal(p, idx)
if p(idx).token == "terminal"
    log(p(idx), "nameRemoved", "terminal");
    idx = skipValue(p, idx+1);
end
end

function [p, idx] = validateInputNotUsingMultiplicity(p, idx)
if strcmp(p(idx).token, 'multiplicity')
    log(p(idx), "multiplicityReplaced");
    p(idx).token = 'repeating';

    switch p(idx+2).token
        case 'error'
            p(idx+2).name = 'false';
            p(idx+2).token = 'false';
        case {'append', 'replace'}
            p(idx+2).name = 'true';
            p(idx+2).token = 'true';
        otherwise
            log(p(idx+2), "valueInvalid", 'multiplicity', p(idx+2).token);
            p(idx+2).name = 'true';
            p(idx+2).token = 'true';
    end
end
end

function [p, idx] = validateOutputNotUsingKind(p, idx, isInput)
if ~isInput && p(idx).token=="kind"
    log(p(idx), "doNotSpecifyKindForOutputs");
end
end

% Input type

function validateInputType(isInput, s)

typeArgumentValidations = { ...
    @(p, idx, ~) validateNotEmptyListComponent(p, idx), ...
    @(p, idx, ~) validateInputTypeIsKnownClassOrAttribute(p, idx) ...
    @(p, idx, ~) validateInputTypeNotUsingPathAttributes(p, idx), ...
    @(p, idx, ~) validateInputTypeNotUsingHandleAvailableAsTypeName(p, idx), ...
    @(p, idx, ~) validateInputTypeHasValidFilenameWildcards(p, idx) ...
    @(p, idx, ~) validateOutputNotUsingNumeric(p, idx, isInput) ...
    };

typeArgumentValidations = [typeArgumentValidations, validateFunctionSignaturesJSON_privateTypeArgumentValidations()];

for i = 1:numel(s.type)
    p = s.type(i);
    idx = 1;

    switch p.name
        case {'comma', 'leftSquareBrace', 'rightSquareBrace'}
            % No action
        case 'string'

            done = false;
            for j=1:numel(typeArgumentValidations)
                if done
                    continue
                end

                [p, newIdx] = typeArgumentValidations{j}(p, idx, @log);

                if newIdx ~= idx
                    idx = newIdx;
                    done = true;
                end
            end

        otherwise
            validateExpectString(p, idx);
    end
end
end

function [p, idx] = validateNotEmptyListComponent(p, idx)
if isempty(p(idx).token)
    log(p(idx), "emptyString");
    idx = idx+1;
end
end

function [p, idx] = validateInputTypeNotUsingPathAttributes(p, idx)
if p.token=="filepath" || startsWith(p.token, 'filepath=')
    log(p, "nameRenamed", "filepath", "file");
    p.token = replace(p.token, 'filepath', 'file');
end
if p.token=="folderpath"
    log(p, "nameRenamed", "folderpath", "folder");
    p.token = replace(p.token, 'folderpath', 'folder');
end
if startsWith(p.token, 'matlabpath=')
    log(p, "nameRenamed", "matlabpath", "matlabpathfile");
    p.token = replace(p.token, 'matlabpath', 'matlabpathfile');
end
if startsWith(p.token, 'graphpath=')
    log(p, "nameRenamed", "graphpath", "hierarchy");
    p.token = replace(p.token, 'graphpath', 'hierarchy');
end
end

function [p, idx] = validateInputTypeNotUsingHandleAvailableAsTypeName(p, idx)
if startsWith(p.token, '@')
    str = regexprep(p.token, ' ', '');
    match = regexp(str, '@\((\w+)\)isa\((\w+),''([\w\.]+)''\)$', 'tokens');
    if ~isempty(match)
        if strcmp(match{1}{1}, match{1}{2})
            log(p, "functionHandleCanBeAvoided", p.token, match{1}{3});
            p.token = match{1}{3};
        end
    end
end
end

function [p, idx] = validateInputTypeHasValidFilenameWildcards(p, idx)
arg = p.token;
if startsWith(arg, 'file=') || startsWith(arg, 'matlabpathfile=')
    match = regexp(arg, '^(file|matlabpathfile)\s*=\s*\*\.[\w\+]+(\s*,\s*\*\.[\w\+]+)*\s*$', 'once');
    if isempty(match)
        if ~isempty(regexp(arg, '^file\s*=\s*\*(\.\*)?\s*$', 'once'))
            log(p, "fileDoesNotNeedWildcard");
        else
            log(p, "fileWildcardFormatInvalid");
        end
    end
end
end

function [p, idx] = validateInputTypeIsKnownClassOrAttribute(p, idx)
type = p.token;
if type(1)=='~'
    type = type(2:end);
end
pats = ["choices\s*=", "file$", "file\s*=", "folder$", "matlabpathfile\s*=", "hierarchy\s*=", "filepath$", "filepath\s*=", ...
    "folderpath$", "matlabpath\s*=", "graphpath\s*=", "identifier\s*=", "numel\s*=", "nrows\s*=", "ncols\s*=", ...
    "logical$", "size\s*=", "real$", "scalar$", "integer$", "square$", "vector$", "column$", "row$", "2d$", ...
    "3d$", "sparse$", "positive$", "<=", ">=", "<", ">", "@", "numeric$", "cellstr$", "inferredFrom\s*=", ...
    "fromPrototypeOrClassname$", "struct\s*:", "cell\s*:"];
pat = "^(" + join(pats, "|") + ")";
extents = regexp(type, pat, 'once', 'tokenExtents');
matchingAttribute = ~isempty(extents);

if matchingAttribute
    attribute = type(extents(1):extents(2));
    attribute = replace(attribute, ' ', '');
    attributeValue = type(extents(2)+1:end);
    if ~isempty(attributeValue) && attributeValue(1)=='='
        pEq = p;
        pEq.cols(1) = p.cols(1)+strlength(attribute);
        pEq.cols(2) = pEq.cols(1)+1;
        log(pEq, "equalExpectedInsteadOfEqualEqual");
    end
    p.token = [attribute attributeValue];
else
    matchingClass = isempty(regexp(type, '[^\w\.]+', 'once')) && ...
        (~isempty(meta.class.fromName(type)) || ~isempty(which(type)));
end

if ~matchingAttribute && ~matchingClass
    log(p, "attributeOrClassUnknown", type);
end

end

function [p, idx] = validateOutputNotUsingNumeric(p, idx, isInput)
if ~isInput && strcmp(p.token, "numeric")
    log(p, "doNotUseNumericInOutputs");
end
end

function validateFilenameNoShadowing(filename)
% Resolve to full path
dirResults = dir(filename);
parentFolder = dirResults(1).folder;
[~, name, ext] = fileparts(filename);
fullFilename = strcat(name, ext);

if endsWith(parentFolder,"resources")
    resourcesLocation = fullfile(parentFolder, fullFilename);
    shadowedLocation = fullfile(fileparts(parentFolder), fullFilename);
else
    resourcesLocation = fullfile(parentFolder, 'resources', fullFilename);
    shadowedLocation = fullfile(parentFolder, fullFilename);
end

if isfile(resourcesLocation) && isfile(shadowedLocation)
    p = newToken(string(filename), "", "", 1, [1 1]);
    log(p,'jsonShadowed', shadowedLocation, resourcesLocation );
end
end

function validateFilenameNotInPackageOrClassFolder(filename)
dirResults = dir(filename);
folders = split(dirResults(1).folder, filesep);
if folders{end}=="resources"
    folders = folders(1:end-1);
end
packageOrClass = startsWith(folders{end}, '+') | startsWith(folders{end}, '@');
if any(packageOrClass)
    p = newToken(string(filename), "", "", 1, [1 1]);
    log(p,'fileInClassOrPackageFolder', fullfile(dirResults(1).folder, dirResults(1).name));
end
end

% Helpers

function idx = skipValue(p, idx)
if p(idx).name == "colon"
    idx = idx + 1;
end

depth = 0;
done = false;
while ~done
    switch p(idx).name
        case {'leftSquareBrace', 'leftCurlyBrace'}
            depth = depth + 1;
        case {'rightSquareBrace', 'rightCurlyBrace'}
            depth = depth - 1;
        otherwise
            % No action
    end
    if depth==0
        done = true;
    end
    idx = idx + 1;
end
end

function match = findTypeWithRegexp(type, exp)
match = struct([]);
for i=1:numel(type)
    if type(i).name == "string"
        if ~isempty(regexp(type(i).token, exp, 'once'))
            match = type(i);
            break;
        end
    end
end
end

function out = log(p, msgId, varargin)
persistent validateFunctionSignaturesReport

if nargin==0
    out = validateFunctionSignaturesReport;
elseif isempty(p) && isnumeric(p)
    validateFunctionSignaturesReport = table(strings(0), [], zeros(0,2), strings(0), strings(0), ...
        'VariableNames', {'Filename', 'LineNumber', 'ColumnExtents', 'MessageId', 'Message'});
else
    if ~contains(msgId, ':')
        msgId = "MATLAB:validateFunctionSignaturesJSON:"+msgId;
    end
    msg = message(msgId, varargin{:});

    if p(1).line ~= p(end).line || string(p(1).file) ~= string(p(end).file)
        p = p(end);  % Don't allow a message to span lines (or, by extension, files).
    end

    validateFunctionSignaturesReport = [validateFunctionSignaturesReport; ...
        {string(p(1).file), p(1).line, [p(1).cols(1) p(end).cols(2)], msgId, string(msg)}];
end

end

function s = tokenJSON(filename, txt)
% Assemble the regular expression
re = strings(0);
re(end+1) = '?<string>"([^"\\]|\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4})*?"';
re(end+1) = "?<number>\-?(0|[1-9][0-9]*)(\.[0-9]+)?([Ee][+\-]?[0-9]+)?";
re(end+1) = "?<comma>,";
re(end+1) = "?<colon>:";
re(end+1) = "?<leftSquareBrace>\[";
re(end+1) = "?<rightSquareBrace>\]";
re(end+1) = "?<leftCurlyBrace>\{";
re(end+1) = "?<rightCurlyBrace>\}";
re(end+1) = "?<true>true";
re(end+1) = "?<false>false";
re(end+1) = "?<null>null";
re = "(" + join(re, ")|(") + ")";
[names, extents]=regexp(txt, re, "names", "tokenExtents");

% Convert file offsets to line/column number
endOfLines = find(char(txt)==newline);
s = repmat(newToken(filename, '', '', nan, []), size(names));
for i=1:numel(names)
    fields = fieldnames(names(i));
    for j=1:numel(fields)
        if ~isempty(names(i).(fields{j}))
            [line,cols] = idx2lineColumn(extents{i}, endOfLines);
            s(i).name = fields{j};
            s(i).token = names(i).(fields{j});
            s(i).line = line;
            s(i).cols = cols;
            if strcmp(s(i).name, 'string')
                s(i).token = jsondecode(s(i).token);
            end
        end
    end
end
end

function tf = isLiveTaskFile(filename)
[~, stem] = fileparts(filename);
tf = startsWith(stem, 'liveTasks');
end

function filename = checkResourcesFolder(filename)
[parentFolder, name, ext] = fileparts(char(filename));
fullFilename = strcat(name,ext);

resourcesLocation = fullfile(parentFolder, 'resources', fullFilename);
if strlength(parentFolder) == 0 && isfile(resourcesLocation)
    filename = resourcesLocation;
end
end

function text = readUTF8(filename)
if isempty(filename)
    throw(MException(message("MATLAB:validateFunctionSignaturesJSON:emptyFileName")));
elseif isempty(fileparts(filename))
    filename = fullfile('.', filename);  % Avoid opening a file on the path
end
fileId = fopen(char(filename),'rt','n','utf-8');
if fileId < 0
    throw(MException(message("MATLAB:validateFunctionSignaturesJSON:cannotOpenFile", filename)));
end
validateFilenameNoShadowing(filename);
validateFilenameNotInPackageOrClassFolder(filename);
text = string(fread(fileId,'*char')');
fclose(fileId);
end

function [line, cols] = idx2lineColumn(indexes, endOfLines)
index = find(endOfLines < indexes(1), 1, 'last');
if isempty(index)
    line = 1;
    cols = indexes;
else
    line = index+1;
    cols = indexes-endOfLines(index);
end
end

function s = newToken(filename, name, token, line, cols)
s = struct('file', filename, 'name', name, 'token', token, 'line', line, 'cols', cols);
end

%LocalWords: subfolder
