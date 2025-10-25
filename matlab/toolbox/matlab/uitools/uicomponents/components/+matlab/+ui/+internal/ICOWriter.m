classdef (Sealed, Abstract) ICOWriter < handle
    % ICOWRITER Utility function to create a Windows ICO file from PNG file(s)
    
    methods(Static)
        function writeICOFile(fileName, varargin)
            %WRITEICOFILE   Create a Windows ICO file out of the list of PNG files provided.
            %
            %   Usage:
            %       writeICOFile [output file] [PNG icon files ...]
            %
            %   Description:
            %
            %       filename - The name of the output ICO file
            %       varargin - Names of the PNG image files to combine into an ICO file
            %
            %   Example:
            %        matlab.ui.internal.ICOWriter.writeICOFile('out.ico','image1.png','image2.png');
            %
            %   For more information on the ICO file format and header description, see:
            %   http://msdn.microsoft.com/en-us/library/ms997538.aspx
            
            % Copyright 2020 The MathWorks, Inc.
            
            if ~ispc
                error('MATLAB:ui:internal:ICOWriter:UnsupportedPlatform', ...
                    'This functionality is only supported on Windows');
            end
            
            imageData = cell(1, length(varargin));
            for idx = 1:length(varargin)
                imageData{idx} = matlab.ui.internal.ICOWriter.getImageData(varargin{idx});
            end
            
            [folder, ~, ~] = fileparts(fileName);
            if exist(folder,'dir') ~= 7
                mkdir(folder);
            end
            h = fopen(fileName, 'w+');
            matlab.ui.internal.ICOWriter.writeIcoHeader(h, length(varargin));
            
            offset = 6 + 16 * length(varargin); % ico header + total image headers
            
            try
                for idx = 1:length(varargin)
                    a = imageData{idx};
                    if ~a(17) && ~a(18) && ~a(19)
                        height = a(20); % there are 4 bytes height in a png.  ICO only uses 1 byte
                    elseif ~a(17) && ~a(18)
                        height = 255;
                    else
                        error('MATLAB:ui:internal:ICOWriter:InvalidDimensions', ...
                              'Invalid dimensions');
                    end
                    if ~ a(21) && ~a(22) && ~a(23)
                        width = a(24);  % there are 4 bytes of width in a png.  ICO only uses 1 byte
                    elseif ~a(21) && ~a(22)
                        width = 255;
                    else
                        error('MATLAB:ui:internal:ICOWriter:InvalidDimensions', ...
                              'Invalid dimensions');
                    end
                    matlab.ui.internal.ICOWriter.writeImageHeader(h, height, width, length(imageData{idx}), offset);
                    offset = offset + length(imageData{idx});
                end
                
                for idx = 1:length(varargin)
                    matlab.ui.internal.ICOWriter.writeImageData(h, imageData{idx});
                end
            catch e
                disp(e.message)
            end
            fclose(h);
            
        end
        
    end
    
    methods(Static, Access = private)

        function imageData = getImageData(fileName)
            h = fopen(fileName);
            imageData = fread(h, inf, '*uint8');
            fclose(h);
        end
        
        function writeIcoHeader(h, numImages)
            header = zeros(1, 6, 'uint8');
            header(3) = 1;
            header(5) = uint8(numImages);
            fwrite(h, header, '*uint8');
        end
        
        function writeImageHeader(h, height, width, size, offset)
            imageHeader = zeros(1, 8, 'uint8');
            imageHeader(1) = uint8(height);
            imageHeader(2) = uint8(width);
            imageHeader(5) = 1;
            imageHeader(7) = 24; % color depth
            fwrite(h, imageHeader, '*uint8');
            
            size = uint32(size);
            fwrite(h, size, '*uint32');
            
            offset = uint32(offset);
            fwrite(h, offset, '*uint32');
        end
        
        function writeImageData(h, data)
            fwrite(h, data, '*uint8');
        end
        
    end
    
end

