function T = collectTableOutput(T)
%

% Copyright 2019 MathWork, Inc.
types = getTypes(T);
typeBlock = 1;
blockRanges = {1};

for i = 2:numel(types)
    type = types{i};
    
    if types(typeBlock) == type
        blockRanges{end} = [blockRanges{end} i];
    else
        if numel(blockRanges{end})==1
            blockRanges(end) = [];
        end
        typeBlock = i;
        blockRanges(end+1)={i}; %#ok<AGROW>
    end
end

if numel(blockRanges{end})==1
    blockRanges(end) = [];
end

for blck = blockRanges(end:-1:1)
    blockIDs = blck{1};
    if ~any(strcmp(types(blockIDs(1)),["datetime","duration","categorical"]))
        name = string(join(T.Properties.VariableNames(blockIDs),'_'));
        name = extractBefore(name,min(strlength(name)+1,64));
        T = mergevars(T,blockIDs,'NewVariableName',name);
    end
end
end

function [types] = getTypes(T)
types = strings(1,width(T));
for i = 1:numel(types)
    types{i} = class(T.(i));
end
end


