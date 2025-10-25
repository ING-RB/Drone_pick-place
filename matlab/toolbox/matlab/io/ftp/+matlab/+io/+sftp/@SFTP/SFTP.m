classdef SFTP < matlab.io.FTP & matlab.io.internal.ftp.SharedOptions
%

%   Copyright 2020-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)
        Host(1, 1) string = missing;
        User(1, 1) string = missing;
        Port(1, 1) uint64 = 22;
        StartingFolder(1, :) {validateStartingFolder} = "/~/";
    end

    properties (Access = public)
        ServerSystem(1, 1) string {matlab.io.sftp.validateSystem} = "unix";
        DatetimeType(1, 1) string {validateDatetimeType} = "datetime";
        ServerLocale(1, 1) string {matlab.internal.datetime.verifyLocale} = "en_US";
        DirParserFcn(1, 1) function_handle = @matlab.io.ftp.parseDirListingForUnix;
    end

    properties (Transient, Hidden)
        Connection
        PasswordSupplied = false;
        DirParserFcnSupplied = false;
        Mode = "binary";
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of curl SFTP in
        % R2021b
        ClassVersion(1, 1) double = 1;
    end

    methods
        function obj = SFTP(host, user, options)
            arguments
                % Required input.
                host(1, 1) string;
                user(1, 1) string;

                % Name-value pair inputs.
                options.ServerSystem (1, 1) string = "unix";
                options.LoadObj (1, 1) logical = false;
                options.DatetimeType (1, 1) string = "datetime";
                options.ServerLocale (1, 1) string = "en_US";
                options.PublicKeyFile (1, 1) string = missing;
                options.PrivateKeyFile (1, 1) string = missing;
                options.Password (1, 1) string = missing;
                options.DirParserFcn (1, 1) function_handle = ...
                    @matlab.io.ftp.parseDirListingForUnix;
                options.UseProxy (1, 1) logical = false;
                options.StartingFolder (1, :) = missing;
                options.PrivateKeyPassphrase(1, 1) string = missing;
                options.?matlab.io.internal.ftp.SharedOptions;
            end
            %

            % Set input params on the object.
            obj.User = user;
            [obj.Host, obj.Port, path] = matlab.io.FTP.splitHostAndPort(host, "sftp://");
            if strlength(path) == 0
                hostAndPath = obj.Host;
                pathIncludedInHost = false;
            else
                hostAndPath = obj.Host + path;
                pathIncludedInHost = true;
            end
            obj.ServerSystem = options.ServerSystem;
            obj.DatetimeType = options.DatetimeType;
            if ~isequaln(options.DirParserFcn, obj.DirParserFcn)
                obj.DirParserFcn = options.DirParserFcn;
                obj.DirParserFcnSupplied = true;
            end

            if ~ismissing(options.StartingFolder)
                if pathIncludedInHost
                    error(message("MATLAB:io:ftp:ftp:StartingFolderAndPathNotAllowed"));
                end
                obj.StartingFolder = options.StartingFolder;
            end

            try
                obj.ServerLocale = options.ServerLocale;
            catch ME
                error(message("MATLAB:io:ftp:ftp:InvalidLocale", ...
                              options.ServerLocale));
            end

            % Attempt to connect to the remote SFTP server.
            obj.Connection = matlab.io.internal.Connection;

            configureProperties(obj, options);

            try
                % Connection Type
                if ismissing(options.Password)
                    if ismissing(options.PublicKeyFile) && ...
                            ismissing(options.PrivateKeyFile)
                        % SSH key authentication with default keys

                        if ispc
                            % Default location for SSH keys on Windows,
                            % .ssh directory in  %HOMEDRIVE%%HOMEPATH%
                            homeDir = string(getenv("HOMEDRIVE")) + ...
                                      string(getenv("HOMEPATH"));
                        elseif isunix || ismac
                            % Default location for SSH keys on Unix and Mac,
                            % .ssh directory in /home/username/
                            homeDir = string(getenv("HOME"));
                        end
                        % Add .ssh folder.
                        homeDir = fullfile(homeDir, ".ssh");
                        options.PrivateKeyFile = fullfile(homeDir, "id_rsa");
                        options.PublicKeyFile = fullfile(homeDir, "id_rsa.pub");

                        if ~exist(options.PrivateKeyFile, "file") || ~exist(options.PublicKeyFile, "file")
                            error(message("MATLAB:io:ftp:ftp:DefaultKeysNotFound", ...
                                options.PrivateKeyFile, options.PublicKeyFile));
                        end

                        if ismissing(options.PrivateKeyPassphrase)
                            try
                                % Default SSH key authentication.
                                obj.RemoteWorkingDirectory = ...
                                    matlab.io.sftp.internal.matlab.connectWithKeys(...
                                    obj.Connection, hostAndPath, obj.User, obj.Port, ...
                                    options.PublicKeyFile, options.PrivateKeyFile, ...
                                    options.UseProxy, obj.StartingFolder, ...
                                    obj.CertificateFilename, obj.VerifyPeer, ...
                                    obj.VerifyHost, obj.LowConnectionSpeed, ...
                                    obj.LowConnectionTime, pathIncludedInHost);
                            catch ME
                                if strcmp(ME.identifier, 'MATLAB:io:ftp:ftp:BadLogin')
                                    error(message("MATLAB:io:ftp:ftp:BadDefaultKeys", ...
                                        hostAndPath, options.PrivateKeyFile, ...
                                        options.PublicKeyFile));
                                else
                                    throw(ME);
                                end
                            end
                        else
                            try
                                % Connect using passphrase
                                obj.RemoteWorkingDirectory = ...
                                    matlab.io.sftp.internal.matlab.connectWithPassphrase(...
                                    obj.Connection, hostAndPath, obj.User, ...
                                    obj.Port, options.PublicKeyFile, ...
                                    options.PrivateKeyFile, options.PrivateKeyPassphrase, ...
                                    options.UseProxy, obj.StartingFolder, ...
                                    obj.CertificateFilename, obj.VerifyPeer, ...
                                    obj.VerifyHost, obj.LowConnectionSpeed, ...
                                    obj.LowConnectionTime, pathIncludedInHost);
                            catch ME
                                if strcmp(ME.identifier, 'MATLAB:io:ftp:ftp:BadLogin')
                                    error(message("MATLAB:io:ftp:ftp:BadDefaultKeys", ...
                                        hostAndPath, options.PrivateKeyFile, ...
                                        options.PublicKeyFile));
                                else
                                    throw(ME);
                                end
                            end
                        end
                    else
                        % get full paths to public and private keys
                        if ismissing(options.PrivateKeyFile) || ismissing(options.PublicKeyFile)
                            error(message("MATLAB:io:ftp:ftp:BothKeysRequired"));
                        end

                        D1 = dir(options.PrivateKeyFile);
                        D2 = dir(options.PublicKeyFile);
                        if isempty(D1) || isempty(D2)
                            error(message("MATLAB:io:ftp:ftp:KeysNotFound", ...
                                options.PrivateKeyFile, options.PublicKeyFile));
                        end
                        options.PrivateKeyFile = string(fullfile(D1.folder, D1.name));
                        options.PublicKeyFile = string(fullfile(D2.folder, D2.name));

                        if ismissing(options.PrivateKeyPassphrase)
                            try
                                % Custom SSH key authentication.
                                obj.RemoteWorkingDirectory = ...
                                    matlab.io.sftp.internal.matlab.connectWithKeys(...
                                    obj.Connection, hostAndPath, obj.User, obj.Port, ...
                                    options.PublicKeyFile, options.PrivateKeyFile, ...
                                    options.UseProxy, obj.StartingFolder, ...
                                    obj.CertificateFilename, obj.VerifyPeer, ...
                                    obj.VerifyHost, obj.LowConnectionSpeed, ...
                                    obj.LowConnectionTime, pathIncludedInHost);
                            catch ME
                                if strcmp(ME.identifier, 'MATLAB:io:ftp:ftp:BadLogin')
                                    error(message("MATLAB:io:ftp:ftp:BadKeys", ...
                                        hostAndPath, options.PrivateKeyFile, ...
                                        options.PublicKeyFile));
                                else
                                    throw(ME);
                                end
                            end
                        else
                            try
                                % Connect using passphrase
                                obj.RemoteWorkingDirectory = ...
                                    matlab.io.sftp.internal.matlab.connectWithPassphrase(...
                                    obj.Connection, hostAndPath, obj.User, obj.Port, ...
                                    options.PublicKeyFile, options.PrivateKeyFile, ...
                                    options.PrivateKeyPassphrase, options.UseProxy, ...
                                    obj.StartingFolder, obj.CertificateFilename, ...
                                    obj.VerifyPeer, obj.VerifyHost, ...
                                    obj.LowConnectionSpeed, obj.LowConnectionTime, ...
                                    pathIncludedInHost);
                            catch ME
                                if strcmp(ME.identifier, 'MATLAB:io:ftp:ftp:BadLogin')
                                    error(message("MATLAB:io:ftp:ftp:BadKeys", ...
                                        hostAndPath, options.PrivateKeyFile, ...
                                        options.PublicKeyFile));
                                else
                                    throw(ME);
                                end
                            end
                        end
                    end
                elseif ~ismissing(options.Password)
                    % password authentication
                    obj.PasswordSupplied = true;
                    try
                        obj.RemoteWorkingDirectory = ...
                            matlab.io.sftp.internal.matlab.connectWithPassword(...
                            obj.Connection, hostAndPath, obj.User, obj.Port, ...
                            options.Password, options.UseProxy, obj.StartingFolder, ...
                            obj.CertificateFilename, obj.VerifyPeer, obj.VerifyHost, ...
                            obj.LowConnectionSpeed, obj.LowConnectionTime, ...
                            pathIncludedInHost);
                    catch ME
                        if strcmp(ME.identifier, 'MATLAB:io:ftp:ftp:BadLogin')
                            error(message("MATLAB:io:ftp:ftp:BadPassword", ...
                                hostAndPath));
                        else
                            throw(ME);
                        end
                    end
                end
                obj.RemotePath = ...
                    matlab.io.ftp.internal.matlab.current_remote_url(obj.Connection);
                obj.StartingFolder = obj.RemoteWorkingDirectory;
            catch ME
                if options.LoadObj
                    warning(ME.message);
                else
                    throw(ME);
                end
            end
        end

        function set.ServerLocale(obj, locale)
        % Set the server locale on the object after validation.
            obj.ServerLocale = string(matlab.internal.datetime.verifyLocale(locale));
        end

        function set.ServerSystem(obj, system)
        % Set the server OS on the object after validation.
            obj.ServerSystem = matlab.io.sftp.validateSystem(system);
        end

        function set.DatetimeType(obj, datetimeType)
        % Set the server OS on the object after validation.
            obj.DatetimeType = validateDatetimeType(datetimeType);
        end

        function set.DirParserFcn(obj, func)
        % Set the custom dir output parsing function.
            if ~isequaln(func, obj.DirParserFcn)
                obj.DirParserFcn = func;
                obj.DirParserFcnSupplied = true; %#ok<MCSUP>
            end
        end

        function set.StartingFolder(obj, StartingFolder)
            if ~isequal(obj.StartingFolder, StartingFolder)
                obj.StartingFolder = string(StartingFolder);
            end
        end
    end

    methods(Hidden)
        function tf = IsConnected(obj)
        % to check that the connection is still alive
            tf = ~isempty(obj.Connection);
        end

        function tf = isFolder(obj, dirname)
            tf = matlab.io.sftp.internal.matlab.isFolder(obj.Connection, dirname);
        end
    end

    methods(Static)
        obj = loadobj(S);
    end
end

function type = validateDatetimeType(type)
    type = validatestring(type, ["datetime", "text"]);
end

function loginFolder = validateStartingFolder(input)
    if ~isstring(input) && ~ischar(input)
        error(message("MATLAB:io:ftp:ftp:LoginFolderMustBeString"));
    end
    loginFolder = input;
end
