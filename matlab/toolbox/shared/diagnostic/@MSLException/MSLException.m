%MSLException - constructs an object, which is a subclass of the MATLAB 
%   MException class.
%   MSLE = MSLException(HANDLES, MSGID, ERRMSG) constructs a Simulink exception 
%   object, MSLE, of class MSLException and assigns to that object a handle 
%   (HANDLES), an identifier (MSGID), and an error message (ERRMSG). This  
%   object provides you with properties and methods to use in your program 
%   code for generating errors, for identifying the objects associated with  
%   an error, and for responding to errors.
%   
%   HANDLES is a cell array of handles to objects, such as Simulink blocks,
%   that are associated with the exception.
%
%   MSGID is a unique message identifier string to better identify the 
%   source of the error. (See MESSAGE IDENTIFIERS in the help for the ERROR 
%   function.)
%
%   ERRMSG is a character string that informs you about the cause of
%   the error and may suggest how to correct the faulty condition. 
%
%   EXAMPLE:
%      MSLE = MSLException([1, 2], 'my:msg:id', 'my message');
%
%   As with MException, you can use a TRY-CATCH block to capture the
%   exception:
%
%      errHndls = []
%      try
%         Perform one or more operations
%      catch E
%         if isa(E, 'MSLException');
%            errHndls = e.handles{1};
%         else %not a Simulink error
%            rethrow(E)
%         end
%      end
%
%   MSLE = MSLException(HANDLES, MESSAGE) constructs a Simulink exception 
%   object, MSLE, of class MSLException and assigns to that object a handle 
%   (HANDLES). MESSAGE is a formatted internationalized message, that can be 
%   created with the method message. You can extract MESSAGE back from
%   MSLE with the MSLException method messageID.
%
%   EXAMPLE:
%      MSLE = MSLException([1, 2], message('Simulink:utility:incompatRotationMirror',5,'test'));
%      msg = MSLE.messageID;
%
% MSLException methods:
% addFixit            - add fixit action to MSLException
% addSuggestion       - add suggestion to MSLException  
%
%   See also MEXCEPTION, HANDLE, ERROR, TRY, CATCH, DBSTACK, MESSAGE 

%   Copyright 2007-2021 The MathWorks, Inc.
%   Built-in function.
