function namespacePrefixes = getNamespacePrefixes(variableNames, nvPairs, rowDimensionName)
%

%   Copyright 2020 The MathWorks, Inc.

namespacePrefixes = strings(0, 0);

% For TableNodeName, RowNodeName, and VariableNames, check for ':',
% indicating presence of a namespace prefix.

% TableNodeName
namespacePrefixes = appendPrefix(nvPairs.TableNodeName, namespacePrefixes);

% Only check for prefixes in the RowDimensionName if the row names will be
% written to the output file.
if nvPairs.WriteRowNames
   namespacePrefixes = appendPrefix(rowDimensionName, namespacePrefixes); 
end

% RowNodeName
namespacePrefixes = appendPrefix(nvPairs.RowNodeName, namespacePrefixes);

% VariableNames
for i = 1:length(variableNames)
    namespacePrefixes = appendPrefix(variableNames(i), namespacePrefixes);
end

namespacePrefixes = unique(namespacePrefixes, 'stable');

end

function prefixes = appendPrefix(name, prefixes)
    name = string(name);
    prefix = extractBefore(name, ":");
    if ~ismissing(prefix) && ... % a prefix exists
        strlength(extractAfter(name, ":")) > 0 && ... % there is a local name after the prefix
        ~(strcmp(prefix, "xml") || strcmp(prefix, "xmlns")) % the prefix is not one of the two reserved prefixes
       prefixes = [prefixes, prefix];
    end
end