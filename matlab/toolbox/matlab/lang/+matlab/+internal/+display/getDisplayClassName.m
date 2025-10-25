function out = getDisplayClassName (inp)
    % This returns the full/ simple classname of the given
    % object based on the full name configuration of the 
    % class and the state of hyperlinks
    
    % Copyright 2017-2019 The MathWorks, Inc.
    
    s = settings;
    settingUsefullname = s.matlab.class.UseFullNameInDisplayHeader.ActiveValue;
    mc = metaclass(inp);
    mcUsefullname = mc.DisplayFullName;
    fullClassName = class(inp); 
    if settingUsefullname || mcUsefullname
        classname = fullClassName;
    else
        reg_expression = '[a-zA-Z_0-9]+\.';
        classname = regexprep(fullClassName, reg_expression, '');
    end

    if matlab.internal.display.isHot
        out = ['<a href="matlab:helpPopup(''' fullClassName ''')" style="font-weight:bold">' classname '</a>'];
    else
        out = classname;
    end
end
