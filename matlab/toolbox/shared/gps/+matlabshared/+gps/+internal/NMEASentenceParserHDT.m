classdef NMEASentenceParserHDT <  matlabshared.gps.internal.NMEASentenceParser
    %NMEASentenceParserHDT creates a parser to extract HDT data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties(Access = protected)
        NMEAOutputStruct = struct("TalkerID","NA","MessageID","HDT","TrueHeadingAngle",nan,"Status",uint8(2));
    end
    
    methods (Access = protected)
        function hdtData = parseNMEALines(obj,data)
            hdtData = obj.NMEAOutputStruct;
            validity = matlabshared.gps.internal.calculateCSValidity(data);
            if(validity == 1)
                hdtData.Status = uint8(0);
                % First Character is $, next two character is &
                hdtData.TalkerID = string(data(2:3));
                hdtData.MessageID = "HDT";
                delim = strfind(data,obj.Delimiter);
                index = 1;
                minNumDelim = 1;
                if numel(delim)>= minNumDelim
                    hdtData.TrueHeadingAngle = real(str2double(data(delim(index)+1:delim(index+1)-1)));
                else
                    hdtData.Status = uint8(2);
                end
            else
                % Invalid Checksum
                hdtData.Status = uint8(1);
            end
        end
    end
end
