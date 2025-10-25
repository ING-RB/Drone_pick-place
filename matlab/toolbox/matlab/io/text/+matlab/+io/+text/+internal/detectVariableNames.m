
function readVarNames = detectVariableNames(format,vnline,delimiter,whitespace,eol,otherArgs,warningOn)
% determine whether or not a line should be treated as Variable Names or data based on the format and other parameters

%   Copyright 2015-2022 The MathWorks, Inc.

% for function call from TabularTextDatastore, keep the warning state
% turned on so we can prompt ambiguous datetime entries at datastore
% construction time.

% save the warning state so that it can reverted back to original state
state = warning;
if nargin == 7 && warningOn
    warning('on');
else
    warning('off');
end
readVarNames = getLines(vnline,format,delimiter,whitespace,eol,otherArgs);
warning(state);
end

function readVarNames = getLines(vnline,format,delimiter,whitespace,eol,otherArgs)
try
    readVarNames = true;
    % if the first line of the file can be parsed with
    % the detected format, then don't read var names.
    [data,pos] = textscan(vnline,format,...
        'Delimiter',delimiter,...
        'WhiteSpace',whitespace,...
        'EndOfLine',eol,...
        otherArgs{:});

    if pos ~= numel(vnline)
        % If the first line ended early, there was an error in the read.
        % Nothing more to check.
        return
    end
    
    % If the line is strictly delimited, then we can find empty fields.
    [D,pos] = textscan(vnline,'%q',numel(data),...
        'Delimiter',delimiter,...
        'WhiteSpace',whitespace,...
        'EndOfLine',eol,...
        otherArgs{:});
    
    if(pos == numel(vnline))
        % The first row must either be a text field, or blank. if a
        % non-text field that is not blank parsed
        % successfuly with the format in the first line, then we
        % shouldn't use the first line as variable names
        if (numel(D{1}) < find(~cellfun(@isempty,data),1,'last'))
            % This can only happen with a field like "3a" which was parsed as
            % {3,'a'} with the format containing %f%q, but '3a' with %q
            readVarNames = false;
            return
        end

        isNonBlank = find(strlength(D{1})~=0);
        N = numel(isNonBlank);
        k = 1;
        % If we find a field which was not blank, or not text that parsed
        % succesfully in data, then stop.
        while readVarNames && k <= N
            idx = isNonBlank(k);
            readVarNames = iscell(data{idx})||isstring(data{idx});
            k = k+1;
        end
    end
catch % ignore any errors and readVarNames by default.
end
end
