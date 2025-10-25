% Log a message

% Copyright 2014-2023 The MathWorks, Inc.

function logMessage(~, class, method, thismessage, logLevel, varargin)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    if bitand(utilsInstance.Debuglevel, logLevel)
        try
            msgStr = [class '.' method];
            if ~isempty(thismessage)
                msgStr = [msgStr ': [' thismessage ']'];
            end
            msgStr = [msgStr ' @ [' char(datetime('now', 'Format', 'yyyy/MM/dd HH:mm:ss.SSS')) ']'];
            for i=1:nargin-5
                if i==1
                    msgStr = [msgStr ' (']; %#ok<AGROW>
                else
                    msgStr = [msgStr ', ']; %#ok<AGROW>
                end
                if ischar(varargin{i})
                    msgStr = [msgStr varargin{i}]; %#ok<AGROW>
                elseif isnumeric(varargin{i}) || islogical(varargin{i})
                    msgStr = [msgStr mat2str(varargin{i})]; %#ok<AGROW>
                else
                    % Try to convert to a char
                    msgStr = [msgStr char(varargin{i})]; %#ok<AGROW>
                end
            end
            if nargin>4
                msgStr = [msgStr ')'];
            end
            logData = struct('eventType','log','message',msgStr);
            message.publish('/VElogmessage', logData);
        catch e
            warning(['LogError: ' e.message]);
        end
    end
end