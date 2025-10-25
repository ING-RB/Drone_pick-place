%   Copyright 2024 The MathWorks, Inc.

function modifyOutgoingSerializationContent(sObj, repo, ~)

    % If the object to serialize is on the repo list, save the dependent name
    onListRepositories = mpmListRepositories();
    if ~isempty(onListRepositories)
        [inList, i] = ismember(repo.Location, [onListRepositories.Location]);
        if inList
            sObj.addNameValue("Name", onListRepositories(i).Name);
        end
    end

end