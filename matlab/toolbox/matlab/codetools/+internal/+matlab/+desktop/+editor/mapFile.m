function filename = unmapFile(filename)
    % unmapFile Reverses any mapping that MATLAB Editor might have applied
    %
    % Returns the corresponding file from the first directory in which
    % it exist amongst the list of alternate MATLAB code trees.  This
    % function is a pass-through if MW_DEBUG_SYMBOL_PATH is not set or
    % if no match is found.
    %

    symbolPath = getenv('MW_DEBUG_SYMBOL_PATH');

    if ispc
        symbolPath = strrep(symbolPath, '/', filesep);
    end

    if isempty(symbolPath)
        return;
    end

    if ~startsWith(filename, matlabroot)
        return
    end

    pathRelativeToMatlabRoot = filename(length(matlabroot) + 1:end);
    
    for newPath = regexp(symbolPath, pathsep, 'split')
        newPath = strrep(newPath{1},'//','/');     %#ok<FXSET> % Only needed on UNIX
        pathToCheck = fullfile(newPath, pathRelativeToMatlabRoot);
        if exist(pathToCheck, 'file') ~= 0
            filename = pathToCheck;
            return;
        end
    end
end

