classdef NMEASentenceParserGSV <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserGSV creates a parser to extract GSV data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","GSV","NumSentences",nan,"SentenceNumber",nan,"SatellitesInView",nan,"SatelliteID",nan,"Elevation",nan,"Azimuth",nan,"SNR",nan,"SignalID",nan,"Status",uint8(2));
    end
    
    methods(Access = protected)
        function gsvData =  parseNMEALines(obj,data)
            gsvData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                gsvData.Status = uint8(0);
                % First Character is $, next two character is talker ID
                gsvData.TalkerID = string(data(2:3));
                gsvData.MessageID = "GSV";
                delim = strfind(data,obj.Delimiter);
                % Use CS as last delimiter
                delim = [delim,csIdx];
                minNumDelim = 3;
                numFields = numel(delim);
                if numFields >= minNumDelim 
                    index = 1;
                    gsvData.NumSentences = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gsvData.SentenceNumber = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gsvData.SatellitesInView= real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    i = 1;
                    % Satellite information contains 4 fields [satID,azimuth,elevation,SNR]
                    while(index <= numFields-4)
                       gsvData.SatelliteID(i) = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                       index = index+1;
                       gsvData.Elevation(i) = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                       index = index+1;
                       gsvData.Azimuth(i) = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                       index = index+1;
                       gsvData.SNR(i) = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                       index = index+1;
                       i = i+1;
                    end
                    if (index < numFields)
                        % This field is only available for version 4.1 and
                        % above
                        gsvData.SignalID = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    end
                else
                    gsvData.Status = uint8(2);
                end
            else
                % Invalid Checksum
                gsvData.Status = uint8(1);
            end
        end
    end
end