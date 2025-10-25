% %MSLDiagnostic - constructs a Simulink diagnostic object
% 
% DIAG = MSLDiagnostic(HANDLES, MSGID, DIAGMSG) constructs a Simulink diagnostic object, DIAG, of class MSLDiagnostic and assigns to that object a handle (HANDLES), an identifier (MSGID), and a diagnostic message (DIAGMSG). This object provides properties and methods to use in a program code for generating diagnostics, identifying the objects associated with a diagnostic, and responding to potentially erroneous situations.
% 
%     
% MSLDiagnostic instance is useful if it's not clear how to handle an erroneous
% Situation. Such an instance is reported without throwing an exception so the caller can make a decision later. 
%     
% HANDLES is a cell array of handles to objects, such as Simulink blocks,
% that are associated with the diagnostic.
%  
% MSGID is a unique message identifier string used to identify the source of the diagnostic. (See MESSAGE IDENTIFIERS in the help for the ERROR function.)
%  
% DIAGMSG is a character string that carries information about the cause of
% the diagnostic and may provide suggestions to correct the problematic condition. 
%  
% EXAMPLE:
% DIAG = MSLDiagnostic([1, 2], 'my:msg:id', 'my message');
%  
% DIAG = MSLDiagnostic(HANDLES, MESSAGE) constructs a Simulink diagnostic 
% object, DIAG, of the class MSLDiagnostic and assigns a handle(HANDLES) to that object. MESSAGE is a formatted internationalized message, which is  
% created with the method known as message. 
%  
% EXAMPLE:
% DIAG = MSLDiagnostic([1, 2], message('Simulink:utility:incompatRotationMirror',5,'test'));
%  
% DIAG = MSLDiagnostic(EX) constructs a Simulink diagnostic object, DIAG,
% of class MSLDiagnostic from MException/MSLException object.
% 
% Handles (if existing) convert to paths. If conversion is not possible, the corresponding path will be made equal to '-1'.
%  
% EXAMPLE:
% try
% . . .
% catch ME
% DIAG = MSLDiagnostic(ME);
% end
%  
% MSLDiagnostic methods:
% findID              - find diagnostic with given IDs
% report              - it depends on the value of the priority property:
%                           Diagnostic.Priority.Default
%                           Diagnostic.Priority.Info
%                               the same as reportAsInfo
%                           Diagnostic.Priority.Warning_Normal
%                               the same as reportAsWarning
%                           Diagnostic.Priority.Error
%                               the same as reportAsError
%                           Diagnostic.Priority.Warning_High
%                               undocumented, do not use
% reportAsError       - throw MSLException created from the diagnostic
% reportAsWarning     - issue warning created from the diagnostic
% reportAsInfo        - issue information created from the diagnostic
% getPriority         - return diagnostic's priority as an instance of 
%                       the Diagnostic.Priority class:
%                           Diagnostic.Priority.Default
%                           Diagnostic.Priority.Info
%                           Diagnostic.Priority.Warning_Normal
%                           Diagnostic.Priority.Warning_High
%                           Diagnostic.Priority.Error
% setPriority         - set diagnostic's priority.
%                       You can assign that property by using numeric values:
%                           0 for Diagnostic.Priority.Default
%                           1 for Diagnostic.Priority.Info
%                           2 for Diagnostic.Priority.Warning_Normal
%                           3 for Diagnostic.Priority.Warning_High
%                           4 for Diagnostic.Priority.Error
%                       You can also assign that property by using string or
%                       character vector (case insensitive):
%                           'default' or "default" for Diagnostic.Priority.Default
%                           'info' or "info" for Diagnostic.Priority.Info
%                           'warning' or "warning" for Diagnostic.Priority.Warning_Normal
%                           'error' or "error" for Diagnostic.Priority.Error
% getMsgToDisplay     - return message to display 
%                       (strip any HTML/XML artifacts from an underlying message object)
% addFixit            - add fixit action to MSLDiagnostic
% addSuggestion       - add suggestion to MSLDiagnostic  
%
%     MSLDiagnostic public fields:
%     identifier  - Character string that identifies the diagnostic
%     message     - Formatted diagnostic message to display	
%     stack       - Structure containing stack trace information
%     cause       - Cell array of MSLDiagnostics that caused this diagnostic
%     paths       - Cell array of strings that represent paths to the objects 
%                   involved in diagnostic creation. Paths are created from 
%                   handles, supplied at the time of MSLDiagnostic creation.
%                   If handles are invalid, the cell array element is '-1'.
%
%   See also HANDLE, DBSTACK, MESSAGE, MSLEXCEPTION, Diagnostic.Priority
%

%   Copyright 2015-2021 The MathWorks, Inc.
%   Built-in class.
