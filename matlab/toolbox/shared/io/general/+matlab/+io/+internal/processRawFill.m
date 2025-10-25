function [fill,varData] = processRawFill(fill,varData)
% Process Raw FillValues into output type.

% Copyright 2019 MathWorks, Inc.
if isnumeric(varData) && isempty(fill)
    fill = NaN;
end

if iscell(varData)
    if isnumeric(fill)
        fill = '';
    end
    fill = {fill};
end

if isstring(varData)
    if isempty(fill)
       fill = "";
    end
    fill = string(fill);
end

if isdatetime(varData) && isnumeric(fill)
    if numel(fill) == 2
        fill = complex(fill(1),fill(2));
    end
    fill = datetime.fromMillis(fill);
end

if isduration(varData) && isnumeric(fill)
    fill = milliseconds(fill);
end

if iscategorical(varData)
    % Combine the categories of the fill value with the
    if isempty(fill)
        fill = categorical(missing);
    end
    if ~iscategorical(fill)
        if ischar(fill)
            fill = {fill};
        end
        fill = categorical(fill);
    end
    % data array.
    cats = union(categories(varData),categories(fill),'stable');
    
    % If ordinal, both data and array need to have the
    % same categories in the same order, so reacreate
    % both with matching properties
    fill = categorical(fill,cats,...
        'Ordinal',isordinal(varData),...
        'Protected',isprotected(varData));
    varData = categorical(varData,cats,...
        'Ordinal',isordinal(varData),...
        'Protected',isprotected(varData));
    
end

end

