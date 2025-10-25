function functionName = extractFunctionNameFromNameSpace(functionFullyQualifiedName)
    namespaceParts = split(functionFullyQualifiedName, '.');
    functionName = namespaceParts(end);
end