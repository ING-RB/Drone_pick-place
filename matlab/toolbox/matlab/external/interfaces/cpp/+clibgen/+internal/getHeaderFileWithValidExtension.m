function results = getHeaderFileWithValidExtension(header)
% If header file is specified without extension, check if the header exists
% with extension .h or .hpp or .hxx

%   Copyright 2024 The MathWorks, Inc.

    if isfile(header)
        results = header;
        return
    end
    [~,~,ext]= fileparts(header);
    if ~isempty(ext)
        error(message('MATLAB:CPP:InvalidHeaderFiles',header));
    else
        extIn = {'.h','.hpp','.hxx'};
        n=0;
        for i = 1:length(extIn)
            file = [header,extIn{i}];
            if isfile(file)
                results = file;
                n=n+1;
            end
        end
        if n ~= 1
            error(message('MATLAB:CPP:FileNotFound',header));
        end
    end
end

% LocalWords:  hxx
