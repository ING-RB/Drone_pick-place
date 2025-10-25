function format = determineFormatString(dataLine, delimiter, whiteSpace, eol, ...
    treatAsEmpty, varTypes, datetimeType, durationType, dtLocale, ...
    ambiguousFormatFlag, otherArgs, format)
% DETERMINEFORMATSTRING Decide the format string from the data line.
%
% If format is not specified, it is initialized, otherwise, it is updated.
%
% User-supplied format must be a concatenation of '%f' and '%q'

%   Copyright 2012-2022 The MathWorks, Inc.

% otherArgs is an empty cell for readtable and contains additional textscan
% arguments
if ~exist('otherArgs','var')
    otherArgs = {};
end

% check if MultipleDelimsAsOne is supplied
multiDelim = {};
if ~isempty(otherArgs)
    idx = find(strcmp(otherArgs,'MultipleDelimsAsOne'));
    if ~isempty(idx)
        multiDelim = otherArgs{idx+1};
    end
end

% remove any delimiters from inside of quoted strings.
dataLine = matlab.io.text.internal.removeDelimsFromQuotedFields(dataLine, ...
    delimiter,sprintf(whiteSpace),eol,treatAsEmpty);

% add an extra char(0) at the end of the input if there is a delimiter
% without any data after the delimiter
trailingBlankOrDelim = 0;
if double(dataLine(end)) == 32
    trailingBlankOrDelim = 1;
elseif iscellstr(delimiter) || isstring(delimiter)
    trailingBlankOrDelim = any(cellfun(@(delimiter)strcmp(dataLine(end-size(delimiter,2)+1:end),delimiter),delimiter));
end
if trailingBlankOrDelim
    dataLine = [dataLine, char(0)];
end

% remove empty delimiters before splitting
if iscellstr(delimiter) || isstring(delimiter)
    emptyDelim = cellfun(@isempty,delimiter);
    if any(emptyDelim)
        delimiter(emptyDelim) = [];
    end
end
% tokenize the input string
if ~isempty(delimiter)
    splits = split(dataLine,delimiter);
else
    splits = {dataLine};
end

% datetimeType determines output type of datetime variables
if datetimeType == "text"
    varTypes(varTypes=="datetime") = {'char'};
end
if durationType == "text"
    varTypes(varTypes=="duration") = {'char'};
end

formatFlag = exist('format','var');
if ~formatFlag
    % initialize format string with types supplied by detectFormatOptions
    format = varTypes;
end

numSplits = numel(splits);
% if there are fewer splits than datatypes returned by detectFormatOptions,
% discard the extra datatypes
if numSplits < numel(varTypes)
    format = format(1:numSplits);
end

jj = 1; % separate counter for varTypes
% check that the datatypes supplied by detectFormatOptions are correct
for ii = 1 : numSplits
    if formatFlag && 2*jj <= numel(format) && format(2*jj) == 'q'
        % when format is passed as input, dont overwrite %q since that was
        % detected as char in earlier iteration
        if ~isempty(splits{ii})
            jj = jj + 1;
        elseif (isempty(splits{ii}) && numSplits ==  length(varTypes))
            jj = jj + 1;
        end
        continue;
    end
    if isempty(splits{ii})
        % check if MultipleDelimsAsOne was specified, if yes remove this
        % split from consideration
        if ~isempty(multiDelim) && multiDelim
            continue;
        else
            if numel(varTypes) >= jj && any(strcmp(varTypes{jj},{'datetime','duration'}))
                if ~formatFlag
                    format{jj} = '%q';
                else
                    format(2*jj) = 'q';
                end
            elseif numel(varTypes) < jj
                format = callConvertDataTypeToFormatString('char', formatFlag, format, jj);
            else
                format = callConvertDataTypeToFormatString(varTypes{jj}, formatFlag, format, jj);
            end
        end
    elseif trailingBlankOrDelim && ii == numSplits
        % use the format returned from detectImportOptions if possible,
        % otherwise revert to using char
        if numel(varTypes) >= jj
            format = callConvertDataTypeToFormatString(varTypes{jj}, formatFlag, format, jj);
        else
            format = callConvertDataTypeToFormatString('char', formatFlag, format, jj);
        end
    elseif jj <= numel(varTypes)
        switch varTypes{jj}
            case 'double'
                % check for quoted numbers
                if contains(splits{ii},'"')
                    varTypes{jj} = 'char';
                else
                    varTypes{jj} = textscanForNumeric(splits{ii}, delimiter, ...
                        treatAsEmpty, whiteSpace, eol, otherArgs);
                end
            case {'char','string'}
                % check for TreatAsEmpty
                if strcmp(strtrim(splits{ii}),'0') || strcmpi(splits{ii},'NaN')
                    varTypes{jj} = 'double';
                else
                    varTypes{jj} = textscanForNumeric(splits{ii}, delimiter, ...
                        treatAsEmpty, whiteSpace, eol, otherArgs);
                end
            case 'datetime'
                % check for ambiguous datetime formats
                if ambiguousFormatFlag
                    varTypes{jj} = ambiguousDates(splits{ii},dtLocale);
                end
            case 'duration'
                % check for wrongly constructed durations since datastore
                % does not skip metadata
                try
                    duration(splits{ii});
                catch
                    varTypes{jj} = 'char';
                end
        end
        format = callConvertDataTypeToFormatString(varTypes{jj}, formatFlag, format, jj);
    else
        format = callConvertDataTypeToFormatString(textscanForNumeric(splits{ii}, delimiter, ...
            treatAsEmpty, whiteSpace, eol, otherArgs), formatFlag, format, jj);
    end
    jj = jj + 1;
