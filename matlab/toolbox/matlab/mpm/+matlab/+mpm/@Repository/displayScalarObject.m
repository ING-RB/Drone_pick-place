function displayScalarObject(obj)
    try
        s = obj.Name;
    catch exception
        if ~isequal(exception.identifier, 'mpm:repository:UnableToGetNameOfOffListRepository')
            throw(exception);
        end
        disp(getHeader(obj, true));
        pg = matlab.mixin.util.PropertyGroup(struct("Location", obj.Location));
        matlab.mixin.CustomDisplay.displayPropertyGroups(obj, pg);
        disp(getFooter(obj, true));
        fprintf("\n");
        return
    end
    displayScalarObject@matlab.mixin.CustomDisplay(obj);
end