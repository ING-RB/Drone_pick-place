classdef (Abstract) IconRepository
    % ICONREPOSITORY utility provides icons for the different T&M Hardware
    % Apps. Implementing classes need to inherit from this class and
    % provide implementations for the abstract members of the class.
    %
    % Public APIs -
    % >> matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon(toolbox, iconID)
    %
    % E.g.
    % >> matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "settings")
    %
    %  ans =
    %
    %      "settings"
    %
    %% NOTE TO CLIENTS
    % Things to do to use this utility -
    %
    % 1. Add your toolbox name to the enumeration in SupportedToolboxes.m
    % class in this folder (if not already added). If not already added,
    % you would have to follow the same procedure in the "getIcon" function
    % below, i.e. create a new persistent variable, create a similar case
    % in the switch-case.
    %
    % 2. Create toolbox icon repository class inheriting from this class
    % (See matlabshared.transportapp.internal.ICTIconRepository for
    % reference)
    %
    % 3. Add the name of your IconRepository class to the
    % ToolboxIconRepositoryDictionary property of the SupportedToolboxes
    % class in this folder.

    % Copyright 2023 The MathWorks, Inc.

    %% Public Abstract Properties
    properties(Abstract, Constant)
        % A dictionary with the icon id as the fieldname, and the
        % associated icon as the value.
        IconDictionary (1, 1) dictionary
    end

    %% Public APIs
    methods (Static)
        function icon = getIcon(toolbox, id)
            % Get the corresponding icon for the given toolbox's icon
            % repositiory and icon id.

            arguments
                toolbox (1, 1) string
                id (1, 1) string
            end

            import matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository
            switch toolbox
                case "ict"
                    iconRepo = IconRepository.getICTIconRepo();

                case "daq"
                    iconRepo = IconRepository.getDAQIconRepo();

                case "imaq"
                    iconRepo = IconRepository.getIMAQIconRepo();

                case "hwmgr"
                    iconRepo = IconRepository.getHwMgrIconRepo();

                case "hwmgrclient"
                    iconRepo = IconRepository.getHwMgrClientIconRepo();

                case "mlhw"
                    iconRepo = IconRepository.getMLHWIconRepo();

                case "vnt"
                    iconRepo = IconRepository.getVNTIconRepo();

                case "icomm"
                    iconRepo = IconRepository.getICOMMIconRepo();

                case "mock"
                    iconRepo = IconRepository.getMockIconRepo();

                otherwise
                    throwAsCaller(MException(message("shared_testmeaslib_apps:iconrepository:ToolboxNotSupported", upper(string(toolbox)))));
            end

            % Get the icon from the IconDictionary.
            try
                icon = iconRepo.IconDictionary(id);
            catch
                allSupportedIDs = matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getExistingIDs(toolbox);
                throwAsCaller(MException(message("shared_testmeaslib_apps:iconrepository:IconNotFound", id, upper(string(toolbox)), join(allSupportedIDs, newline))));
            end

            if iscell(icon)
                icon = icon{:};
            end

            %% NESTED FUNCTIONS

        end

        function allIDs = getExistingIDs(toolbox)
            % Get list of all IDs currently supported by the IconRepository
            % class.

            arguments
                toolbox (1, 1) matlabshared.testmeasapps.internal.themeableiconrepository.SupportedToolboxes
            end

            try
                repo = feval(matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository. ...
                    getRepoName(toolbox));
                allIDs = string(keys(repo.IconDictionary));
            catch ex
                throw(ex);
            end
        end
    end

    %% Static Helper functions
    methods (Static, Access = private)
        function instance = getIconRepositoryInstance(toolbox)
            % Return the icon repository instance for the provided
            % toolbox.

            repoName = matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository. ...
                getRepoName(toolbox);
            instance = feval(repoName);

            % Verify that the provided Icon Repository instance
            % inherits from this class (i.e. IconRepository.m).
            mustBeA(instance, "matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository");
        end

        function iconRepo = getICTIconRepo()
            persistent ictIconRepo
            if isempty(ictIconRepo)
                ictIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("ict");
            end
            iconRepo = ictIconRepo;
        end

        function iconRepo = getDAQIconRepo()
            persistent daqIconRepo
            if isempty(daqIconRepo)
                daqIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("daq");
            end
            iconRepo = daqIconRepo;
        end

        function iconRepo = getIMAQIconRepo()
            persistent imaqIconRepo
            if isempty(imaqIconRepo)
                imaqIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("imaq");
            end
            iconRepo = imaqIconRepo;
        end

        function iconRepo = getHwMgrIconRepo()
            persistent hwmgrIconRepo
            if isempty(hwmgrIconRepo)
                hwmgrIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("hwmgr");
            end
            iconRepo = hwmgrIconRepo;
        end

        function iconRepo = getHwMgrClientIconRepo()
            persistent hwmgrclientIconRepo
            if isempty(hwmgrclientIconRepo)
                hwmgrclientIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("hwmgrclient");
            end
            iconRepo = hwmgrclientIconRepo;
        end

        function iconRepo = getMLHWIconRepo()
            persistent mlhwIconRepo
            if isempty(mlhwIconRepo)
                mlhwIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("mlhw");
            end
            iconRepo = mlhwIconRepo;
        end

        function iconRepo = getVNTIconRepo()
            persistent vntIconRepo
            if isempty(vntIconRepo)
                vntIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("vnt");
            end
            iconRepo = vntIconRepo;
        end

        function iconRepo = getICOMMIconRepo()
            persistent icommIconRepo
            if isempty(icommIconRepo)
                icommIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("icomm");
            end
            iconRepo = icommIconRepo;
        end

        function iconRepo = getMockIconRepo()
            persistent mockIconRepo
            if isempty(mockIconRepo)
                mockIconRepo = ...
                    matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIconRepositoryInstance("mock");
            end
            iconRepo = mockIconRepo;
        end
    end

    methods (Static, Access = ?matlabshared.testmeasapps.internal.ITestable)
        function name = getRepoName(toolbox)
            % Get the associated icon repository for the toolbox.
            arguments
                toolbox (1, 1) matlabshared.testmeasapps.internal.themeableiconrepository.SupportedToolboxes
            end

            name = matlabshared.testmeasapps.internal.themeableiconrepository.SupportedToolboxes. ...
                ToolboxIconRepositoryDictionary(toolbox);

            if isempty(name) || name == ""
                throwAsCaller(MException(message("shared_testmeaslib_apps:iconrepository:ToolboxNotSupported", string(toolbox))));
            end
        end
    end
end