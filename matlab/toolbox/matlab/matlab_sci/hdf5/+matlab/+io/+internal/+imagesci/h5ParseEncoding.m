function useUtf8 = h5ParseEncoding(inputArgs)
%H5PARSEENCODING forces utf-8 encoding of the input arguments
%
%   USEUTF8 = H5PARSEENCODING(INPUTARGS) returns a logical bool true if the
%   h5 input arguments to 'h5info' and 'h5disp' are treated as UTF-8
%   encoded text
%
%   See also H5INFO, H5DISP

%   Copyright 2017-2022 The MathWorks, Inc.

    useUtf8 = false ;
    % If text encoding is not set, return 'false'
    if isempty(inputArgs)
        return
    end

    if numel(inputArgs) ~= 2
        error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'));
    end

    arg1 = inputArgs{1}; % should be 'TextEncoding'
    arg2 = inputArgs{2}; % should be 'UTF-8' or 'system'

    validatestring(arg1, "TextEncoding");
    validatestring(arg2, ["UTF-8", "system"]);

    % If text encoding is 'UTF-8', return 'true'
    if strcmpi(arg2, 'UTF-8')
        useUtf8 = true;
    end

end
