classdef NMEASentenceParserGGA <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserGGA creates a parser to extract GGA data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","GGA","UTCTime",NaT,"Latitude",nan,"Longitude",nan,"QualityIndicator",nan,"NumSatellitesInUse",nan,"HDOP",nan,"Altitude",nan,"GeoidSeparation",nan,"AgeOfDifferentialData",nan,"DifferentialReferenceStationID",nan,"Status",uint8(2));
    end
    
    methods(Access = protected)
        function ggaData =  parseNMEALines(obj,data)
            ggaData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                ggaData.Status = uint8(0);
                % First Character is $, next two character is talker ID
                ggaData.TalkerID = string(data(2:3));
                ggaData.MessageID = "GGA";
                delim = strfind(data,obj.Delimiter);
                % Use CS as last delimiter
                delim = [delim,csIdx];
                minNumDelim = 15;
                if numel(delim)>= minNumDelim 
                    index = 1;
                    utctime = data(delim(index)+1:delim(index+1)-1);
                    if(~isempty(utctime) && strlength(utctime)>=5)
                        % Time format is hhmmss.ss.Decimal part may not be
                        % fixed
                        utctime = real([str2double(utctime(1:2)),str2double(utctime(3:4)),str2double(utctime(5:end))]);
                        % Only time needs to be displayed
                        if ~isnan(utctime)
                            ggaData.UTCTime = datetime([0,0,0,utctime],'TimeZone','UTC','Format','HH:mm:ss.SSS');
                        end
                    end
                    index = index+1;
                    latitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    latitudeD = data(delim(index)+1:delim(index+1)-1);
                    ggaData.Latitude = matlabshared.gps.internal.convertLatLong(latitude,latitudeD);
                    index = index+1;
                    longitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    longitudeD = data(delim(index)+1:delim(index+1)-1);
                    ggaData.Longitude = matlabshared.gps.internal.convertLatLong(longitude,longitudeD);
                    index = index+1;
                    ggaData.QualityIndicator = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    ggaData.NumSatellitesInUse = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    ggaData.HDOP = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    ggaData.Altitude = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+2;
                    ggaData.GeoidSeparation = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+2;
                    ggaData.AgeOfDifferentialData = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    ggaData.DifferentialReferenceStationID = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                else
                    ggaData.Status = uint8(2);
                end
            else
                % Invalid Checksum
                ggaData.Status = uint8(1);
            end
        end
    end
end
