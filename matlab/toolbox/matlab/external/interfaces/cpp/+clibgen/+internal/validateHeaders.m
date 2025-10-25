function validateHeaders(parser, headers)
% Validate the header files

%   Copyright 2024 The MathWorks, Inc.

    if ~iscellstr(headers) %#ok<*ISCLSTR>
        if isempty(headers) 
            error(message('MATLAB:CPP:EmptyHeaderFiles')); 
        end
        
        try
            validateattributes(headers,{'char','string'},{'vector','row'});   
        catch ME
            error(message('MATLAB:CPP:InvalidHeaderInputType'));
        end

        if headers == ""
            error(message('MATLAB:CPP:EmptyHeaderFiles')); 
        end

        if ismissing(headers)
            error(message('MATLAB:CPP:EmptyHeaderFiles'));
        end

        %check if header is any NV pair
        if (~isempty(parser) && isscalar(headers)) && ismember(headers, parser.Parameters)
            error(message('MATLAB:CPP:InterfaceFileNotSpecified', headers));
        end
    else
        if ~isrow(headers)
            error(message('MATLAB:CPP:InvalidHeaderInputType'));
        end
    end

    if ~isempty(find(startsWith(headers, "<"), 1))
        % at least one header seems to refer to a 'RootPaths' key
        % defer validation
        return;
    end

    headers = cellstr(convertStringsToChars(headers));
    for index = 1:length(headers)
        % Error if the header/source file is a wildcard character
        if strfind(headers{index}, '*') > 0
            error(message('MATLAB:CPP:InvalidHeaderFiles',headers{index}));
        end
        [status,~] = fileattrib(headers{index});
         if ~status
             [~,~,ext] = fileparts(headers{index});
             % Error out if multiple headers are specified in char arrays
             % instead of strings
             if ~isempty(ext)
                error(message('MATLAB:CPP:FileNotFound',headers{index}));
             end
        end
        if status
            [~,~,ext] = fileparts(headers{index});
            % Takes empty quotes in the first input
            if ((isempty(deblank(headers{index})) || (exist(headers{index},'dir') == 7)) && isempty(ext))
                % if first input has more than 1 file
                if ~isscalar(headers)
                    error(message('MATLAB:CPP:InvalidHeaderFiles',headers{index}));
                else
                    error(message('MATLAB:CPP:EmptyHeaderFiles'));
                end
            end
            if isempty(dir(headers{index}))
               error(message('MATLAB:CPP:InvalidHeaderFiles',headers{index}));
            end
            % Check for duplicate entry
            for i = index+1:length(headers)
                if strcmp(headers{i},headers{index})
                    error(message('MATLAB:CPP:DuplicateHeaderEntry',headers{index}));
                end
            end
            if ~isempty(ext)
                if ~(strcmp(ext,'.h')  || strcmp(ext,'.hpp') || strcmp(ext,'.hxx') || ...
                     strcmp(ext,'.cpp') || strcmp(ext,'.cxx'))
                        error(message('MATLAB:CPP:IncorrectFileExtension',headers{index}));
                end
            end
        end
    end
end

% LocalWords:  hxx cxx
