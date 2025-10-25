function Evaluate( str )
% Evaluate: Evaluate the string to execute it.
try
    evalin('base', str);
catch err
    errordlg(err.message, DAStudio.message('mg:textedit:errTitle'));
end
end
