%ACTXSERVER Creates a COM Automation server.
%  H = ACTXSERVER('PROGID') Creates a local or remote COM Automation server
%  where PROGID is the programmatic identifier of the COM server and H is
%  the handle of the server's default interface. 
%
%  H = ACTXSERVER('PROGID', 'param1', value1,...) creates an ActiveX
%  server with optional parameter name/value pairs. Parameter names are:
%   machine:    specifies the name of a remote machine on which to launch 
%               the server.
%
%  Example:
%  h=actxserver('myserver.test.1', machine='machinename')
%
%  h=actxserver('myserver.test.1')
%
%
%  The following syntaxes are deprecated and will become obsolete.  They
%  are included for reference, but the above syntaxes are preferred.
%
%  H = ACTXSERVER(PROGID,'MACHINE') specifies the name of a remote machine 
%  on which to launch the server.
% 

% Copyright 2006-2023 The MathWorks, Inc.
