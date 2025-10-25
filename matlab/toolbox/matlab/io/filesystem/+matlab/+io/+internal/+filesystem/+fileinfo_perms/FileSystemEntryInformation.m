classdef FileSystemEntryInformation < matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties
        AbsolutePath (:, :) string
    end

    properties (Dependent)
        LastModifiedTimestamp (:, :) datetime
        % Permissions (:, :) matlab.io.internal.filesystem.fileinfo_perms.FileSystemEntryPermissions
    end

    methods
        function timestamp = get.LastModifiedTimestamp(obj)
            S = matlab.io.internal.filesystem.resolvePathWithAttributes(obj.AbsolutePath, ResolveSymbolicLinks=false);
            timestamp = datetime.fromMillis(S.LastModified);
        end

        % function perms = get.Permissions(obj)
        %     import matlab.io.internal.filesystem.fileinfo_perms.*
        %     perms = filePermissions([obj(:).AbsolutePath]);
        %     perms = reshape(perms, size(obj));
        % end
    end

    methods (Sealed)
        function perms = permissions(obj)
            perms = matlab.io.internal.filesystem.fileinfo_perms.filePermissions([obj(:).AbsolutePath]);
        end
    end

    methods (Sealed, Access = protected)
        function displayNonScalarObject(objArr)
            varNames = ["AbsolutePath", "LastModifiedTimestamp"];
            varTypes = ["string", "datetime"];
            allSymLinks = false;
            allFiles = false;
            if all(isa(objArr, "matlab.io.internal.filesystem.fileinfo_perms.SymbolicLinkInformation"))
                varNames = [varNames, "LinkTarget"];
                varTypes = [varTypes, "string"];
                allSymLinks = true;
            elseif all(isa(objArr, "matlab.io.internal.filesystem.fileinfo_perms.FileInformation"))
                varNames = [varNames, "FileType", "Size", "Description", "RelatedFunctions"];
                varTypes = [varTypes, "string", "double", "string", "string"];
                allFiles = true;
            else
                varNames = [varNames, "FileType", "Size", "Description", "RelatedFunctions", "LinkTarget"];
                varTypes = [varTypes, "string", "double", "string", "string", "string"];
            end

            if all(isa(objArr, "matlab.io.internal.filesystem.fileinfo_perms.FolderInformation"))
                allFolders = true;
            else
                allFolders = false;
            end

            T = table(Size=[numel(objArr) numel(varNames)], VariableNames=varNames, ...
                VariableTypes=varTypes);
            for index = 1 : numel(objArr)
                obj = objArr(index);
                reducedPath = obj.AbsolutePath;
                if strlength(reducedPath) > 70
                    reducedPath = reverse(extractBefore(reverse(reducedPath), 70));
                    % find filesep in path
                    if matlab.io.internal.vfs.validators.isIRI(char(reducedPath))
                        pathSep = "/";
                    else
                        pathSep = filesep;
                    end
                    reducedPath = "..." + pathSep + extractAfter(reducedPath, pathSep);
                end
                T(index, :).AbsolutePath = reducedPath;
                T(index, :).LastModifiedTimestamp = obj.LastModifiedTimestamp;
                if (isa(obj, "matlab.io.internal.filesystem.fileinfo_perms.FileInformation"))
                    T(index, :).FileType = obj.FileType;
                    T(index, :).Size = obj.Size;
                    T(index, :).Description = obj.Description;
                    T(index, :).RelatedFunctions = obj.RelatedFunctions;
                else
                    if ~allFolders && ~allSymLinks
                        T(index, :).FileType = missing;
                        T(index, :).Size = NaN;
                        T(index, :).Description = missing;
                        T(index, :).RelatedFunctions = missing;
                    end
                end
                if (isa(obj, "matlab.io.internal.filesystem.fileinfo_perms.SymbolicLinkInformation"))
                    T(index, :).LinkTarget = obj.Target;
                else
                    if ~allFolders && ~allFiles
                        T(index, :).LinkTarget = missing;
                    end
                end
            end

            if any(contains(T.Properties.VariableNames, "FileType")) && all(ismissing(T.FileType))
                T = removevars(T, "Type");
                T = removevars(T, "Description");
                T = removevars(T, "RelatedFunctions");
                T = removevars(T, "Size");
            end
            if any(contains(T.Properties.VariableNames, "LinkTarget")) && all(ismissing(T.LinkTarget))
                T = removevars(T, "LinkTarget");
            end
            disp(T);
        end
    end
end
