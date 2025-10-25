function b = hasContents(folderInfo, args)
    arguments
        folderInfo struct;
        args.CheckEmptyContents     = false;
        args.IncludeDefaultContents = false;
    end
    if any(ismember(folderInfo.m, 'Contents.m'))
        if args.CheckEmptyContents
            dirHelpStr = matlab.internal.help.folder.getContentsMHelp(folderInfo, true);
            b = dirHelpStr ~= "";
        else
            b = true;
        end
    elseif args.IncludeDefaultContents
        b = any(~structfun(@isempty, rmfield(folderInfo, 'path')));
    else
        b = false;
    end
end

%   Copyright 2018-2024 The MathWorks, Inc.
