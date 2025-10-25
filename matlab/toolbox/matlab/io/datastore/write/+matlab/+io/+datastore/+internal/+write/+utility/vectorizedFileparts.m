function [pathstr, name, ext] = vectorizedFileparts(file)
%VECTORIZEDFILEPARTS   Vectorized version of fileparts
%   [FILEPATH, NAME, EXT] = VECTORIZEDFILEPARTS(FILE) returns the path,
%   file name, and file name extension for the specified FILE. The FILE
%   input is the name of a file or folder, and can include a path and file
%   name extension. The function interprets all characters following the
%   right-most path delimiter as a file name plus extension.

%   Copyright 2023 The MathWorks, Inc.

pathstr = "";
name = "";
ext = "";

if iscellstr(file) || ischar(file) %#ok<ISCLSTR>
    file = string(file);
end

if isempty(file)
    return;
end

if ispc
    % find the last occurrence of / or \, i.e. file separators
    ind1 = strfind(file,"/");
    ind2 = strfind(file,"\");
    if iscell(ind1)
        ind = zeros(size(ind1,1),1);
        emptyFwdSlash = all(cellfun('isempty',ind1));
        emptyBckwdSlash = all(cellfun('isempty',ind2));
        if emptyFwdSlash && emptyBckwdSlash
            ind = [];
        else
            for ii = 1 : size(ind1,1)
                lastIdx = [ind1{ii}, ind2{ii}];
                ind(ii) = lastIdx(end);
            end
        end
    else
        ind = max([ind1,ind2]);
    end
    if isempty(ind)
        % there were no file separators, check to see if a mounted drive is
        % part of the path
        ind = strfind(file,":");
        if ~isempty(ind)
            if iscell(ind)
                for ii = 1 : size(ind,2)
                    pathstr(ii,1) = extractBetween(file(ii),1,ind{ii}(end));
                end
            else
                pathstr = extractBetween(file,1,ind(end));
            end
        end
    else
        if ind(end) == 2 && (strfind(file(1),"\") == 1 || strfind(file(1),"/") == 1)
            % special case for UNC server, such as \\home
            pathstr =  file;
            ind = length(file);
        else
            % get the path till the last file separator
            pathstr = extractBetween(file,1,ind-1);
        end
    end
    if isempty(ind)
        % no file separator, i.e,. no folder structure in path
        name = file;
    else
        % get file name after last file separator, currently includes extension
        name = extractBetween(file,ind+1,strlength(file));
    end
    % separate file name from extension
    [ext, name] = getExtension(name,ext);
else    % UNIX
    % find occurrences of the file separator
    ind = strfind(file,filesep);
    if isempty(ind)
        % if no file separators are found, file name is input
        name = file;
    else
        % check whether cell array of index locations was returned
        if iscell(ind)
            pathstr = strings(size(ind,2),1);
            name = strings(size(ind,2),1);
            ext = strings(size(ind,2),1);
            for i = 1:size(ind,1)
                % for each string location in the input, separate the path
                % from the file name and the extension
                thisIndex = ind{i};
                if ~isempty(thisIndex)
                    pathstr(i,1) = extractBefore(file(i),thisIndex(end));
                    name(i,1) = extractAfter(file(i),thisIndex(end));
                    [ext(i,1), name(i,1)] = getExtension(name(i));
                end
            end
        else
            pathstr = extractBefore(file,ind(end));
            name = extractAfter(file,ind(end));
            [ext, name] = getExtension(name,ext);
        end

        % Do not forget to add filesep when in the root filesystem
        idx = deblank(pathstr) == "";
        if any(idx)
            pathstr(idx) = filesep;
        end
    end
end
ext = reshape(ext, [], 1);
end

function [ext, name] = getExtension(name,ext)
    if ~isempty(name)
        % Look for extension part
        ind = strfind(name, ".");
        if isempty(ind)
            % Could not find any extension, return the original strings.
            ext = "";
            return;
        elseif iscell(ind)
            % if cell, go through each entry separately
            for ii = 1 : size(ind,1)
                if ~isempty(ind{ii})
                    tempIdx = ind{ii}(end);
                    ext(ii) = extractAfter(name(ii),tempIdx-1);
                    name(ii) = extractBefore(name(ii),tempIdx);
                else
                    ext(ii) = "";
                end
            end
        else
            ind = ind(end);
            ext = extractAfter(name,ind-1);
            name = extractBefore(name,ind);
        end
    end
end
