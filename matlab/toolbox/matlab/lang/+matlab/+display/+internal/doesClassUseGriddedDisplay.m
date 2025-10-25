function doesClassUseGriddedDisplay = doesClassUseGriddedDisplay(arr)
% doesClassUseGriddedDisplay returns true for class arrays that have a
% gridded display format
    arguments(Input)
        arr {mustBeNonempty}
    end
    arguments(Output)
        doesClassUseGriddedDisplay (1,1) logical
    end

    doesClassUseGriddedDisplay = false;

    if isa(arr, "matlab.mixin.internal.MatrixDisplay")
        % Only classes that have a string converter method or
        % override convertObjectToStringForDisplay can be supported
        mc = metaclass(arr);
        strMC = findobj(mc.MethodList, Name = "string");
        % The string converter method can be defined by the array or any of
        % its super-classes
        doesClassHaveStringConverterMethod = ~isempty(strMC) && mc <= strMC.DefiningClass;
        convertObjectToStringMC = findobj(mc.MethodList, Name = "convertObjectToStringForDisplay");
        doesClassHaveObjToStringDispMethod = ~isempty(convertObjectToStringMC) && convertObjectToStringMC.DefiningClass ~= matlab.metadata.Class.fromName("matlab.mixin.internal.MatrixDisplay");
        doesClassUseGriddedDisplay =  doesClassHaveStringConverterMethod ||  doesClassHaveObjToStringDispMethod;
    elseif isa(arr, "char") || isenum(arr)
        doesClassUseGriddedDisplay = true;
    end
end
