classdef (Sealed) CSTCustomSettings < handle
%

%   Copyright 2013-2022 The MathWorks, Inc.

    properties
        ControlSystemDesignerVersion = 3.0
        ResppackLayoutUpdate logical = true;
        CSTPlotsVersion double {mustBeMember(CSTPlotsVersion,[1,2])} = 2
        MPCPlotsVersion double {mustBeMember(MPCPlotsVersion,[1,2])} = 2
    end
    methods (Access = private)
        function obj = CSTCustomSettings
        end
    end
    methods (Static)
        function singleObj = getInstance
            mlock
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = controllibutils.CSTCustomSettings;
            end
            singleObj = localObj;
        end
                     
        function setControlSystemDesignerVersion(Value)
            if ismember(Value,[1,2,3])
                obj = controllibutils.CSTCustomSettings.getInstance;
                obj.ControlSystemDesignerVersion = Value;
            else
                error(message('Controllib:general:UnexpectedError','Version input must be 1,2 or 3.'))
            end
        end
        
        function Value = getControlSystemDesignerVersion
            obj = controllibutils.CSTCustomSettings.getInstance;
            Value = obj.ControlSystemDesignerVersion;
        end
        
        % Resppack Layout flag
        function setResppackLayoutUpdate(Value)
            obj = controllibutils.CSTCustomSettings.getInstance;
            obj.ResppackLayoutUpdate = Value;
        end
        
        function Value = getResppackLayoutUpdate()
            obj = controllibutils.CSTCustomSettings.getInstance;
            Value = obj.ResppackLayoutUpdate;
        end

        % Controls Plot Version
        function oldValue = setCSTPlotsVersion(Value)
            obj = controllibutils.CSTCustomSettings.getInstance;
            oldValue = obj.CSTPlotsVersion;
            obj.CSTPlotsVersion = Value;
        end

        function Value = getCSTPlotsVersion()
            obj = controllibutils.CSTCustomSettings.getInstance;
            Value = obj.CSTPlotsVersion;
        end

        % Model Predictive Control Plot Version
        function oldValue = setMPCPlotsVersion(Value)
            obj = controllibutils.CSTCustomSettings.getInstance;
            oldValue = obj.MPCPlotsVersion;
            obj.MPCPlotsVersion = Value;
        end

        function Value = getMPCPlotsVersion()
            obj = controllibutils.CSTCustomSettings.getInstance;
            Value = obj.MPCPlotsVersion;
        end
    end
end

