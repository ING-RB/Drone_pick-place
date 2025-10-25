function xmlLocSetEntityResolver(p,args)
%

% Copyright 2022-2024 The MathWorks, Inc.
for i=1:length(args)
    if isa(args{i},'org.xml.sax.EntityResolver')
        p.setEntityResolver(args{i});
        break;
    end
end

end