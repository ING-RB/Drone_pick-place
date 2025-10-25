classdef UnixPermissions < matlab.io.FileSystemEntryPermissions
%

%   Copyright 2024-2025 The MathWorks, Inc.

    properties (Dependent)
        UserExecute (:, 1) logical
        GroupRead (:, 1) logical
        GroupWrite (:, 1) logical
        GroupExecute (:, 1) logical
        OtherRead (:, 1) logical
        OtherWrite (:, 1) logical
        OtherExecute (:, 1) logical
    end

    methods
        function uExec = get.UserExecute(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("UserExecute", true);
            values = getPerms(obj.AbsolutePath, "UserExecute");
            uExec = values.UserExecute;
        end

        function gRead = get.GroupRead(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("GroupRead", true);
            values = getPerms(obj.AbsolutePath, "GroupRead");
            gRead = values.GroupRead;
        end

        function gWrite = get.GroupWrite(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("GroupWrite", true);
            values = getPerms(obj.AbsolutePath, "GroupWrite");
            gWrite = values.GroupWrite;
        end

        function gExec = get.GroupExecute(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("GroupExecute", true);
            values = getPerms(obj.AbsolutePath, "GroupExecute");
            gExec = values.GroupExecute;
        end

        function oRead = get.OtherRead(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("OtherRead", true);
            values = getPerms(obj.AbsolutePath, "OtherRead");
            oRead = values.OtherRead;
        end

        function oWrite = get.OtherWrite(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("OtherWrite", true);
            values = getPerms(obj.AbsolutePath, "OtherWrite");
            oWrite = values.OtherWrite;
        end

        function oExec = get.OtherExecute(obj)
            import matlab.io.internal.filesystem.getPerms;
            validateFilesystem("OtherExecute", true);
            values = getPerms(obj.AbsolutePath, "OtherExecute");
            oExec = values.OtherExecute;
        end
    end

    methods
        function obj = UnixPermissions(location)
            arguments
                location (1, 1) string
            end
            obj.AbsolutePath = matlab.io.internal.filesystem.resolveRelativeLocation(location);
        end
    end

    % Setters block
    methods
        function obj = set.UserExecute(obj, value)
            validateFilesystem("UserExecute", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("UserExecute", value));
        end

        function obj = set.GroupRead(obj, value)
            validateFilesystem("GroupRead", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("GroupRead", value));
        end

        function obj = set.GroupWrite(obj, value)
            validateFilesystem("GroupWrite", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("GroupWrite", value));
        end

        function obj = set.GroupExecute(obj, value)
            validateFilesystem("GroupExecute", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("GroupExecute", value));
        end

        function obj = set.OtherRead(obj, value)
            validateFilesystem("OtherRead", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("OtherRead", value));
        end

        function obj = set.OtherWrite(obj, value)
            validateFilesystem("OtherWrite", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("OtherWrite", value));
        end

        function obj = set.OtherExecute(obj, value)
            validateFilesystem("OtherExecute", false);
            matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                string(obj.Type), struct("OtherExecute", value));
        end
    end
end

function validateFilesystem(permName, getter)
    if ispc
        if getter
            error(message("MATLAB:io:filesystem:filePermissions:" + ...
                "CannotGetUnixPermissionsOnWindows", permName));
        else
            error(message("MATLAB:io:filesystem:filePermissions:" + ...
                "CannotSetUnixPermissionsOnWindows", permName));
        end

    end
end
