function [pathstr, name, ext] = fileparts(file)

    emptyFile = isempty(file);
    fileIsCellstr = iscellstr(file); %#ok<ISCLSTR>
    fileIsString = isstring(file);
    fileIsChar = ischar(file);

    supportedTypes = fileIsChar || fileIsCellstr || fileIsString;

    if ~supportedTypes
        % error when input is not any of char or string or cellstr
        error(message("MATLAB:fileparts:MustBeChar"));
    elseif fileIsChar && ~isrow(file) && ~emptyFile
        % error for char matrices
        error(message("MATLAB:fileparts:MustBeChar"));
    elseif fileIsString && any(ismissing(file),"all")
        % error for missing string
        error(message("MATLAB:fileparts:StringMissingUnsupported"));
    end

    % if input is empty, return the appropriate output
    if emptyFile
        if fileIsString
            % string output
            pathstr = string.empty(size(file));
            name = string.empty(size(file));
            ext = string.empty(size(file));
        else
            if fileIsChar
                % char output
                pathstr = char.empty(size(file));
                name = char.empty(size(file));
                ext = char.empty(size(file));
            else
                % cellstr output
                pathstr = cell.empty(size(file));
                name = cell.empty(size(file));
                ext = cell.empty(size(file));
            end
        end
        return;
    end

    % branch for scalar input vs vector input on Windows
    fileIsScalar = isscalar(file);
    fileIsScalarCell = fileIsCellstr && fileIsScalar;
    inputIsScalar = (fileIsChar && ~fileIsCellstr) || (fileIsString && fileIsScalar);
    if inputIsScalar && ispc
        [pathstr, name, ext] = legacyPCExecution(file);
    else
        % convert to string to use string API
        file = string(file);

        % Branch code for OS-specific constraints
        if ispc
            % convert input into a column vector
            [pathstr, name] = pcExecution(file);
        else
            % convert input into a row vector
            [pathstr, name] = unixExecution(file);
        end

        % separate file name from extension
        numOutArgs = nargout;
        if numOutArgs > 1
            [ext, name] = getExtension(name);
        end

        % convert back to char or cellstr if input was char or cellstr.
        if ~fileIsString
            if numOutArgs > 1
                [pathstr, name, ext] = returnCharOrCellstr(pathstr, name, ext, numOutArgs, fileIsScalarCell);
            else
                pathstr = returnCharOrCellstr(pathstr, [], [], numOutArgs, fileIsScalarCell);
            end
        end
    end
end

