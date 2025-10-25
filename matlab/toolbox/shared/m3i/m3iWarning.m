function m3iWarning(varargin)
% Usage: m3iWarning(source, messageId, extra argments)
%        e.g: m3iWarning('Clipboard', 'M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB')
% Usage: m3iWarning(messageId, extra argments)
%        e.g: m3iWarning('M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB') 
    m3iMessage(2, varargin{:});
end


