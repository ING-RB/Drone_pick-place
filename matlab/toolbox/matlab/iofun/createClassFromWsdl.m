function name = createClassFromWsdl(wsdl)
%createClassFromWsdl Create a MATLAB object based on a WSDL-file.
%   createClassFromWsdl('source') creates MATLAB classes based on a WSDL 
%   application programming interface (API). The source argument specifies a URL
%   or file path to a WSDL API, which defines web service methods, arguments, 
%   and transactions. It returns the name of the new class.
%  
%   Based on the WSDL API, the createClassFromWSDL function creates a new folder
%   in the current directory. The folder contains a MATLAB file for each web service
%   method. In addition, two default MATLAB are created, the object's
%   display method (display.m) and its constructor (servicename.m).
%
%   Example
%  
%   cd(tempdir)
%   % Create a class for the web service provided by xmethods.net.
%   url = 'http://services.xmethods.net/soap/urn:xmethods-delayed-quotes.wsdl';
%   createClassFromWsdl(url);
%   % Instantiate the object.
%   service = StockQuoteService;
%   % getQuote returns the price of a stock.
%   getQuote(service,'GOOG')
%
%   This function will be removed in a future release.  For non-RPC/Encoded WSDLs,
%   use matlab.wsdl.createWSDLClient instead.
%
%   See also createSoapMessage, callSoapService, parseSoapResponse, 
%            matlab.wsdl.createWSDLClient.

% Copyright 1984-2020 The MathWorks, Inc.

% Parse the WSDL-file.
fname = mfilename;
error(message('MATLAB:webservices:WSDLDeprecationError', fname));
end

