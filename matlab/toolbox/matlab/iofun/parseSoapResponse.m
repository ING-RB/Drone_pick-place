function varargout = parseSoapResponse(response)
%parseSoapResponse Convert the response from a SOAP server into MATLAB types.
%   parseSoapResponse(RESPONSE) converts RESPONSE, text returned by a SOAP server,
%   into a cell array of appropriate MATLAB datatypes.
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
%   See also createClassFromWsdl, callSoapService, createSoapMessage, 
%            matlab.wsdl.createWSDLClient.

% Copyright 1984-2020 The MathWorks, Inc.

% Parse the text into a DOM.
fname = mfilename;
error(message('MATLAB:webservices:WSDLDeprecationError', fname));
end