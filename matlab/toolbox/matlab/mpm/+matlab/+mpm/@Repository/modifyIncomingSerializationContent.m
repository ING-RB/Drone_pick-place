%   Copyright 2024 The MathWorks, Inc.
function modifyIncomingSerializationContent(sObj)

    onListRepositories = mpmListRepositories();
    if sObj.hasNameValue("Name") && ~isempty(onListRepositories)
        % Try matching by name
        [inList, i] = ismember(sObj.Name, [onListRepositories.Name]);
        if inList
            % Found a matching name; replace object
            sObj.Location = onListRepositories(i).Location;
            sObj.Name = onListRepositories(i).Name;
            return;
        end
    end

    % Incoming repo will not have a name match
    % Remove name attribute to prevent accidental renaming
    if sObj.hasNameValue("Name")
        sObj.remove("Name")
    end

end