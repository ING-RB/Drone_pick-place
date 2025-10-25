classdef NMEASentenceParserRMC <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserRMC creates a parser to extract RMC data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","RMC","FixStatus","NA","Latitude",nan,"Longitude",nan,"GroundSpeed",nan,"TrueCourseAngle",nan,"UTCDateTime",NaT,"MagneticVariation",nan,"ModeIndicator","NA","NavigationStatus","NA","Status",uint8(2));
    end
    
    methods (Access = protected)
        function rmcData =  parseNMEALines(obj,data)
            rmcData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                rmcData.Status = uint8(0);
                % First Character is $, next two character is talker ID
                rmcData.TalkerID = string(data(2:3));
                rmcData.MessageID = "RMC";
                delim = strfind(data,obj.Delimiter);
                delim = [delim,csIdx];
                minNumDelim = 12;
                if numel(delim)>= minNumDelim
                    index = 1;
                    time = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    fixStatus = data(delim(index)+1:delim(index+1)-1);
                    if ~isempty(fixStatus)
                        rmcData.FixStatus = fixStatus;
                    end
                    index = index+1;
                    Latitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    LatitudeD = data(delim(index)+1:delim(index+1)-1);
                    rmcData.Latitude = matlabshared.gps.internal.convertLatLong(Latitude,LatitudeD);
                    index = index+1;
                    Longitude = data(delim(index)+1:delim(index+1)-1);
                    index = index+1;
                    LongitudeD = data(delim(index)+1:delim(index+1)-1);
                    rmcData.Longitude = matlabshared.gps.internal.convertLatLong(Longitude,LongitudeD);
                    index = index+1;
                    rmcData.GroundSpeed = real(str2double(data(delim(index)+1:delim(index+1)-1)))*0.514444;
                    index = index+1;
                    rmcData.TrueCourseAngle = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    date = data(delim(index)+1:delim(index+1)-1);
                    rmcData.UTCDateTime = getDateTime(obj,date,time);
                    index = index+1;
                    rmcData.MagneticVariation = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    if(data(delim(index)+1:delim(index+1)-1)== 'W')
                        rmcData.MagneticVariation = -1*rmcData.MagneticVariation;
                    end
                    % There are some fields not given by all versions of NMEA
                    numData = numel(delim);
                    index = index+1;
                    if(numData>index)
                        % Only available in version 2.3 and above
                        rmcData.ModeIndicator = data(delim(index)+1:delim(index+1)-1);
                        index = index+1;
                        if(numData>index)
                            % Only available in version 4.1 and above
                            rmcData.NavigationStatus = data(delim(index)+1:delim(index+1)-1);
                        end
                    end
                else
                    rmcData.Status = uint8(2);
                end
            else
                rmcData.Status = uint8(1);
            end
        end
    end
    methods (Access = private)
        function datetimeUTC = getDateTime(~,date,time)
            % Time value should be at least 5 characters
            datetimeUTC = NaT;
            if (~isempty(time) && ~isempty(date))
                if (strlength(date)>=5 && strlength(time)>=5)
                  time = real([str2double(time(1:2)),str2double(time(3:4)),str2double(time(5:end))]);
                  date = real([str2double(['20',date(5:end)]),str2double(date(3:4)),str2double(date(1:2))]);
                  datetimeTemp = [date,time];
                  if ~all(isnan(datetimeTemp))
                      datetimeUTC = datetime(datetimeTemp,'TimeZone','UTC','Format','d-MMM-y HH:mm:ss.SSS');
                  end
                end
            end
        end
    end
end
