classdef NMEASentenceParserGST <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserGST creates a parser to extract GST data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct = struct("TalkerID","NA","MessageID","GST","UTCTime",NaT,"RMSStdDeviationOfRanges",nan,"StdDeviationSemiMajorAxis",nan,"StdDeviationSemiMinorAxis",nan,"OrientationSemiMajorAxis",nan,"StdDeviationLatitudeError",nan,"StdDeviationLongitudeError",nan,"StdDeviationAltitudeError",nan,"Status",uint8(2));
    end
    
    methods(Access = protected)
        function gstData =  parseNMEALines(obj,data)
            gstData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                gstData.Status = uint8(0);
                % First Character is $, next two character is Talker ID
                gstData.TalkerID = string(data(2:3));
                gstData.MessageID = "GST";
                delim = strfind(data,obj.Delimiter);
                delim = [delim,csIdx];
                minNumDelim = 9;
                if numel(delim) >= minNumDelim
                    index = 1;
                    utctime = data(delim(index)+1:delim(index+1)-1);
                    if(~isempty(utctime) && strlength(utctime)>=5)
                        utctime = real([str2double(utctime(1:2)),str2double(utctime(3:4)),str2double(utctime(5:end))]);
                        % Only time needs to be displayed
                        if ~isnan(utctime)
                            gstData.UTCTime = datetime([0,0,0,utctime],'TimeZone','UTC','Format','HH:mm:ss.SSS');
                        end
                    end
                    index = index+1;
                    gstData.RMSStdDeviationOfRanges = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.StdDeviationSemiMajorAxis = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.StdDeviationSemiMinorAxis = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.OrientationSemiMajorAxis = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.StdDeviationLatitudeError = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.StdDeviationLongitudeError = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                    index = index+1;
                    gstData.StdDeviationAltitudeError = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                else
                    gstData.Status = uint8(2);
                end
            else
                % invalid checksum
                gstData.Status = uint8(1);
            end
        end
    end
end
