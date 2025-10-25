function help(stmt)
% Given a stmt that evaluates to a property of the M3I.ClassObject, 
% isplays the meta-information stored in the cmof for 
%
% Usage: m3i.help('myClass.myProp') 
% or     m3i.help('myClass.myProp.at(3).moreStuff.etc')
    a = regexp(stmt, '\.');
    prefix = stmt(1:a(end)-1);
    target = stmt(a(end)+1:end);
    item = evalin('base', prefix);
    if ( isa(item, 'M3I.ClassObject') || isa(item, 'M3I.ImmutableClassObject'))
        y = @(a) disp(a.body);
        expr = sprintf('item.getMetaClass.getProperty(''%s'').ownedComment', target);
        m3i.foreach(eval(expr), y);
    else
        disp('No help available for things which are not M3I.ClassObjects');
    end
end