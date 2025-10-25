classdef MessageLogger < handle
%

%   Copyright 2018 The MathWorks, Inc.

    properties
        GenerateMessages;
        HeaderMessages;
        totalConstructs;
        undefinedConstructs;
    end
    methods
        function dispGenerateMessages(obj)
            for msg = obj.GenerateMessages
                messageParams = cellstr(msg{:});
                disp(message(messageParams{:}).getString);
            end
        end
        function dispHeaderMessages(obj)
            for msg = obj.HeaderMessages
                firstMessageParams = cellstr(msg.firstMessage);
                secondMessageParams = cellstr(msg.secondMessage);
                disp(message(firstMessageParams{:}).getString);
                disp(message(secondMessageParams{:}).getString);
            end
        end
        function warningMessage = getGenerateMessages(obj)
            warningMessage = "";
            for msg = obj.GenerateMessages
                messageParams = cellstr(msg{:});
                warningMessage = warningMessage + message(messageParams{:}).getString + string(newline);
            end
        end
        function warningMessage = getHeaderMessages(obj)
            warningMessage = "";
            for msg = obj.HeaderMessages
                firstMessageParams = cellstr(msg.firstMessage);
                secondMessageParams = cellstr(msg.secondMessage);
                warningMessage = warningMessage + string(newline) + message(firstMessageParams{:}).getString + ...
                    string(newline) + message(secondMessageParams{:}).getString;
            end
        end
    end
end