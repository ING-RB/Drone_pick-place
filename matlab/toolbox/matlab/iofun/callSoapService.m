function resp = callSoapService(endpoint,soapAction,theMessage)
%callSoapService Send a SOAP message off to an endpoint.
%   callSoapService(ENDPOINT,SOAPACTION,MESSAGE) sends the MESSAGE, a Java DOM,
%   to the SOAPACTION service at the ENDPOINT.
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
%   See also createClassFromWsdl, createSoapService, parseSoapResponse, 
%            matlab.wsdl.createWSDLClient.

% Copyright 1984-2020 The MathWorks, Inc.

% Use inline Java to send the message.

fname = mfilename;
error(message('MATLAB:webservices:WSDLDeprecationError', fname));
end
