function html = getNoHelpFoundContent(topic)

if ~isempty(topic)    
    help_str = getString(message('MATLAB:helpwin:NoHelpFound', sprintf('<span class="helptopic">%s</span>.', topic)));
    p1 = sprintf('<p>%s</p>', help_str);
    searchAction = matlab.internal.help.helpwin.formatMatlabLink(['docsearch(''' topic ''')']);    
    searchText = getString(message('MATLAB:helpwin:SearchInDocumentation', sprintf('<b>%s</b>', topic)));  
    p2 = sprintf('<p><a href="%s">%s</a>.</p>', searchAction, searchText);    
    html = sprintf('%s%s', p1,p2);    
else
    html = '';
end

end