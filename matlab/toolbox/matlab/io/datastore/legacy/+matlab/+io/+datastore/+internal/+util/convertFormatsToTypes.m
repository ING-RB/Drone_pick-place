function types = convertFormatsToTypes(formats, textType)
%CONVERTFORMATSTOTYPES   Convert from format strings to data types
%   TYPES = CONVERTFORMATSTOTYPES(FORMATS, TEXTTYPE) is a cell array of
%   data types corresponding to the input format strings. TEXTTYPE
%   determines the output data type of text, either 'char' or 'string'.

%   Copyright 2019 The MathWorks, Inc.

types = cell(1,numel(formats));
% remove the specific datetime and duration formats and keep the generic
% parts only
for ii = 1 : numel(formats)
    formats{ii} = strrep(formats{ii},'%*','%');
    if startsWith(formats{ii},"%{") && endsWith(formats{ii},"}D")
        % dates and time
        formats{ii} = '%D';
    elseif startsWith(formats{ii},"%{") && endsWith(formats{ii},"}T")
        % duration
        formats{ii} = '%T';
    end
end

stateNat = warning("off",'MATLAB:textscan:AllNatSuggestFormat');
stateNaN = warning("off", 'MATLAB:textscan:AllNaNDurationSuggestFormat');
state = [stateNat, stateNaN];
[msg,id] = lastwarn();

typesCells = textscan(char(0),strjoin(formats,''),"TextType",textType);
lastwarn(msg,id);
warning(state);

for ii = 1 : numel(typesCells)
    types{ii} = class(typesCells{ii});
end
end
