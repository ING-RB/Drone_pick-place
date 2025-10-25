classdef TempFolderManager < handle
% Object to manage a local temp folder that can be cleaned up on exit

    properties (SetAccess = private)
        InstanceRoot(1,1) string
        TempFolderLocation(1,1) string = missing;
        PersistOnClose(1,1) logical = false
        Suffix(:,1) string;
    end

    methods
        function obj = TempFolderManager(suffix,args)
            arguments
                suffix(1,:) string = ""
                args.PersistOnClose(1,1) logical = false;
            end
            obj.Suffix = suffix;
            if ~ispc
                obj.InstanceRoot = fullfile(tempdir,matlab.lang.internal.uuid);
            else
                obj.InstanceRoot = fullfile(tempdir,extractBefore(matlab.lang.internal.uuid,'-'));
            end

            for arg = string(fieldnames(args)')
                obj.(arg) = args.(arg);
            end
        end

        function val = get.TempFolderLocation(obj)
            if ismissing(obj.TempFolderLocation)
                folder = fullfile(obj.InstanceRoot,obj.Suffix{:});
                if ~isfolder(folder)
                    assert(mkdir(folder),"Unable To Create Local Folder.");
                end
                obj.TempFolderLocation = folder;
            end
            val = obj.TempFolderLocation;
        end

        function delete(obj)
            if ~obj.PersistOnClose && isfolder(obj.TempFolderLocation)
                rmdir(obj.InstanceRoot,'s');
            end
        end
    end
end

%   Copyright 2024-2025 The MathWorks, Inc.
