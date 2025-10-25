classdef FileSystemEntryPermissionsPropertyNamesAndTypes
    %

    %   Copyright 2024 The MathWorks, Inc.

    properties (Constant)
        BasicPermNames = ["Readable", "Writable"];
        BasicClassPropNames = ["AbsolutePath", "Type"];

        ExtendedUnixPermNames = ["UserExecute", "GroupRead", "GroupWrite", ...
            "GroupExecute", "OtherRead", "OtherWrite", "OtherExecute"];

        BasicPropNames = [matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicClassPropNames, ...
            matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPermNames];

        AllPermNames = [matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPermNames, ...
            matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.ExtendedUnixPermNames];

        AllPropNames = [matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPropNames, ...
            matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.ExtendedUnixPermNames];

        BasicPropTypes = ["string", "matlab.io.FileSystemEntryType", ...
            "logical", "logical"];
        DisplayBasicPropTypes = ["string", "matlab.io.FileSystemEntryType", ...
            "matlab.io.PermissionsValues", "matlab.io.PermissionsValues"];

        BasicPermTypes = ["logical", "logical"];

        ExtendedUnixPermTypes = ["logical", "logical", "logical", "logical", ...
            "logical", "logical", "logical"];

        AllPropTypes = ["string", ...
            "matlab.io.FileSystemEntryType", "logical", "logical", "logical", ...
            "logical", "logical", "logical", "logical", "logical", "logical"];

        DisplayAllPropTypes = ["string", ...
            "matlab.io.FileSystemEntryType", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues", ...
            "matlab.io.PermissionsValues"];

        DisplayLength = 70;
    end

    methods
        function basicDict = basicClassPropNamesAndTypes(obj)
            basicDict = dictionary(obj.BasicPropNames, obj.BasicPropTypes);
        end

        function basicPermsDict = basicPermsNamesAndTypes(obj)
            basicPermsDict = dictionary(obj.BasicPermNames, obj.BasicPermTypes);
        end

        function extendedUnixPermsDict = extendedUnixPermsNamesAndTypes(obj)
            extendedUnixPermsDict = dictionary(obj.ExtendedUnixPermNames, ...
                obj.ExtendedUnixPermTypes);
        end

        function allPermsDict = allPermsNamesAndTypes(obj)
            keys = [obj.BasicPermNames, obj.ExtendedUnixPermNames];
            values = [obj.BasicPermTypes, obj.ExtendedUnixPermTypes];
            allPermsDict = dictionary(keys, values);
        end

        function allPropsDict = allPropsNamesAndTypes(obj)
            keys = [obj.BasicPropNames, obj.ExtendedUnixPermNames];
            values = [obj.BasicPropTypes, obj.ExtendedUnixPermTypes];
            allPropsDict = dictionary(keys, values);
        end
    end

    methods(Static)
        function permNames = getModifiablePermNames()
            if ispc
                permNames = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPermNames;
            else
                permNames = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.AllPermNames;
            end
        end

        function propNames = getModifiablePropNames()
            if ispc
                propNames = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPropNames;
            else
                propNames = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes.AllPropNames;
            end
        end
    end
end
