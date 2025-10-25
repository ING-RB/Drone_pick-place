classdef (Abstract) FTP < matlab.mixin.Copyable
%FTP Abstract class for C++ and Java implementations of FTP

%   Copyright 2020-2024 The MathWorks, Inc.

    methods
        delete(obj, filename);
        newDir = cd(obj, folder);
        rename(obj, oldname, newname);
        mkdir(obj, dirname);
        rmdir(obj, dirname);
        varargout = dir(obj, folderName);
        location = mput(obj, str);
        location = mget(obj, str, targetDirectory);
        disp(obj);
        display(obj);
        S = saveobj(obj);
    end

    methods(Static)
        obj = loadobj(S);
    end

    properties (GetAccess = public, SetAccess = protected)
        RemoteWorkingDirectory(1, 1) string = missing;
    end

    properties (Access = protected)
        RemotePath(1, 1) string = "";
        System(1, 1) string {matlab.io.ftp.validateSystem} = "unix";
    end

    methods (Access = protected)
        function verifyConnection(obj)
        %VERIFYCONNECTION Verify that connection can be established to FTP server
            if isempty(obj.Connection)
                % Connection was not set up correctly, error
                error(message("MATLAB:io:ftp:ftp:NoConnection", obj.Host, obj.Port));
            end

            % cd to the correct folder if a connection was lost.
            cd(obj, obj.RemoteWorkingDirectory);
        end
    end

    methods (Static)
        function [host, port, path] = splitHostAndPort(str, scheme)
            if ~startsWith(str, scheme)
                str = scheme + str;
            end
            [host, port, path] = matlab.io.ftp.internal.matlab.splitURL(str);
        end
    end
end
