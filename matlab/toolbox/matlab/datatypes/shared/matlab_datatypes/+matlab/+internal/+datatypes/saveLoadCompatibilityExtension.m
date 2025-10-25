classdef (Abstract) saveLoadCompatibilityExtension
%SAVELOADCOMPATIBILITYEXTENSION Utility class to enforce backwards INcompatibility when loading a saved object with versioned superclasses.

%   Copyright 2022 The MathWorks, Inc.

    methods(Hidden)
        function serialized = setCompatibleVersionExtensionLimit(~, serialized, nvPairs)
            arguments
                ~
                serialized
                nvPairs.ClassName (1,1) string
                nvPairs.VersionNum (1,1) double
                nvPairs.MinCompatibleVersion (1,1) double
            end
            serialized.subclassVersionInfo.(nvPairs.ClassName).versionSavedFrom = nvPairs.VersionNum; % scalar double. version number of saved object
            serialized.subclassVersionInfo.(nvPairs.ClassName).minCompatibleVersion = nvPairs.MinCompatibleVersion; % scalar double. minimum running version required to reconstruct an instance from serialized data
            serialized.subclassVersionInfo.(nvPairs.ClassName).incompatibilityMsg = ''; % character row vector. Addition to warning message in case of incompatible load
        end

        function tf = isIncompatibleVersionExtension(~, serializedObj, nvPairs)
            % Warn if current version is below the minimum compatible version of the serialized object
            arguments
                ~
                serializedObj
                nvPairs.ClassName (1,1) string
                nvPairs.VersionNum (1,1) double
                nvPairs.WarnMsgId (1,1) string
            end
            tf = nvPairs.VersionNum < serializedObj.subclassVersionInfo.(nvPairs.ClassName).minCompatibleVersion;
            if tf
                warnState = warning('backtrace','off'); % warn without backtrace for cleaner display
                restoreWarnState = onCleanup(@()warning(warnState));
                msg = append(getString(message(nvPairs.WarnMsgId)), serializedObj.subclassVersionInfo.(nvPairs.ClassName).incompatibilityMsg);
                warning(WarnMsgId, msg);
            end
        end
    end
end