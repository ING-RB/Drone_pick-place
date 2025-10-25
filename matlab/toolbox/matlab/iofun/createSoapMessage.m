function dom = createSoapMessage(tns,methodname,values,names,types,style)
%createSoapMessage Create a SOAP message, ready to send to the server.
%   createSoapMessage(NAMESPACE,METHOD,VALUES,NAMES,TYPES,STYLE) creates a SOAP
%   message.  VALUES, NAMES, and TYPES are cell arrays.  NAMES will
%   default to dummy names and TYPES will default to unspecified.  STYLE
%   specifies 'document' or 'rpc' messages ('rpc' is the default).
%
%   Example:
%
%   message = createSoapMessage( ...
%       'urn:xmethods-delayed-quotes', ...
%       'getQuote', ...
%       {'GOOG'}, ...
%       {'symbol'}, ...
%       {'{http://www.w3.org/2001/XMLSchema}string'}, ...
%       'rpc');
%   response = callSoapService( ...
%       'http://64.124.140.30:9090/soap', ...
%       'urn:xmethods-delayed-quotes#getQuote', ...
%       message);
%   price = parseSoapResponse(response)
% 
%   This function will be removed in a future release.  For non-RPC/Encoded WSDLs,
%   use matlab.wsdl.createWSDLClient instead.
%
%   See also createClassFromWsdl, callSoapService, parseSoapResponse, 
%            matlab.wsdl.createWSDLClient.

% Copyright 1984-2020 The MathWorks, Inc.

% Default to made-up names.
fname = mfilename;
error(message('MATLAB:webservices:WSDLDeprecationError', fname));
end