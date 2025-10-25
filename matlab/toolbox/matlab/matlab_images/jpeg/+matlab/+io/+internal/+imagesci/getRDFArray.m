function rdf_array = getRDFArray(rdf_list)
%GETRDFARRAY extracts XMP fields from array structures
%   [RDF_ARRAY] = GETRDFARRAY(RDF_LIST) returns a cell containing listed
%   metadata fields from rdf:Bag, rdf:Seq or rdf:Alt structures
%   RDF_LIST is a list of rdf:Bag, rdf:Seq or rdf:Alt nodes

%   Copyright 2022 The MathWorks, Inc.

    num_child = size(rdf_list.Children,2);
    rdf_array = cell(1,num_child);
    carray_ind = 1;

    for child_index = 1:num_child

        if(isa(rdf_list.Children(child_index),'matlab.io.xml.dom.Element'))
            % Only process the child node if it is a XML document object

            % Call the recursive function to obtain the array elements and
            % assign the value(s) to a new cell array
            rdf_li_element = matlab.io.internal.imagesci.getRDFChildren(rdf_list.Children(child_index));
            rdf_array{carray_ind} = rdf_li_element;
            carray_ind = carray_ind+1;

        end

    end
    % The MAXP object has 'Element' nodes and 'Text' nodes. The metadata is
    % present only in the 'Element' nodes, and not in the 'Text' nodes.
    % Hence, a cell array sized to the number of children (Element + Text
    % nodes) is created, and only the Element nodes are read. Then, the
    % cell array is resized.
    rdf_array(carray_ind:end) = [];

end
