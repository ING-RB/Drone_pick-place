function ret = fullfile_vfileparttail(parts)
%

%   Copyright 2015-2020 The MathWorks, Inc.

    try
        parts = cellfun(@(x) char(x), parts, 'UniformOutput', false);
        ret  = struct('name',{},'separator',{},'isleaf',{});
        inputBeingTyped = parts{end};
        parts = parts(1:end-1);
    
        lastSep = find(inputBeingTyped==filesep, 1, 'last');
        
        if ispc
            altLastSep = find(inputBeingTyped=='/', 1, 'last');
            if isempty(lastSep) || (~isempty(altLastSep) && altLastSep > lastSep)
                lastSep = altLastSep;
            end
        end
        
        if ~isempty(lastSep)
            typedPath = inputBeingTyped(1:lastSep);
            typedName = inputBeingTyped(lastSep+1:end);
            separator = inputBeingTyped(lastSep);
        else
            typedPath = '';
            typedName = inputBeingTyped;
            separator = '/';
        end

        ff = fullfile(parts{:}, [typedPath '*']);
        files = dir(ff);
        inputLength = strlength(typedName);
        for i = 1:numel(files)
            if files(i).name(1) == '.'
                continue;
            end

            name = files(i).name;
            if inputLength >= 3
                addMatch = contains(name, typedName, 'IgnoreCase', true);
            else
                addMatch = startsWith(name, typedName, 'IgnoreCase', true);
            end
            
            if addMatch  
                ret(end+1) = struct('name', name, 'separator', separator, 'isleaf', ~files(i).isdir); %#ok<AGROW>
            end
        end
    catch
        ret  = struct('name',{},'separator',{},'isleaf',{});
    end
    
end

