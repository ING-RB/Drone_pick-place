classdef NMEASentenceParserGSA <  matlabshared.gps.internal.NMEASentenceParser
%NMEASentenceParserGSA creates a parser to extract GSA data

%   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","GSA","Mode","NA","FixType",nan,"SatellitesIDNumber",nan(1,12),"PDOP",nan,"VDOP",nan,"HDOP",nan,"SystemID",nan,"Status",uint8(2));
    end

    methods(Access = protected)
        function gsaData =  parseNMEALines(obj,data)
            gsaData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                gsaData.Status = uint8(0);
                % First Character is $, next two character is &
                gsaData.TalkerID = string(data(2:3));
                gsaData.MessageID = "GSA";
                delim = strfind(data,obj.Delimiter);
                delim = [delim,csIdx];
                minNumDelim = 18;
                if numel(delim)>= minNumDelim
                index = 1;
                mode = data(delim(index)+1:delim(index+1)-1);
                if ~isempty(mode)
                    gsaData.Mode = string(mode);
                end
                index = index+1;
                gsaData.FixType = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                for i = 1:12
                    sateliteNum = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    if ~isnan(sateliteNum)
                        gsaData.SatellitesIDNumber(i) = sateliteNum;
                    end
                    index = index+1;
                end
                gsaData.PDOP = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                gsaData.VDOP = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                gsaData.HDOP = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                if(numel(delim)>index)
                    % Only available in version 4.1 and above
                    gsaData.SystemID = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                end
                else
                   gsaData.Status = uint8(2); 
                end
            else
                % invalid checksum
                gsaData.Status = uint8(1);
            end
        end
    end
end
