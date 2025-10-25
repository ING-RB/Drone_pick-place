classdef FTP < matlab.io.FTP & matlab.io.internal.ftp.SharedOptions
%

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private)
        Host(1, 1) string = missing;
        Username(1, 1) string = missing;
        Port(1, 1) uint64 = 21;
    end

    properties (Access = public)
        ServerLocale(1,1) string {matlab.io.ftp.validateServerLocale} = "en_US";
        DirParserFcn(1, 1) function_handle = @matlab.io.ftp.parseDirListingForUnix;
        Mode(1, 1) string {validateMode} = "binary";
    end

    properties(SetAccess = protected)
        TLSMode(1, 1) string {matlab.io.ftp.validateTLSMode} = "none";

        %LOCALDATACONNECTIONMETHOD Set the current data connection mode
        %   LocalDataConnectionMethod is set to 'passive' by default.
        %   Can be any of the following values:
        %
        %   passive - This option is only for data transfers between the client
        %             and server. This option informs the server to open a
        %             data port to which the client will connect to conduct
        %             data transfers. This is the default option.
        %
        %   active  - No communication with the FTP server is conducted,
        %             but this causes all future data transfers to require
        %             the FTP server to connect to the client's data port.
        %
        LocalDataConnectionMethod(1, 1) string {validateLocalDataConnectionMethod} = "passive";
    end

    properties (Transient, Hidden)
        Connection
        PasswordSupplied = false;
        DirParserFcnSupplied = false;
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of curl FTP in
        % R2021a
        ClassVersion(1, 1) double = 1;
    end

    methods
        function obj = FTP(host, username, password, options)
            arguments
                % Required input.
                host(1, 1) string;

                % Optional (positional) inputs.
                username(1, 1) string = "anonymous";
                password(1, 1) string = "anonymous@email.com";

                % Name-value pair inputs.
                options.System(1, 1) string = "auto";
                options.LocalDataConnectionMethod(1, 1) string  = "passive";
                options.LoadObj(1, 1) logical = false;
                options.TLSMode(1, 1) string = "none";
                options.ServerLocale(1, 1) string = "en_US";
                options.DirParserFcn (1, 1) function_handle = ...
                    @matlab.io.ftp.parseDirListingForUnix;
                options.UseProxy (1, 1) logical = false;
                options.?matlab.io.internal.ftp.SharedOptions;
            end
            %

            % Set input params on the object.
            obj.Username = username;
            [obj.Host, obj.Port, path] = matlab.io.FTP.splitHostAndPort(host, "ftp://");
            if strlength(path) == 0
                hostAndPath = obj.Host;
            else
                hostAndPath = obj.Host + path;
            end

            obj.TLSMode = options.TLSMode;
            if ~isequaln(options.DirParserFcn, obj.DirParserFcn)
                obj.DirParserFcn = options.DirParserFcn;
                obj.DirParserFcnSupplied = true;
            end

            try
                obj.ServerLocale = options.ServerLocale;
            catch ME
                error(message("MATLAB:io:ftp:ftp:InvalidLocale", ...
                              options.ServerLocale));
            end

            if options.System == "auto"
                remoteSystemSupplied = false;
            else
                obj.System = matlab.io.ftp.validateSystem(options.System);
                remoteSystemSupplied = true;
            end
            obj.LocalDataConnectionMethod = options.LocalDataConnectionMethod;

            % Attempt to connect to the remote FTP server.
            obj.Connection = matlab.io.internal.Connection;

            if password ~= "anonymous@email.com"
                obj.PasswordSupplied = true;
            end
            
            configureProperties(obj, options);

            try
                obj.RemoteWorkingDirectory = matlab.io.ftp.internal.matlab.connect(...
                    obj.Connection, hostAndPath, obj.Username, password, obj.Port, ...
                    obj.LocalDataConnectionMethod, obj.TLSMode, ...
                    options.UseProxy, obj.CertificateFilename, obj.VerifyPeer, ...
                    obj.VerifyHost, obj.LowConnectionSpeed, ...
                    obj.LowConnectionTime);
                obj.RemotePath = matlab.io.ftp.internal.matlab.current_remote_url(obj.Connection);

                if ~remoteSystemSupplied
                    serverSystemString = matlab.io.ftp.internal.matlab.serverSystem(obj.Connection);
                    obj = setServerSystem(obj, serverSystemString);
                end
            catch ME
                if options.LoadObj && ME.identifier == "MATLAB:io:ftp:ftp:BadLogin"
                    warning(message("MATLAB:io:ftp:ftp:BadLogin"));
                else
                    throw(ME);
                end
            end
        end

        function set.Mode(obj, mode)
        % Set the mode on the object after validation.
            obj.Mode = validateMode(mode);
        end

        function set.ServerLocale(obj, locale)
        % Set the server locale on the object after validation.
            obj.ServerLocale = string(matlab.internal.datetime.verifyLocale(locale));
        end

        function set.DirParserFcn(obj, func)
        % Set the custom dir output parsing function.
            if ~isequaln(func, @matlab.io.ftp.parseDirListingForUnix)
                obj.DirParserFcn = func;
                obj.DirParserFcnSupplied = true; %#ok<MCSUP>
            end
        end
    end

    methods(Hidden)
        function tf = IsConnected(obj)
        % to check that the connection is still alive
            tf = ~isempty(obj.Connection);
        end

        function tf = isFolder(obj, dirname)
            tf = matlab.io.ftp.internal.matlab.isFolder(obj.Connection, dirname);
        end
    end

    methods(Static)
        obj = loadobj(S);
    end

    methods (Access = protected)
        function obj = setServerSystem(obj, serverSystemString)
        % set System property based on output of SYST primitive
            if serverSystemString == ""
                obj.System = "unix";
                return;
            end

            if contains(serverSystemString, "unix", "IgnoreCase", true)
                % is a UNIX server, could be QNX server
                if contains(serverSystemString, "QNX")
                    obj.System = "QNX";
                end
            elseif contains(serverSystemString, "Windows", "IgnoreCase", true)
                % is a Windows server
                obj.System = "Windows";
            end
        end
    end
end

function method = validateLocalDataConnectionMethod(method)
    try
        method = validatestring(method, ["passive" "active"]);
    catch ME
        % Throw a custom error message if LocalDataConnectionMethod validation failed.
        error(message("MATLAB:io:ftp:ftp:IncorrectDataLocalConnectionMode"));
    end
end

function mode = validateMode(mode)
    mode = validatestring(mode, ["binary" "ascii"]);
end

