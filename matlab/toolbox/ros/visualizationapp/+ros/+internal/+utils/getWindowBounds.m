function location = getWindowBounds()
%getWindowBounds returns the location on the screen where the app should
%get lauched and the size of the app.
%The values supplied are interpreted as the window left and top positions,
% width and height in that order

screenSize = get(groot, 'ScreenSize');
appSize = round((3/4) * screenSize);
centerLocation = round((screenSize - appSize)/ 2);
location = [centerLocation(3) centerLocation(4) 0.80*screenSize(3) 0.7407*screenSize(4)];
end