function [pathstr, name] = pcExecution(file)
    % find the last occurrence of / or \, i.e. file separators, and use
    % that to determine the extent of the path
    revfile = reverse(file);
    persistent separator;
    if isempty(separator)
        separator = "\" | "/";
    end

    % extract before and after file separators to get path and file name
    revName = revfile.extractBefore(separator);
    revName = reverse(revName);
    name = revName;
    revPathstr = revfile.extractAfter(separator);
    revPathstr = reverse(revPathstr);
    pathstr = revPathstr;

    % empty paths might be mounted drives, find colon indicating drive
    % letter
    vectorEmpty = ismissing(pathstr);
    if any(vectorEmpty)
        pathstr(vectorEmpty) = reverse(":" + revfile(vectorEmpty).extractAfter(":"));
    end

    % add back file separator for paths ending in colon
    endColon = endsWith(pathstr, ":");
    if any(endColon, "all")
        colonIndices = endColon & strlength(pathstr) > 2;
        name(colonIndices) = extractAfter(file(colonIndices), pathstr(colonIndices));
        nameStartingWithFilesep = startsWith(name, separator);
        name(nameStartingWithFilesep) = extractAfter(name(nameStartingWithFilesep),separator);
        pathstr(colonIndices) = pathstr(colonIndices) + filesep;

        if any(~colonIndices,"all")
            % add the appropriate file separator for paths ending in colon when
            % input size > 3
            colonIndicesGt3 = endColon & strlength(file) >= 3;
            extractor = extractBetween(file(colonIndicesGt3), 3, 3);
            isSep = matches(extractor, separator);
            if all(isSep)
                pathstr(colonIndicesGt3) = pathstr(colonIndicesGt3) + extractor;
            else
                pathstr(colonIndicesGt3 & isSep) = pathstr(colonIndicesGt3 & isSep) + ...
                    extractor(isSep);
                end
            end
        end

        % for UNC paths, check that the second character is / or \
        if ~ismissing(revPathstr)
            indices = matches(pathstr, ["\"; "/"]) & strlength(file) > 1;
            pathstr(indices) = file(indices);
            name(indices) = "";
        end

        % add the file separator for paths that are empty
        emptyPaths = strlength(pathstr) == 0;
        if any(emptyPaths, "all")
            pathstr(emptyPaths) = filesep;
        end

        % for paths ending in colon, the rest of the input string is the file
        % name
        name(ismissing(name)) = "";
        endColon = endsWith(pathstr, ":");
        name(endColon) = extractAfter(file(endColon), ":");

        % for paths that are empty, the input string is a file name only

    missingPaths = ismissing(pathstr);
    name(missingPaths) = file(missingPaths);
    pathstr(missingPaths) = "";
end

function [pathstr, name, ext] = legacyPCExecution(file)
    if isstring(file)
        inputWasString = true;
        file = char(file);
    else
        inputWasString = false;
    end
    ext = '';
    pathstr = '';
    ind = find(file == '/' | file == '\', 1, 'last');
    if isempty(ind)
        ind = find(file == ':', 1, 'last');
        if ~isempty(ind)
            pathstr = file(1:ind);
        end
    else
        if ind == 2 && (file(1) == '/' || file(1) == '\')
            % Special case for UNC server
            pathstr =  file;
            ind = length(file);
        else
            pathstr = file(1:ind-1);
        end
    end
    if isempty(ind)
        name = file;
    else
        if ~isempty(pathstr) && pathstr(end)== ':'
            % Don't append to D: which is a volume path on windows
            if length(pathstr) > 2
                pathstr = [pathstr filesep];
            elseif length(file) >= 3 && (file(3) == '/' || file(3) == '\')
                pathstr = [pathstr file(3)];
            end
        elseif isempty(deblank(pathstr))
            pathstr = filesep;
        end
        name = file(ind+1:end);
    end

    if ~isempty(name)
        % Look for EXTENSION part
        ind = find(name == '.', 1, 'last');

        if ~isempty(ind)
            ext = name(ind:end);
            name(ind:end) = [];
        end
    end

    if inputWasString
        pathstr = string(pathstr);
        name = string(name);
        ext = string(ext);
    end
end

function [pathstr, name] = unixExecution(file)
% find occurrences of the file separator
    revfile = reverse(file);

    % extract before and after file separators to get path and file name
    revName = extractBefore(revfile, filesep);
    name = reverse(revName);
    revPathstr = extractAfter(revfile, filesep);
    pathstr = reverse(revPathstr);

    % When both path and file name are empty, insert input into file name
    missingIndices = ismissing(name) & ismissing(pathstr);
    name(missingIndices) = file(missingIndices);

    % Add file separator when in the root file system
    pathstr(pathstr == "") =  filesep;
    pathstr(ismissing(pathstr)) = "";
    name(ismissing(name)) = "";
end

function [pathstr, name, ext] = returnCharOrCellstr(pathstr, name, ext, numOutArgs, fileIsScalarCell)
% char or cellstr was provided as input so convert back to char or cellstr.

    pathstr = getReturnCharOrCellstr(pathstr, fileIsScalarCell);

    if numOutArgs == 1 || ~numOutArgs
        return;
    else
        if numOutArgs > 2
            ext = getReturnCharOrCellstr(ext, fileIsScalarCell);
        end

        if nargout > 1
            name = getReturnCharOrCellstr(name, fileIsScalarCell);
            if isempty(name)
                % Only when returning the the second output 'name' as empty
                % character vector, if not all outputs are empty, replace
                % the 0×0 empty char array with 1×0 empty char array for
                % backward compatibility before g1531204: vectorize fileparts.
                name = char.empty(1, 0);
            end
        end
    end
end

function returnStr = getReturnCharOrCellstr(inStr, fileIsScalarCell)
% Return as character vector for string scalar input and as cell array for
% string array input or when fileIsScalarCell.

    % Convert string scalar to character vector and string array to cell
    % array.
    returnStr = convertStringsToChars(inStr);

    % G2864889: Ensure TITO (Type In, Type Out) even for scalar cell inputs.
    if fileIsScalarCell
        returnStr = {returnStr};
    end
end

function [ext, newName] = getExtension(name)
% get extension from the file name
    newName = reverse(name);

    ext = reverse(extractBefore(newName,".") + ".");
    newName = reverse(extractAfter(newName,"."));

    hasNoDot = ismissing(ext);

    newName(hasNoDot) = name(hasNoDot);
    ext(hasNoDot) = "";
end

% Copyright 1984-2024 The MathWorks, Inc.
