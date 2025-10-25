function foundWithImport = iterateOverImports(resolveFcn, imports, topic, isCaseSensitive)
    foundWithImport = false;
    
    firstName = regexp(topic, '\w+', 'match', 'once');
    for i = 1:numel(imports)
        thisImport = imports{i};
        if endsWith(thisImport, '*')
            foundWithImport = resolveFcn(replace(thisImport, '*', topic));
        else
            names = regexp(thisImport, '^(?<qualifiers>.*\.)?(?<lastItem>.*)$', 'names');
            if matlab.lang.internal.introspective.casedStrCmp(isCaseSensitive, firstName, names.lastItem)
                foundWithImport = resolveFcn(append(names.qualifiers, topic));
            end
        end

        if foundWithImport
            return;
        end
    end
end

%   Copyright 2019-2024 The MathWorks, Inc.
