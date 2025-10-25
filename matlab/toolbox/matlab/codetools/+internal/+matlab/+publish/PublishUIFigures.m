classdef PublishUIFigures < internal.matlab.publish.PublishFigures
%

% Copyright 2020 The MathWorks, Inc.

    methods
        function obj = PublishUIFigures(options)
            obj = obj@internal.matlab.publish.PublishFigures(options);
        end
    end
    
    methods(Static)
        function imgFilename = snapFigure(f,imgNoExt,opts)                        
             method = 'getframe';
             % Nail down the image format.
            if isempty(opts.imageFormat)
                imageFormat = internal.matlab.publish.getDefaultImageFormat(opts.format,method);
            else
                imageFormat = opts.imageFormat;
            end
            
            % Nail down the image filename.
            imgFilename = internal.matlab.publish.getPrintOutputFilename(imgNoExt,imageFormat);
            
            myFrame = snapIt(f, {});
           
            % Debug info
            comment = getFigureComment(f);
            
            % Finally, write out the image file.
            internal.matlab.publish.resizeIfNecessary(imgFilename,imageFormat,opts.maxWidth,opts.maxHeight,myFrame,comment);
        end
    end
end

%===============================================================================

function c = getFigureComment(f)
    c = getDebugCommentForImage(f);
end