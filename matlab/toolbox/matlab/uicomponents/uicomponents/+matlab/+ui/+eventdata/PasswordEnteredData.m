classdef PasswordEnteredData< matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'PasswordEntered' events
    
    properties(SetAccess = 'private')
        Token;
    end
    
    methods
        function obj = PasswordEnteredData(token)
            % The token is a required input.
            narginchk(1,1);
            
            obj.Token = token;
        end
    end
end