end

% detectImportOptions will return the wrong number of datatypes when
% MultipleDelimitersAsOne (or MultipleDelimsAsOne) is set
% remove the extra datatypes here
if ~formatFlag
    for kk = 1 : numel(format)
        if ~contains(format{kk},'%')
            format{kk} = [];
        end
    end
    format = format(~cellfun(@isempty, format));
    format = replace([format{:}],'*','');
end
end

function formatString = convertDatatypeToFormatString(varTypesThis)
if isempty(varTypesThis)
    formatString = '%q';
else
    switch varTypesThis
        case 'double'
            formatString = '%f';
        case {'char', 'string'}
            formatString = '%q';
        case 'datetime'
            formatString = '%D';
        case 'duration'
            formatString = '%T';
        case 'hexadecimal'
            formatString = '%x';
        case 'binary'
            formatString = '%b';
    end
end
if contains(varTypesThis,'D')
    formatString = varTypesThis;
end
end

function format = callConvertDataTypeToFormatString(varTypeThis, formatFlag, format, idx)
% depending on whether formats were passed in as input, it will either be cellstr or char vector
if ~formatFlag
    format{idx} = convertDatatypeToFormatString(varTypeThis);
else
    format(2*idx) = strrep(convertDatatypeToFormatString(varTypeThis),'%','');
end
end

function format = ambiguousDates(dataToken, dtLocale)
try
    dataToken = datetime(strtrim(strip(dataToken,'"')),'Format','preserveinput','Locale',dtLocale);
    format = ['%{' dataToken.Format '}D'];
catch ME
    if strcmp(ME.identifier,'MATLAB:datetime:UnrecognizedDateStringSuggestLocale') || ...
            strcmp(ME.identifier, 'MATLAB:datetime:UnrecognizedDateStringsSuggestLocale') || ...
            strcmp(ME.identifier, 'MATLAB:datetime:UnrecognizedDateStringWithLocale')
        format = 'char';
    end
end
end

function format = textscanForNumeric(splits, delimiter, treatAsEmpty, ...
    whiteSpace, eol, otherArgs)
format = '%*f';
curr_pos = 0;
try
    if ~isempty(treatAsEmpty)
        [~,pos] = textscan(splits, format, 1, 'Delimiter', ...
            delimiter, 'TreatAsEmpty', treatAsEmpty, otherArgs{:}, 'Whitespace', ...
            whiteSpace, 'EndOfLine', eol, 'NumCharactersToSkip', curr_pos);
    else
        [~,pos] = textscan(splits, format, 1, 'Delimiter', ...
            delimiter, otherArgs{:}, 'Whitespace', whiteSpace, ...
            'EndOfLine', eol, 'NumCharactersToSkip', curr_pos);
    end
    if pos < numel(splits)
        format = 'char';
    else
        format = 'double';
    end
catch
    % did not read anything, switch to %*q
    format = 'char';
end
end
