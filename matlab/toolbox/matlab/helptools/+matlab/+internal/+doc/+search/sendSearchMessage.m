function [success, response] = sendSearchMessage(endpoint, args)
    arguments
        endpoint (1,1) string
        args.Params struct = struct.empty
        args.Body = ''
    end


    success = false;
    response = [];

    url = connector.getUrl('messageservice/json/secure');
    options = weboptions('RequestMethod','post', ...
                         'MediaType','application/json', ...
                         'CertificateFilename', connector.getCertificateLocation);
    
    uri = matlab.net.URI("help/search/" + endpoint);
    if ~isempty(args.Params)
        uri.Query = matlab.net.QueryParameter(args.Params);
    end

    body = args.Body;
    if ~isempty(body) && ~ischar(body) && ~isstring(body)
        body = jsonencode(body);
    end

    MessageBody = struct('requestroute', char(uri), ...
                         'requestcontent', body);
    Message = struct('DocSearchMessage', {{MessageBody}});
    Body = struct('uuid', matlab.lang.internal.uuid, ... 
                  'messages', Message);
    try
        response = webwrite(url, Body, options);
        if nargout
            response = jsondecode(response.messages.DocSearchMessageResponse.results);
            success = ~isempty(response) && isfield(response,'success') && response.success;
        end
    catch
    end
end