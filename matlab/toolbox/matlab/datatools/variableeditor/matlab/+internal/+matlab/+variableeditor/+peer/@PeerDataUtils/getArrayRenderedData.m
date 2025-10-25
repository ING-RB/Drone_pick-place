% getRenderedData returns a cell array of strings for the desired range of
% values

% Copyright 2017-2023 The MathWorks, Inc.

function [renderedData, renderedDims] = getArrayRenderedData(data)
    vals = cell(size(data,2),1);
    for column=1:size(data,2)
        r=evalc('disp(data(:,column))');
        if ~isempty(r)
            textformat = ['%s', '%*[\n]'];
            vals{column}=strtrim(textscan(r,textformat,'Delimiter',''));
        end
    end
    renderedData=[vals{:}];

    if ~isempty(renderedData)
        renderedData=[renderedData{:}];
    end

    renderedDims = size(renderedData);
end
