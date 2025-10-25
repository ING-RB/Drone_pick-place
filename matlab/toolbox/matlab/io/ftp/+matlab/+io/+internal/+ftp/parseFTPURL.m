function inmemStr = parseFTPURL(url, userAndPassword)
%PARSEFTPURL Returns an in-memory string from the supplied FTP URL
%   PARSEFTPURL accepts 2 inputs which are of the following format:
%   1) URL, of the form ftp://urltoFile:port
%   2) credentials, of the form user:password
%   Port, user, and password are all optional inputs.

% Copyright 2020 The MathWorks, Inc.
    arguments
        url(1, 1) string;
        userAndPassword(1, 1) string = "anonymous:anonymous@email.com";
    end

    % strip off ftp:// from URL
    if startsWith(url, "ftp://")
        url = extractAfter(url, "ftp://");
    end

    % get host till first /
    entryPointToHost = extractBefore(url, "/");

    % split user and password
    [user, password] = splitUserAndPassword(userAndPassword);

    % create FTP object with provided credentials
    obj = matlab.io.ftp.FTP(entryPointToHost, user, password);

    % create relative path to file
    relativePathToFile = extractAfter(url, "/");
    inmemStr = matlab.io.ftp.internal.matlab.parseUrl(obj.Connection, relativePathToFile);
end

function [user, password] = splitUserAndPassword(str)
    % Utility to split the combined user and password string into
    % constituent parts
    str = split(str, ":");

    if numel(str) == 1
        % Only received the username. Use the default password.
        user = str;
        password = "anonymous@email.com";
    elseif numel(str) == 2
        % Both host and port were provided.
        user = str(1);
        password = str(2);
    end
end