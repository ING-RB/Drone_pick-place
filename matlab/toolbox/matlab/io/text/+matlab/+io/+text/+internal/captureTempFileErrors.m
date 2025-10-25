function out = captureTempFileErrors(fcn,text)
% Captures errors thrown when reading or writing to temporary text files.

% Copyright 2022 The MathWorks, Inc.
try
    out = fcn();
catch ME
    snippit = text{1}(1:min([20,end]));
    switch ME.identifier
        case 'MATLAB:io:xml:common:InvalidXMLFile'
            msg = message("MATLAB:io:xml:common:InvalidXMLData",snippit);
            ME = MException(msg);
        otherwise
            % If the error contains the "filename" we want to obscure 
            % that. Using a temp file is an implementation detail.
            if contains(ME.message,"inmem:")
                msg = message("MATLAB:io:common:text:CannotParseText",snippit);
                ME = addCause(MException(msg),ME);
            end
    end

    throwAsCaller(ME);
end
