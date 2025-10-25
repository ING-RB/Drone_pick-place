function [uri, filepath] = resolveLocation(location)
    uri = matlab.net.URI.empty;
    filepath = string.empty;
    if isempty(location) || location == ""
        return;
    end

    if startsWith(location, ["http:", "https:", "matlab:", "text:", "mailto:", "about:"])
        uri = createEncodedUri(location);
        return;
    end
    
    % If it doesn't look like a URL with one of the supported schemes
    % above, it is likely a file on disk.
    fileLocation = matlab.internal.web.FileLocation(location);

    % If FileLocation didn't find the file and the input doesn't specify
    % the file: scheme, this may be a URL with the scheme omitted 
    % (e.g. mathworks.com instead of https://mathworks.com)
    if startsWith(location, "file:") || isValidFileLocation(fileLocation)
        uri = fileLocation.Uri;
        filepath = fileLocation.FilePath;
    elseif isInferredUrl(location)
        uri = matlab.net.URI("https://" + location);
    end
end    

function validFile = isValidFileLocation(fileLocation)
    if ~isempty(fileLocation.FilePath)
        % If the file doesn't exist, only use the location as a filepath
        % if it was provided as an absolute path.
        validFile = fileLocation.FileExists || ~fileLocation.RelativePathToMissingFile;
    else
        validFile = false;
    end
end

function isUrl = isInferredUrl(location)
    localhostPattern = ("localhost"|"127.0.0.1") + optionalPattern(":" + digitsPattern);
    noProtocolPattern = regexpPattern("^[^/\\]+\.[a-zA-Z]{2,}(/|$)");
    isUrl = startsWith(location, [localhostPattern, noProtocolPattern]);
end

function uri = createEncodedUri(location)
    % Create a matlab.net.URI from the raw string. This will parse the
    % string into a path, query, and fragment.
    uri = matlab.net.URI(location);

    % The URI will now have the scheme, host, and port set correctly, but
    % the other parts of the URI may not be encoded correctly.
    % Setting the path, query, and fragment properties explicitly on a
    % matlab.net.URI object will ensure that encoding is applied.
    if ~isempty(uri.Path)
        uri.EncodedPath = join(uri.Path, "/");
    end
    uri.Query = matlab.net.QueryParameter(uri.EncodedQuery);
    uri.Fragment = matlab.net.internal.urldecode(uri.Fragment);
end
    