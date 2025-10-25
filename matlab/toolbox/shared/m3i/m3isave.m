% Syntax: m3isave(filename, model)
function m3isave(filename, model)
    s = M3I.XmiWriterSettings;
    s.MultiPackageMetaModel = false;
    s.SerializeUuid = true;
    xwf = M3I.XmiWriterFactory;
    xw = xwf.createXmiWriter(s);
    xw.write(filename, model);
end
