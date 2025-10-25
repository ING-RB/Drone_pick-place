classdef EncodingInput < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.functions.HasAliases
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Parameter)   
        %ENCODING the character encoding used to interpret the bytes as text.
        %  Use '' to invoke auto-charset detection
        %
        % See also fopen
        Encoding = '';
    end
    
    methods      
        function opts = set.Encoding(opts,rhs)
            try
                if ~strcmp(rhs,'system')
                    % Verify encoding name is valid
                    native2unicode('',rhs);
                end
            catch
                throwAsCaller(MException(message('MATLAB:iofun:InvalidEncoding', string(rhs))));
            end
            opts.Encoding = convertStringsToChars(rhs);
        end
    end
    
    methods (Hidden)
        function v = getAliases(~)
            v = matlab.io.internal.functions.ParameterAlias("Encoding","FileEncoding");
        end
    end

    methods (Static,Hidden)
        function encoding = detectEncodingFromFilename(filename)
            fid = fopen(filename);
            [~, ~, ~, encoding] = fopen(fid);
            fclose(fid);
        end
        
        function t = encodingSuggestions()
            t = {'UTF-8','ISO-8859-1','windows-1251','GB2312','Shift_JIS','windows-1252','EUC-KR','GBK','EUC-JP'};
        end
    end
end
