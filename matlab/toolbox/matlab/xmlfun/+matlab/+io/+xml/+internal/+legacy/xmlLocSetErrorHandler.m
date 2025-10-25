function xmlLocSetErrorHandler(p,args)
%

% Copyright 2022-2024 The MathWorks, Inc.
useDefaultErrorHandler = true;

for i=1:length(args)
    if isa(args{i},'org.xml.sax.ErrorHandler')
        p.setErrorHandler(args{i});
        useDefaultErrorHandler = false;
        break;
    end
end

if useDefaultErrorHandler
    p.setErrorHandler(org.xml.sax.helpers.DefaultHandler());
end

end