function xmp_struct = getXMPMetadata(maxp_document)
%GETXMPMETADATA extracts XMP fields from a JPEG file
%   XMP_STRUCT = GETXMPMETADATA(MAXP_DOCUMENT) returns a structure
%   containing the XMP metadata fields. The input argument is an object of
%   the class matlab.io.xml.dom.Document

%   Copyright 2022 The MathWorks, Inc.

    xmp_struct = struct();
   
    % Find the rdf:Description tags and process it
    if maxp_document.hasChildNodes

        num_child = size(maxp_document.Children,2);

        for child_index = 1:num_child

            % Only process the child node if it is of class
            % matlab.io.xml.dom.Element. Else, skip
            if(isa(maxp_document.Children(child_index),'matlab.io.xml.dom.Element'))
                xmp_struct = matlab.io.internal.imagesci.getRDFDescription(maxp_document.Children(child_index),xmp_struct);
                
            end
        end
    end

end
