function m3i_updateObjProperty(fStudioString, fId, fFilename, fPropertyName, fPropertyIndex)
%

%   Copyright 2008 The MathWorks, Inc.

    fObj = evalin('base', fStudioString);
    lModel = fObj.modelM3I;
    if(~fObj.isvalid()) 
        disp ('Obj is not valid');
        return;
    end
    
    fObjMeta = fObj.getMetaClass();
    fObjProperty = fObjMeta.getProperty(fPropertyName);
    if(~fObjProperty.isvalid()) 
        disp ('property is not valid');
        return;
    end
    
    fObjPropertyType = fObjProperty.type;
    if(strcmp(fObjPropertyType.name, 'String')~=1) 
        disp ('property type is not a string');
        return;
    end
    
    % do not allow changes to simulink model
    if fObj.getMetaClass() == SCP.Simulink.Model.MetaClass
        return;
    end
    if ~isempty(fObj.containerM3I) && fObj.containerM3I.getMetaClass() == SCP.Simulink.Model.MetaClass
        return;
    end 
    
    transaction = M3I.Transaction(lModel); 
    try
        lFactory = lModel.factory;
        currValueStr = file2strFcn(fFilename);
        currValue = lFactory.createFromString(fObjPropertyType.qualifiedName(), currValueStr);
        if(fPropertyIndex == -1)
            fObj.setOrAdd(fObjProperty, currValue);
        else
            % adding 1 to the index to correct for M based indexing
            values = fObj.get(fObjProperty);
            if(~values.isvalid) 
                disp('cannot find values for this object');
            end
            values.replace(fPropertyIndex+1, currValue );
        end
        transaction.commit();
        clear transaction;
    catch e
        clear transaction;
        rethrow(e);
    end
    
end

function str = file2strFcn(fileName)

fid = fopen(fileName, 'r');

if fid == -1
    fprintf(1,'Failed to open file ''%s'' for reading.\n',fileName);
    error('sam:matlabEditor:FileNotFound','Failed to open file %s',fileName);
end

F = fread(fid);
str = char(F');
fclose(fid);

end
