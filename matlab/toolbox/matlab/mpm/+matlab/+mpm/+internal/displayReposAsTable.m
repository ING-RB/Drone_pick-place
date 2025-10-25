function displayReposAsTable(repos)
    if isempty(repos)
        return
    end

    toDisplay = table.empty(numel(repos), 0);
    for property = ["Name", "Location"]
        toDisplay = addvars(toDisplay, [repos.(property)]', NewVariableNames=property);
    end
    disp(toDisplay);
end