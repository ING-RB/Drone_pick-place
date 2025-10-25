function copyIfMissing(src,target)
%

%   Copyright 2020-2024 The MathWorks, Inc.

    if isfolder(src)
        if ~isfolder(target)
            copyfile(src, target, 'f');
            users = '';
            if isunix
                users = 'u';
            end
            fileattrib(target, '+w', users, 's');
        end
    elseif ~isfile(target)
        copyfile(src,target,'f');
        fileattrib(target,'+w')
    end
end
