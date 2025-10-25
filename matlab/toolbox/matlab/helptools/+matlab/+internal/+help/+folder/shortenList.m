function list = shortenList(dirInfos, topic)
    dirInfos = dirInfos(arrayfun(@(f)matlab.internal.help.folder.hasContents(f, CheckEmptyContents=true, IncludeDefaultContents=true), dirInfos));
    list = {dirInfos.path};
    tail = append(filesep, fullfile(topic));
    list = list(endsWith(list, tail,'IgnoreCase',true));
    list = unique(list, 'stable');
    if ~isempty(list)
        notUnique = 1:numel(list);
        while any(notUnique)
            tail = regexptranslate('escape', tail);
            minimalPath(notUnique) = regexpi(list(notUnique), "[^\" + filesep + "]*" + tail + "$", 'match', 'once'); %#ok<AGROW>
            [~, ix] = unique(minimalPath, 'stable');
            notUnique = setdiff(notUnique, ix);
            [~, notUnique] = ismember(minimalPath, minimalPath(notUnique));
            notUnique = find(notUnique);
            tail = append(filesep, minimalPath(notUnique));
        end
        list = minimalPath(cellfun(@isFolder, minimalPath));
    end
end

function b = isFolder(f)
    b = ~isempty(matlab.lang.internal.introspective.hashedDirInfo(f));
end

% Copyright 2018-2024 The MathWorks, Inc.
