function ex = processPrintingError(e, pj)
%PROCESSPRINTINGERROR Helper function for print

% Copyright 2013-2024 The MathWorks, Inc.

ex = [];
je = [];
msg = '';
isJSD = feature('webui');
if nargin < 2
    isUIF = isJSD;
else
    isUIF = matlab.ui.internal.isUIFigure(pj.ParentFig);
end
if isJSD || isUIF
    % functional only for Java figure
    return
end

PrintMsgID = 'MATLAB:print:';
if isa(e, 'matlab.exception.JavaException')
   je = e.ExceptionObject;
   if isa(je, 'com.mathworks.hg.util.OutputHelperProcessingException')
      % Extract the underlying cause of the processing error - if one was provided
      if ~isempty(je.getCause)
         je = je.getCause();
      end
   end
   % Extract the message - it might be an error ID
   if ~isempty(je.getMessage())
      msg = je.getMessage();
   end
elseif isa(e, 'MException') 
   if strcmp(e.identifier, 'MATLAB:graphics:java:GenericJavaException')
       msg = e.message;
       problemInOutputHelperPrefix = 'Problem while processing in an OutputHelper. ';
       msg = extractMessageID(msg, problemInOutputHelperPrefix, PrintMsgID); 
   elseif startsWith(e.identifier, 'MATLAB:graphics:java:')
       msg = e.message;
       javaLangException = 'java.lang.'; 
       msg = extractMessageID(msg, '', javaLangException); 
   end
end

if nargin < 2
    % if no printjob provided, assume we're not trying to use clipboard and
    % we're not interested in debug info 
    pj.DebugMode = false;
    goingToClipboard = false;
else
    % might be going to clipboard, and if there's an out of memory error
    % there are some things the user can try so we'll customize the message
    % for them...
    goingToClipboard = pj.DriverClipboard && isempty(pj.FileName);
end

if isa(je, 'com.mathworks.hg.util.HGRasterOutputHelper$RasterSizeException')
    ex = MException(message('MATLAB:print:InvalidRasterOutputSize'));    
elseif isa(je, 'java.lang.OutOfMemoryError') || startsWith(msg, 'java.lang.OutOfMemory')
    if goingToClipboard 
        ex = MException(message('MATLAB:print:clipboardCopyFailed'));
    else
        ex = MException(message('MATLAB:print:JavaHeapSize'));    
    end
elseif ~isempty(msg) && strncmp(msg, PrintMsgID, length(PrintMsgID))
    ex = MException(message(msg.toCharArray'));
end

if ~isempty(ex)
    if pj.DebugMode
        % Add the cause as extra debugging information.
        ex = ex.addCause(e);
    end
    
    ex.throwAsCaller()
end
end

function msg = extractMessageID(msg, prefix, msgIDString) 
% examine text of java message, if it starts with the specified prefix, look for
% the msgIDPrefix and return the ID associated with that.
% Otherwise, return original message 
   if isempty(prefix) || startsWith(msg, prefix)
       idx = strfind(msg, msgIDString);
       if ~isempty(idx)
          % msg starts with prefix and contains the msgIDString
          % so extract the messageID 
          idx = idx(1); % only deal with 1st 
          % extract message ID
          strs = split(msg(idx:end)); 
          msg = strs{1}; 
       elseif ~isempty(prefix)
          %discard prefix, if any, 
          msg = msg(length(prefix)+1:end);
       end
       msg = java.lang.String(msg);
   end
end
