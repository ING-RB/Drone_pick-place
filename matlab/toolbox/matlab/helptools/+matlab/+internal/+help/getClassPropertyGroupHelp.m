function helpStr = getClassPropertyGroupHelp(refItem, wantHyperlinks, prefix)
    helpStr = "";

    classPropertyGroups = refItem.ClassPropertyGroups;
    if ~isempty(classPropertyGroups)
        if wantHyperlinks
            helpLocation = fullfile(docroot, refItem.HelpLocation);
        else
            helpLocation = "";
        end

        header = getString(message("MATLAB:introspective:helpParts:ClassProperties"));
        propertiesHeader = prefix + header + newline;

        if classPropertyGroups(1).Title ~= ""
            prefix = prefix + indent(.5);
        end

        propertyGroupStrings = strings(size(classPropertyGroups));
        for j = 1:numel(classPropertyGroups)
            classProperties = classPropertyGroups(j).ClassProperties;
            propertyStrings = strings(size(classProperties));
            for i = 1:numel(classProperties)
                propertyStrings(i) = makeValueString(classProperties(i), helpLocation, prefix);
            end
            propertiesString = join(propertyStrings, newline);

            if classPropertyGroups(j).Title ~= ""
                propertiesString = prefix + classPropertyGroups(j).Title + newline + propertiesString;
            end

            propertyGroupStrings(j) = propertiesString + newline;
        end

        helpStr = newline + propertiesHeader + join(propertyGroupStrings, newline);
    end
end

%   Copyright 2022-2023 The MathWorks, Inc.
