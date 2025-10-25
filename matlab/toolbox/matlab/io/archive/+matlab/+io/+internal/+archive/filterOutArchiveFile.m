function entries = filterOutArchiveFile(entries, archiveFilename, archiveFcn)
% Removes the archiveFilename from the list of files to include in the archive.

% Copyright 2020 The MathWorks, Inc.

comp = @strcmp; % comparator to use on mac and linux
if ispc
    comp = @strcmpi; % comparator to use on windows
end

% get full path for archive file
[status, fileAttrib] = fileattrib(archiveFilename);
if(status)
    archiveFilename = fileAttrib.Name;
end

for i = length(entries):-1:1
    % get full path for entry file
    entryFile = entries(i).file;
    [status, fileAttrib] = fileattrib(entryFile);
    if(status)
        entryFile = fileAttrib.Name;
    end
    if comp(archiveFilename, entryFile)
        % do not add the archiveFilename to the entries structure
        wid = sprintf('MATLAB:%s:archiveName', archiveFcn);
        warning(wid,'%s', ...
            getString(message('MATLAB:io:archive:createArchive:archiveName',upper(archiveFcn),archiveFilename)));
        entries(i) = [];
    end
end