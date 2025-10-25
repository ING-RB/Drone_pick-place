function pageDimension = pdfInfo(filename)
% pageDimension = pdfInfo(filename) Returns the height and width of the 
% first page of specified pdf file. 

% Copyright 2017-2020 The MathWorks, Inc.
import java.io.File
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.PDPage

% Loading the PDF Document
try
f = File(filename);
docLoad = PDDocument.load(f);
catch ME
    % When is a JavaException, use exception class name 
    % instead of dumping a long java error stack
    if isa(ME,'matlab.exception.JavaException')
        % Error using rptgen.utils.pdfInfo (line 18)
        % Cannot compute image dimensions: filename.pdf
        %   Reason: class java.io.FileNotFoundException
        error(message('mlreportgen:dom_error:cannotComputeImageDimension', ...
            filename, char(ME.ExceptionObject.getClass)));
    else
        error(message('mlreportgen:dom_error:cannotComputeImageDimension', ...
            filename, ME.message));
    end
end

% Fetching the first page from the PDF Document
page = docLoad.getPage(0);

pageSize = page.getMediaBox();
ppi =  rptgen.utils.getScreenPixelsPerInch();

% Default Height and Width measurement units inside a PDF are in points
% and since each inch has 72 points we are dividing the height and width by 72
% The final value is multiplied by getScreenPixelsPerInch to get the value
% in pixels

pageDimension.Height = ((pageSize.getHeight())/72)*ppi;
pageDimension.Width = ((pageSize.getWidth())/72)*ppi;

docLoad.close();
end