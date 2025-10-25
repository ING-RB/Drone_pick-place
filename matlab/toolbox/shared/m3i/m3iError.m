function m3iError(varargin)
% Usage: m3iError(source, messageId, extra argments)
%        e.g: m3iError('Clipboard', 'M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB')
% Usage: m3iError(messageId, extra argments)
%        e.g: m3iError('M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB') 
    m3iMessage(1, varargin{:});
end


