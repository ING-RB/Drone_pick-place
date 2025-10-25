function schema = ErrorMenu( cbinfo )
    schema = DAStudio.ContainerSchema;
    schema.label = DAStudio.message('dastudio:studio:DIGErrorMenuBar');
    schema.tag = 'Studio:DIGError';
    schema.childrenFcns = { { @ErrorItem, cbinfo.userdata } };     
end

function schema = ErrorItem( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.label = DAStudio.message('dastudio:studio:DIGErrorPrintSchemaTree');
    schema.tag = 'Studio:EditSchema';
    schema.userdata = cbinfo.userdata;
    schema.callback = @EditSchemaCallback;    
end

function EditSchemaCallback( cbinfo )
    err = cbinfo.userdata;
    disp(err.getReport);
end
