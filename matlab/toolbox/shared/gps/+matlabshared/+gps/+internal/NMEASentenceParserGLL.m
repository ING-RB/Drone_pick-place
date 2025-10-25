classdef NMEASentenceParserGLL <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserGLL creates a parser to extract GLL data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","GLL","Latitude",nan,"Longitude",nan,"UTCTime",NaT,"DataValidity","NA","PositioningMode","NA","Status",uint8(2));
    end
    
    methods (Access = protected)
        function gllData =  parseNMEALines(obj,data)
            gllData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                gllData.Status = uint8(0);
                % First Character is $, next two character is talker ID
                gllData.TalkerID = string(data(2:3));
                gllData.MessageID = "GLL";
                delim = strfind(data,',');
                % Use CS as last delimiter
                delim = [delim,csIdx];
                minNumDelim = 7;
                if numel(delim)>= minNumDelim
                    index = 1;
                    Latitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    LatitudeD = data(delim(index)+1:delim(index+1)-1);
                    gllData.Latitude = matlabshared.gps.internal.convertLatLong(Latitude,LatitudeD);
                    index = index+1;
                    Longitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    LongitudeD = data(delim(index)+1:delim(index+1)-1);
                    gllData.Longitude = matlabshared.gps.internal.convertLatLong(Longitude,LongitudeD);
                    index = index+1;
                    utctime = data(delim(index)+1:delim(index+1)-1);
                    if(~isempty(utctime) && strlength(utctime)>=5)
                        % Time format is hhmmss.ss.Decimal part may not be
                        % fixed
                        utctime = uint8(real([str2double(utctime(1:2)),str2double(utctime(3:4)),str2double(utctime(5:end))]));
                        if ~isnan(utctime)
                            gllData.UTCTime = datetime([0,0,0,utctime],'TimeZone','UTC','Format','HH:mm:ss.SSS');
                        end
                    end
                    index = index+1;
                    dataValidity = data(delim(index)+1:delim(index+1)-1);
                    if~isempty(dataValidity)
                        gllData.DataValidity = string(dataValidity);
                    end
                    index = index+1;
                    if(numel(delim)>index)
                        % Only available in version 4.1 and above
                        mode = data(delim(index)+1:delim(index+1)-1);
                        if~isempty(mode)
                            gllData.PositioningMode = string(mode);
                        end
                    end
                else
                    gllData.Status = uint8(2);
                end
            else
                % Invalid Checksum
                gllData.Status = uint8(1);
            end
        end
    end
end
