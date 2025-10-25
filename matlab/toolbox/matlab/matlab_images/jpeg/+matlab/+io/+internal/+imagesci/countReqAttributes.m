function tg_count = countReqAttributes(element_maxp)
%COUNTREQATTRIBUTES counts the number of non-rdf and non-xml attributes
%   TG_COUNT = COUNTREQATTRIBUTES(ELEMENT_MAXP) returns the number of
%   attributes which do not belong to the RDF or the XML framework. It
%   returns the number of attributes associated with legit namespaces.
%   ELEMENT_MAXP is a child node of rdf:Description or any of its child
%   nodes.

%   Copyright 2022 The MathWorks, Inc.

    tg_count = 0;
    if(element_maxp.HasAttributes)

        maxp_attr = element_maxp.getAttributes();
        attr_len = getLength(maxp_attr) - 1;

        for attr_index = 0:attr_len

            attr_item = item(maxp_attr,attr_index);
            
            [nms_name,field_name] = matlab.io.internal.imagesci.splitNamespaceFieldName(attr_item.Name);
            % Accounting for the edge case where either the
            % namespace name or the field name might be missing. In
            % that case, ignore and move on to the next iteration
            % And, do not count the tags if the namespace is 'rdf' or 'xml'
            if isempty(nms_name)|| isempty(field_name) || any(strcmpi(nms_name, {'rdf','xml'}))
                continue;
            end
            
            tg_count = tg_count + 1;

        end

    end

end
