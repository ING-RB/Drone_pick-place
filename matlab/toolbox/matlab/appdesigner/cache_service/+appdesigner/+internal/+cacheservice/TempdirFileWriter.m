classdef TempdirFileWriter < handle
    %TEMPDIRFILEWRITER 

%   Copyright 2024 The MathWorks, Inc.

    methods
        function root = getCacheRoot(~)
            persistent cacheLocation;

            if isempty(cacheLocation)
                if ispc
                    userID = getenv('USERNAME');
                else
                    userID = getenv('USER');
                end

                cacheLocation = fullfile(tempdir,...
                    append('matlab_', userID),...
                    append('R', version('-release')),...
                    'toolbox', 'matlab', 'appdesigner', 'cache');
            end

            if ~isfolder(cacheLocation)
                mkdir(cacheLocation);
            end

            root = cacheLocation;
        end

        function writeContent(~, filepath, fileContent)
            fid = fopen(filepath, 'w', 'n', 'UTF-8');

            cleanup = onCleanup(@()fclose(fid));

            fprintf(fid, '%s', fileContent);
        end

        function filePath = getInitFilePath(obj, uid)
           filePath = fullfile(obj.getCacheRoot(), uid, 'server', append('ad_', uid, '.m'));
        end

        function [isPresent, path] = hasInitFile(obj, uid)
            path = obj.getInitFilePath(uid);

            isPresent = logical(exist(path, 'file'));
        end

        function deleteInitFile(obj, uid)
            [isPresent, path] = obj.hasInitFile(uid);

            if isPresent
                delete(path);
            end
        end
    end
end
