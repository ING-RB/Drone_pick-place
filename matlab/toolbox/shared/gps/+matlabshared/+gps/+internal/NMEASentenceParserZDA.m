classdef NMEASentenceParserZDA <  matlabshared.gps.internal.NMEASentenceParser
%NMEASentenceParserZDA creates a parser to extract ZDA data

%   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct = struct("TalkerID","NA","MessageID","ZDA","UTCTime",NaT,"UTCDay",nan,"UTCMonth",nan,"UTCYear",nan,"LocalZoneHours",nan,"LocalZoneMinutes",nan,"Status",uint8(2));
    end

    methods(Access = protected)
        function zdaData =  parseNMEALines(obj,data)
            zdaData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                zdaData.Status = uint8(0);
                % First Character is $, next two character is &
                zdaData.TalkerID = string(data(2:3));
                zdaData.MessageID = "ZDA";
                delim = strfind(data,obj.Delimiter);
                delim = [delim,csIdx];
                minNumDelim = 7;
                if numel(delim)>= minNumDelim
                index = 1;
                utctime = data(delim(index)+1:delim(index+1)-1);
                 if(~isempty(utctime) && strlength(utctime)>=5)
                    utctime = real([str2double(utctime(1:2)),str2double(utctime(3:4)),str2double(utctime(5:end))]);
                      if ~isnan(utctime)
                    zdaData.UTCTime = datetime([0,0,0,utctime],'TimeZone','UTC','Format','HH:mm:ss.SSS');
                      end
                end
                index = index+1;
                zdaData.UTCDay = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                zdaData.UTCMonth = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                zdaData.UTCYear = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                zdaData.LocalZoneHours = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+1;
                zdaData.LocalZoneMinutes = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                else
                  zdaData.Status = uint8(2);
                end
                else
                zdaData.Status = uint8(1);
            end
        end
    end
end
