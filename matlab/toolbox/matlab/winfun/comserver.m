function varargout = comserver(action, nv)
%COMSERVER Register, unregister, or query MATLAB COM server.
%   COMSERVER(ACTION) where ACTION is 'register', 'unregister', or 'query'.
%   An optional name-value pair may be specified when the ACTION is
%   'register' or 'unregister', where name is 'User' and value can be
%   'current' (default) or 'all'; see usage below.
%
%   COMSERVER('register') registers MATLAB as a COM server for the
%   current user only; does not require administrative privileges.
%   This is equivalent to COMSERVER('register','User','current').
%
%   COMSERVER('register','User','all') registers MATLAB as a COM server
%   for all users; requires administrative privileges.
%
%   COMSERVER('unregister') unregisters MATLAB as a COM server for the
%   current user only; does not require administrative privileges.
%   This is equivalent to COMSERVER('unregister','User','current').
%
%   COMSERVER('unregister','User','all') unregisters MATLAB as a COM
%   server for all users; requires administrative privileges.
%
%   S = COMSERVER('query') returns the path to the MATLAB executable
%   registered as a COM server for the current user and all users in the
%   struct S with two corresponding fields, User and Administrator.
%
%   See also ACTXSERVER, ACTXGETRUNNINGSERVER, ENABLESERVICE.
 
%   Copyright 2019 The MathWorks.

   arguments
        % add more comments about each argument
        action string {mustBeMember(action, ["register", "unregister", "query"])}
        nv.User string {mustBeMember(nv.User, ["current", "all"])}
    end
    
    if ~ispc
        error(message('MATLAB:COM:NonWindowsError'));
    end
    
    % Query does not take additional arguments
    if(action == "query") && isfield(nv, 'User')
       error ('MATLAB:COM:QueryError', getString(message('MATLAB:COM:QueryError'))); 
    end
    
    %call internal function
    [varargout{1:nargout}] = comserver_internal(action, nv);
end
