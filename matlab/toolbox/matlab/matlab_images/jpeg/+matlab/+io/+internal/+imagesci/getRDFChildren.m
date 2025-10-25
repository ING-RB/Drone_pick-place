function info_output = getRDFChildren(maxp_element)
%GETRDFCHILDREN extracts the metadata fields from the child nodes
%
%   INFO_OUTPUT = GETRDFCHILDREN(MAXP_ELEMENT) returns a metadata field
%   value either as a struct/cell or a char array in INFO_OUTPUT.
%   MAXP_ELEMENT is a child node of rdf:Description or any of its child
%   nodes.

%   Copyright 2022 The MathWorks, Inc.


    info_output = struct();

    % start by counting the number of children and attributes of current node
    num_sub_child = size(maxp_element.Children,2);
    num_req_attr = matlab.io.internal.imagesci.countReqAttributes(maxp_element);

    % Case 1: If the node has only 1 sub child, it is the node value
    if(num_req_attr == 0 && num_sub_child==1)

        info_output = maxp_element.TextContent;

    % Case 2: If the node does not have any attributes and has more than one
    % value in a list in the sub nodes
    % rdf:Seq, rdf:Alt, rdf:Bag nodes don't have attributes
    elseif(num_req_attr == 0)
        rdf_list = 'null';
        for child_index = 1:num_sub_child

            sub_child = maxp_element.Children(child_index);
            if(isa(sub_child,'matlab.io.xml.dom.Element'))

                if(strcmp(sub_child.TagName,'rdf:Seq') || strcmp(sub_child.TagName,'rdf:Alt') || strcmp(sub_child.TagName,'rdf:Bag'))
                    % If we find rdf:Seq,rdf:Alt or rdf:Bag get the list out
                    rdf_list = sub_child;
                     
                    % getRDFArray is to be called to pull out the array
                    % list from rdf:Bag,rdf:Seq or rdf:Alt
                    info_output = matlab.io.internal.imagesci.getRDFArray(rdf_list);
            
                    % break out of the for loop since there can be only one
                    % rdf:Seq,rdf:Alt or rdf:Bag
                    break;
                
                else
                    info_output = hGetChildInfo(sub_child, info_output);
                end

            end

        end
        
    % Case 3: If the node has 1 or more attributes
    else
        % If child node has attributes, store them
        child_attr = maxp_element.getAttributes();
        attr_len = getLength(child_attr) - 1;

        for attr_index = 0:attr_len

            attr_item = item(child_attr,attr_index);
            % If the attribute is rdf:value, it is the value of the node
            attr_val = attr_item.Value;
            if(strcmp(attr_item.Name,'rdf:value'))
                info_output = attr_val;

                % Else, extract the attributes
            else
                [nms_name,field_name] = matlab.io.internal.imagesci.splitNamespaceFieldName(attr_item.Name);
                % Accounting for the edge case where either the
                % namespace name or the field name might be missing. In
                % that case, ignore and move on to the next iteration
                if isempty(nms_name)||isempty(field_name)
                    continue;
                end
                info_output.(field_name) = attr_val;

            end
        end

        % If the node has sub children but they are not array values nested inside
        % rdf:Seq,rdf:Alt or rdf:Bag tags
        if (num_sub_child > 1)
            % if node is nested, get all fields out
            for child_index = 1:num_sub_child
    
                sub_child = maxp_element.Children(child_index);
                if(isa(sub_child,'matlab.io.xml.dom.Element'))
                    info_output = hGetChildInfo(sub_child, info_output);
                end
    
            end
        end
    end

end


function info_output = hGetChildInfo(sub_child, info_output)
% Helper function to recurse into the child node and assign the data to
% the appropriate field

    % Recurse into this child node as the metadata
    % may be present in the children of 'sub_child'
    tempdata = matlab.io.internal.imagesci.getRDFChildren(sub_child);
    % According to the spec, the element content for an unqualified
    % XMP property with a structure value can be a nested
    % rdf:Description element
    if(strcmp(sub_child.TagName,'rdf:Description'))
        info_output = tempdata;
    else
        % Split the tag name into namespace name and field
        % name
        [nms_name,field_name] = matlab.io.internal.imagesci.splitNamespaceFieldName(sub_child.TagName);
        % Accounting for the edge case where either the
        % namespace name or the field name might be missing. In
        % that case, ignore and move on to the next iteration
        if isempty(nms_name)||isempty(field_name)
            info_output = [];
            return;
        end
        info_output.(field_name) = tempdata;

    end

end
