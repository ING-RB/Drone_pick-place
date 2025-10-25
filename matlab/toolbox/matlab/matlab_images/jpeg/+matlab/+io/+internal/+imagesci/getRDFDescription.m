function xmp_struct = getRDFDescription(maxp_element,xmp_struct)
%GETRDFDESCRIPTION extracts a list of all top-level rdf:Description elements
%   XMP_STRUCT = GETRDFDESCRIPTION(MAXP_ELEMENT, XMP_STRUCT) returns a
%   struct with the processed attributes and child nodes of top level
%   rdf:Description tags
%

%   Copyright 2022 The MathWorks, Inc.

    if(strcmp(maxp_element.TagName,'rdf:Description'))
        % If element is 'rdf:Description' process the attributes and
        % children
        xmp_struct = processRDFDescription (maxp_element, xmp_struct);
    else
        % If not recurse into the child nodes of maxp_element
        num_child = size(maxp_element.Children,2);

        for child_index = 1:num_child

            if(isa(maxp_element.Children(child_index),'matlab.io.xml.dom.Element'))
                % only recurse if child element is XML element
                xmp_struct = matlab.io.internal.imagesci.getRDFDescription(maxp_element.Children(child_index),xmp_struct);

            end

        end

    end

end

function xmp_struct = processRDFDescription(rdf_desc, xmp_struct)
% Helper function to process the attributes and child nodes of top level 
% rdf:Description tag and populate xmp_struct

    % Extract the attributes (if any)
    if(rdf_desc.HasAttributes)
        desc_attr = rdf_desc.getAttributes();
        % The indexing of the 'item' method starts from 0
        attr_len = getLength(desc_attr) - 1;
        for attr_index = 0:attr_len
            attr_item = item(desc_attr,attr_index);
            
            % In the XMP packet, the name of the field is of the
            % form 'namespace:field'. Split field name into namespace
            % name and field name
            [nms_name,field_name] = matlab.io.internal.imagesci.splitNamespaceFieldName(attr_item.Name);

            % Accounting for the edge case where either the
            % namespace name or the field name might be missing. In
            % that case, ignore and move on to the next iteration
            if isempty(nms_name) || isempty(field_name)
                continue;
            end

            attr_val = attr_item.Value;

            % Store field name within its namespace struct
            xmp_struct.(nms_name).(field_name) = attr_val;

        end
    end


    % Next we get all the children nodes
    num_children = size(rdf_desc.Children,2);

    for child_index = 1:num_children

        sub_child = rdf_desc.Children(child_index);

        if(isa(sub_child,'matlab.io.xml.dom.Element'))
            % In the XMP packet, the name of the field is of the
            % form 'namespace:field'. Split field name into namespace
            % name and field name
            [nms_name,field_name] = matlab.io.internal.imagesci.splitNamespaceFieldName(sub_child.TagName);

            % Accounting for the edge case where either the
            % namespace name or the field name might be missing. In
            % that case, ignore and move on to the next iteration
            if isempty(nms_name) || isempty(field_name)
                continue;
            end

            % The metadata can be present in the child nodes as
            % attributes and/or child of child nodes. The function
            % 'getRDFChildren' recurses into itself to extract all.
            xmp_struct.(nms_name).(field_name) = matlab.io.internal.imagesci.getRDFChildren(sub_child);

        end

    end
end