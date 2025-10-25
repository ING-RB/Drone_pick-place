function m3iInfo(varargin)
% Usage: m3iInfo(source, messageId, extra argments)
%        e.g: m3iInfo('Clipboard', 'M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB')
% Usage: m3iInfo(messageId, extra argments)
%        e.g: m3iInfo('M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB') 
    m3iMessage(3, varargin{:});
end


