classdef NMEASentenceParserVTG <  matlabshared.gps.internal.NMEASentenceParser
%NMEASentenceParserVTG creates a parser to extract VTG data

%   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct= struct("TalkerID","NA","MessageID","VTG","TrueCourseAngle",nan,"MagneticCourseAngle",nan,"GroundSpeed",nan,"ModeIndicator","NA","Status",uint8(2));
    end

    methods(Access = protected)
        function vtgData =  parseNMEALines(obj,data)
            vtgData = obj.NMEAOutputStruct;
            [validity,csIdx] = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                vtgData.Status = uint8(0);
                % First Character is $, next two character is Talker ID
                vtgData.TalkerID = string(data(2:3));
                vtgData.MessageID = "VTG";
                delim = strfind(data,obj.Delimiter);
                % use csIdx * as last delimiter
                delim = [delim,csIdx];
                minNumDelim = 5;
                if numel(delim)>= minNumDelim
                index = 1;
                vtgData.TrueCourseAngle = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+2;
                vtgData.MagneticCourseAngle = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                index = index+2;
                vtgData.GroundSpeed = real(str2double(data(delim(index)+1:delim(index+1)-1)))*0.514444;
                index = index+4;
                if(numel(delim)>index)
                    % Only available in version 2.3 and above
                    mode = data(delim(index)+1:delim(index+1)-1);
                    if ~isempty(mode)
                        vtgData.ModeIndicator = string(mode);
                    end
                end
                else
                   vtgData.Status = uint8(2);
                end
            else
                vtgData.Status = uint8(1);
            end
        end
    end
end
