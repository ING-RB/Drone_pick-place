function displayPackagesAsTable(pkgs, fields, variableTypes)
% displayPackagesAsTable Display packages as table

%   Copyright 2024 The MathWorks, Inc.

    arguments
        pkgs (1,:) matlab.mpm.Package
        fields(1, :) string = string.empty
        variableTypes(1, :) string = string.empty
    end

    numberOfPkgs = numel(pkgs);
    if(isempty(fields) && isempty(variableTypes))
        fields = ["Name", "Version", "Editable", "Repository", ...
            "InstalledAsDependency",  ...
            "Dependencies",  "MissingDependencies", "Summary"];
        variableTypes = ["string", "string", "logical", "string", ...
            "logical", "cell", "cell", "string"];
    end


    sz = [numberOfPkgs, numel(fields)];

    if numberOfPkgs == 0
        return
    end

    displayTable = table(Size=sz, VariableNames = fields, VariableTypes=variableTypes);

    for idx = 1:numel(pkgs)
        for j = 1:numel(fields)
            if(strcmp(fields(j), "Name"))
                displayTable{idx, fields{j}} = matlab.mpm.internal.packageDisplayName(pkgs(idx));
            elseif(strcmp(fields(j), "Dependencies") || strcmp(fields(j), "MissingDependencies"))
                displayTable{idx, fields{j}} = ...
                    {matlab.mpm.internal.getDependenciesDisplayString(pkgs(idx).(fields{j}))};
            elseif (strcmp(fields(j), "Repository"))
                %@todo(chiragg, 02/21) Fow now use displayString of
                %Repository but this may need an update when we can just
                %insert the matlab.mpm.Repository type in table
                if(~isempty(pkgs(idx).(fields{j})))
                    displayTable{idx, fields{j}} = displayString(pkgs(idx).(fields{j}));
                else
                    displayTable{idx, fields{j}} = missing;
                end
            else
                displayTable{idx, fields{j}} = pkgs(idx).(fields{j});
            end
        end
    end

    fprintf("\n");
    disp(displayTable);

end
