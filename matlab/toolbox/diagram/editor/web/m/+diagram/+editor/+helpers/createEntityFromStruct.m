function entity = createEntityFromStruct(operations, root, options)
    arguments
        operations (1,1) diagram.interface.Operations
        root (1,1) diagram.interface.Diagram
        options (1,1) struct {validateOptions}
    end
    fields = getValidFields();
    entity = operations.createEntity(root);
    if (isfield(options, fields.parent))
        operations.setParent(entity, options.parent);
    end
    if (isfield(options, fields.subDiagram))
        operations.setSubDiagram(entity, options.subDiagram);
    end
    if (isfield(options, fields.title))
        operations.setTitle(entity, options.title);
    end
    if (isfield(options, fields.type))
        operations.setType(entity, options.type);
    end
    if (isfield(options, fields.glyph))
        operations.setGlyph(entity, options.glyph);
    end
    if (isfield(options, fields.tag))
        operations.setTag(entity, options.tag);
    end
    if (isfield(options, fields.shape))
        operations.setShape(entity, options.shape);
    end
    if (isfield(options, fields.position))
        operations.setPosition(entity, options.position(1), options.position(2));
    end
    if (isfield(options, fields.size))
        operations.setSize(entity, options.size(1), options.size(2));
    end
    if (isfield(options, fields.attributeValue))
        operations.setAttributeValue(entity, options.attributeValue(1), options.attributeValue(2));
    end
end

function validateOptions(options)
    fields = fieldnames(options);
    validFields = getValidFields();
    for i=1:numel(fields)
        if ~isfield(validFields, fields{i})
            throw(MException('createEntityFromStruct:InvalidArgument', 'Invalid argument: %s', fields{i}));
        end
    end  
end

function fields = getValidFields()
    fields.parent = 'parent';
    fields.subDiagram = 'subDiagram';
    fields.title = 'title';
    fields.type = 'type';
    fields.glyph = 'glyph';
    fields.tag = 'tag';
    fields.shape = 'shape';
    fields.position = 'position';
    fields.size = 'size';
    fields.attributeValue = 'attributeValue';
end