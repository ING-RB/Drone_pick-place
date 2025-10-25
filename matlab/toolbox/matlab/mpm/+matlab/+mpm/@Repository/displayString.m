function s = displayString(obj)
    try
        s = obj.Name;
    catch exception
        if ~isequal(exception.identifier, 'mpm:repository:UnableToGetNameOfOffListRepository')
            throw(exception);
        end
        s = obj.Location;
    end
end