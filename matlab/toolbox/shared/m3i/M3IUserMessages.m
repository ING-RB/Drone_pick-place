%

%   Copyright 2009-2010 The MathWorks, Inc.
classdef M3IUserMessages < handle

    % singleton
    properties (Access=public, Constant)
        instance = M3IUserMessages();
    end
    
    % public interface
    methods (Access=public, Static)
        function show()
            M3IUserMessageStream.addStreamListener(M3IUserMessages.instance);
        end
        
        function hide()
            M3IUserMessageStream.removeStreamListener(M3IUserMessages.instance);
        end
    end
    
    % M3IUserMessageStream listener implementation.    
    methods (Access=public)
        function clear(self)
        end
        
        function handleMessage(self, type, classifier, source, summary, reportedBy, details)
            classifier = self.tweakMessage(classifier);
            str = sprintf('%s : %s : %s', type, classifier, details);
            disp(str);
        end
        
        function flush(self)
        end
               
        
        % Format the string that is displayed in the Message field
        % Show up to two words from the original string
        function msg = tweakMessage(self, msg)
            strs = regexp(msg, ' ', 'split');
            if numel(strs) > 1
                msg = [strs{1} ' ' strs{2}];
            else
                msg = strs{1};
            end
        end        
    end
    
      
end

% LocalWords:  IUser
