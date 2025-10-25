function obj = processFolder(obj, folder)
    %processFolder Helper function to testFolders

    %   Copyright 2021 The MathWorks, Inc.

    contents = dir(folder);
    contents(strcmp({contents.name}, "..") | strcmp({contents.name},".")) = [];
    for content = contents'
        fullName = fullfile(folder, content.name);
        if content.isdir
            if content.name == "+internal"
                if obj.CheckInternal
                    obj = obj.processFolder(fullName);
                end
            elseif startsWith(content.name, '@')
                if obj.InspectClasses
                    obj = obj.processFolder(fullName);
                end
            elseif startsWith(content.name, '+')
                if obj.RecursePackages
                    obj = obj.processFolder(fullName);
                end
            elseif obj.RecurseFolders
                obj = obj.processFolder(fullName);
            end
        else
            obj = obj.runTests(fullName);
        end
    end
end
