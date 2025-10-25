function [delimiter,headerlines,multipleDelimsAsOne,types] = detectParametersFromString(str,supplieddelim,suppliedheader,delimiter,headerlines,dtLocale,otherArgs)
% reads a string to determine Delimiter and HeaderLines and
% MultipleDelimsAsOne

% Copyright 2018-2022 MathWorks, Inc.

% initialize to default behavior.
multipleDelimsAsOne = false;

% Need to preserve the inputs in case detection
% fails to have the correct fallback

textSource = matlab.io.text.internal.TextSourceWrapper();
matlab.io.text.internal.openTextSourceFromString(textSource, str);

args = otherArgs;
if supplieddelim
    args = [{'Delimiter',delimiter},args];
else
    id = find(strcmp(args,'Delimiter'));
    args([id;id+1])=[];
end

if suppliedheader
    args = [{'NumHeaderLines',headerlines},args];
else
    id = find(strcmp(args,'NumHeaderLines')|strcmp(args,'HeaderLines'));
    args([id;id+1])=[];
end

endOfLine = find(strcmp('EndOfLine',args));
args(endOfLine)={'LineEnding'};
if ~isempty(endOfLine) && isempty(args{endOfLine+1})
    args([endOfLine;endOfLine+1]) = [];
end
if ~isempty(endOfLine) && strcmp(args{endOfLine+1}, '\r\n')
    args{endOfLine+1} = {'\r\n','\r','\n'};
end

args(strcmp('TreatAsEmpty',args))={'TreatAsMissing'};

% inspect the string contents
st = matlab.io.text.internal.detectFormatOptions(textSource, args{:}, 'DateLocale', dtLocale);

switch (st.Mode)
    case 'Delimited' 
        % use delimited with detected delimiter
        delimiter = st.Delimiter;
        headerlines = st.NumHeaderLines;
        ids = st.Types;

    case {'SpaceAligned','FixedWidth'}
        % use space + tab and multiple as one
        delimiter = num2cell(sprintf(' \t'));
        headerlines = st.NumHeaderLines;
        multipleDelimsAsOne = true;
        ids = st.Types;
    otherwise %case 'LineReader'
        % Do nothing--Detection failed. Use the fallback
        % defaults for detected parameters
        % (delimiter =','; headerlines = 0) 
        % Or in the case of partial detection (header
        % detection only) use the input parameter values.
        delimiter = {','};
        headerlines = 0;
        ids = st.Types;
        
end
ids(1:headerlines,:) = [];
tdto.EmptyColumnType = 'double';
tdto.DetectVariableNames =  true;
tdto.ReadVariableNames = true;
tdto.MetaRows = 0;
tdto.DetectMetaRows = true;
results = matlab.io.internal.detectTypes(ids,tdto);

types = results.Types;
end