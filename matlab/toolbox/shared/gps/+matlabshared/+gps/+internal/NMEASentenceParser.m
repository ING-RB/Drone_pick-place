classdef NMEASentenceParser
% Parent class for sentence parser.

% Copyright 2020 The MathWorks, Inc.
    properties(Access = protected,Abstract)
        NMEAOutputStruct
    end

    properties(Access = protected)
        Delimiter = ',';
    end

    methods(Access = protected,Abstract)
        parsedData = parseNMEALines(obj,unparsedData);
    end

    methods
        function parsedData = parse(obj,unparsedData)
            numSentence = numel(unparsedData);
            % If cell array is empty,return cell array with status 2
            if (numSentence == 0)
                parsedData = obj.NMEAOutputStruct;
            else
                parsedData = repmat(obj.NMEAOutputStruct,numSentence,1);
                n = 1;
                while (n<=numSentence)
                    parsedData(n) = parseNMEALines(obj,unparsedData{n});
                    n = n+1;
                end
            end
        end
    end
end
