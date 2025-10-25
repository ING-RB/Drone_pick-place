classdef ConnectErrorDocInfo < handle
    %CONNECTERRORDOCINFO Holds the information about the
    % troubleshooting connect error doc for ICT and MATLAB Hardware interfaces.

    %   Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        % Contains connect error troubleshooting doc information for each
        % ICT and MATLAB Hardware interface key.
        DocInfoMap containers.Map = instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.getMapInfo()
    end

    properties (Hidden, Constant)
        % Doc map locations for both ICT and MATLAB doc.
        DocIDMapLocICT = "matlab: helpview('instrument', "
        DocIDMapLocMATLAB = "matlab: helpview('matlab', "

        % Struct to hold all the interface names, doc link tag and doc map
        % location information for each interface. New interface names
        % along with doc tag and doc map location should be added as a new
        % entry in the struct as seen below.
        DocInfo = struct( ...
            "udpport", ["'udpport_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocICT], ... % For udpport
            "tcpserver", ["'tcpserver_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocICT], ... % For tcpserver
            "visadev", ["'visadev_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocICT], ... % For visadev
            "serialport", ["'serialport_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocMATLAB], ... % For serialport
            "tcpclient", ["'tcpclient_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocMATLAB], ... % For tcpclient
            "bluetooth", ["'bluetooth_connectError'", instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocIDMapLocMATLAB] ... % For bluetooth
            )
    end

    methods (Access = private, Static)
        function mapInfo = getMapInfo()
            % This helper function creates the container map from the doc
            % information struct provided.
            docInfo = instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocInfo;
            mapInfo = containers.Map;
            entries = string(fieldnames(docInfo)');
            for entry = entries
                mapInfo(entry) = docInfo.(entry);
            end
        end
    end
end