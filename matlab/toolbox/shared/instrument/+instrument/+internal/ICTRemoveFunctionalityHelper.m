classdef ICTRemoveFunctionalityHelper
    %ICTREMOVEFUNCTIONALITYHELPER will create and show/throw a warning and error as
    % part of the ICT legacy interface remove functionality "Warn" and
    % "Error" phases.

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties (Hidden, Constant)
        LegacyFunctions = ["makemid", "midedit", "midtest", "instrfind", ...
            "instrfindall", "instrreset", "instrcallback", ...
            "instrnotify", "instrhelp", "seriallist", "tmtool"]

        LegacyInterfaces = ["Bluetooth", "gpib", "serial", "tcpip", "udp", "visa", "i2c", ...
            "IviDCPwr", "IviDmm", "IviFgen", "IviSwtch", "IviSpecAn", "IviScope", ...
            "IviRFSigGen", "IviPwrMeter"]

        LegacyInstrhwinfoTypes = ["instrhwinfobluetooth","instrhwinfogpib",...
            "instrhwinfoserial","instrhwinfoserialport", ...
            "instrhwinfotcpip","instrhwinfoudp","instrhwinfovisa", "instrhwinfoi2c"]

        LegacyInterfacesWithIcdevice = ["gpib", "serial", "tcpip", "visa"]

        LegacyToNewInterfaceMap = containers.Map(...
            ["gpib", "serial", "tcpip", "visa"], ...
            ["visadev", "serialport", "tcpclient/tcpserver", "visadev"] ...
            );
    end

    properties (Hidden, Constant)
        % List of legacy ICT classes or functions that are in remove
        % functionality.
        RemoveFunctionalityList = [...
            instrument.internal.ICTRemoveFunctionalityHelper.LegacyInterfaces, ...
            instrument.internal.ICTRemoveFunctionalityHelper.LegacyFunctions, ...
            instrument.internal.ICTRemoveFunctionalityHelper.LegacyInstrhwinfoTypes, ...
            ]

        ToolboxPath = fullfile(matlabroot,"toolbox",filesep)
        TestPath = fullfile(matlabroot,"test",filesep)
        UnitTestPath = [fullfile(matlabroot,"test","toolbox","shared","instrument","unit","tICTRemoveFunctionalityHelper.m") fullfile(matlabroot,"test","toolbox","instrument","instrument", "interface", "tICTReleaseCompatibilityPhasing.m")]

        % The initial number of dbstack file names that need to be omitted.
        DBStackNumFramesToOmit = 4
    end

    methods
        function obj = ICTRemoveFunctionalityHelper(validname, phase, type)
            % Decides the message type to show for the remove functionality
            % phases.
            % warning - instrument.internal.ICTRemoveFunctionalityPhase.Warn
            % error - instrument.internal.ICTRemoveFunctionalityPhase.Error
            arguments
                validname (1, 1) string
                phase (1, 1) instrument.internal.ICTRemoveFunctionalityPhase = ...
                    instrument.internal.ICTRemoveFunctionalityPhase.Warn
                type (1, 1) instrument.internal.ICTRemoveFunctionalityEntity = ...
                    instrument.internal.ICTRemoveFunctionalityEntity.Class
            end

            narginchk(1,3);

            % Return early if
            %
            % 1. The interface or function should not warn or error (i.e.
            % not present in RemoveFunctionalityList),
            %
            % OR,
            %
            % 2. The interface or function is in the Warn phase, but
            % should not show a warning (~showWarning).
            returnEarly = @(name, ph) ...
                ~ismember(name, obj.RemoveFunctionalityList) || ...
                (ph == "Warn" && ~showWarning(obj));

            if returnEarly(validname, phase)
                return
            end

            % userMessageId - product:OldClass:ClassToBeRemoved, product:oldfun:FunctionToBeRemoved
            % (format specified as part of Remove functionality guideline)
            % Message Id shown to users.
            if type == instrument.internal.ICTRemoveFunctionalityEntity.Class
                userMessageId = "instrument:" + validname + ":ClassToBeRemoved";
            else
                userMessageId = "instrument:" + ...
                    renameForInstrhwinfo(obj, validname) + ":FunctionToBeRemoved";
            end

            % Message Id used in resource file.
            removeFcnMessageId = "instrument:removeFcnMessages:" + validname;

            if phase == instrument.internal.ICTRemoveFunctionalityPhase.Warn
                displayWarning(obj, validname, userMessageId, removeFcnMessageId);
            else
                ex = getError(obj, userMessageId, removeFcnMessageId);
                if ~isempty(ex)
                    % Throw error from the calling legacy client interface.
                    throwAsCaller(ex);
                end
            end

            %% NESTED FUNCTION
            function name = renameForInstrhwinfo(~, name)
                % If the name is instrhwinfo + <type> (e.g.
                % instrhwinfoserial), return only "instrhwinfo". Any other
                % name remains unchanged.
                if contains(name, "instrhwinfo")
                    name = "instrhwinfo";
                end
            end
        end
    end

    methods (Access = ?instrument.internal.ITestable)
        function str = getWarningString(obj, removeFcnWarningId, validname)
            % For any of the LegacyInterfacesWithIcdevice, add an
            % additional line to the warning message text about icdevice
            % incompatibility with the new interface. E.g. serialport is
            % not compatible with icdevice, and users should only use
            % serial. If users want to use serialport with icdevice, they
            % need to create an icdevice object with name-value argument
            % LegacyMode=false.
            str = message(removeFcnWarningId).string;
            if any(validname == obj.LegacyInterfacesWithIcdevice)
                str = str + newline + ...
                    message("instrument:removeFcnMessages:icdeviceNotSupported", obj.LegacyToNewInterfaceMap(validname)).string;
            end
        end
    end

    methods (Access = private)
        function displayWarning(obj, validname, userMessageId, removeFcnMessageId)
            % Create and show the remove functionality warning requested
            % by a specific legacy client interface.

            removeFcnWarningId = removeFcnMessageId + "Warning";
            warningstr = getWarningString(obj, removeFcnWarningId, validname);
            warnState = warning("backtrace", "off");
            oc = onCleanup(@()warning(warnState));
            warning(userMessageId, warningstr);
        end

        function ex = getError(~, userMessageId, removeFcnMessageId)
            % Create and return the remove functionality error exception
            % requested by a specific legacy client interface.

            removeFcnErrorId = removeFcnMessageId + "Error";
            errorstr = message(removeFcnErrorId).getString;
            ex = MException(userMessageId, errorstr);
        end

        function showWarn = showWarning(obj)
            % This function will return whether to warn or not depending on
            % which file is calling legacy ICT interfaces/functions.

            % Only customer code should show the remove functionality warning.
            showWarn = true;

            % Discard the first "DBStackNumFramesToOmit" file paths as they will be the paths
            % to the legacy ICT code, the ICTRemoveFunctionalityHelper constructor
            % and showWarningHelper function.
            [ST, ~] = dbstack('-completenames', obj.DBStackNumFramesToOmit);

            if isempty(ST)
                return
            end

            % Acquire list of all files from dbstack
            table = struct2table(ST);
            files = string(table.file)';

            % Show the warning when running the dedicated unit test for the class.
            if isUnitTest(obj, files)
                return
            end

            % Dont show warning if it is a toolbox product file or any other test file.
            showWarn = ~(isToolbox(obj, files(1)) || isTest(obj, files));

            function flag = isUnitTest(obj, files)
                flag = any(ismember(obj.UnitTestPath, files));
            end

            function flag = isToolbox(obj, file)
                flag = contains(file, obj.ToolboxPath);
            end

            function flag = isTest(obj, files)
                flag = any(contains(files, obj.TestPath));
            end
        end
    end
end
