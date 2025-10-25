function folders = absolutizeFolderNames(folders)
%absolutizeFolderNames makes every input folder name an
%   absolute path while removing trailing slashes if necessary.

%   Copyright 2019 The MathWorks, Inc.

    import matlab.io.internal.vfs.validators.isIRI;
    import matlab.io.datastore.internal.folders.removeTrailingSlash;

    % Absolutize input filenames.
    for index = 1:numel(folders)
        attributes = dir(folders{index});
        if isempty(attributes)
            folder = '';
        else
            folder = attributes(1).folder;
            % Percent-encode URIs if necessary
            if isIRI(folder)
                uri = matlab.net.URI(folder, 'literal');
                folder = convertStringsToChars(uri.EncodedURI);
            end
        end

        folders{index} = folder;
    end

    % Remove any trailing slashes.
    folders = removeTrailingSlash(folders);
end