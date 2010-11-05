function callback_press(hObject,eventdata)
% CALLBACK_PRESS operates when the secondary or primary button is pressed
% in the variable menu
%__________________________________________________________________________
% USAGE: callback_press(hObject,eventdata)
% 
% INPUT: hObject - handle of calling object
%        eventdata - not used, but reserved for MATLAB future use
% 
% OUTPUT: none
%__________________________________________________________________________

% Gets the gui handles for variable window
ax = get(hObject,'UserData');
h = guihandles(get(hObject,'parent'));

% Executes when primary button is pressed
if ax == 1;
    set(h.primary,'visible','on');
    set(h.primary_blank,'visible','on');
    set(h.primary_blank2,'visible','on');
    set(h.primary_blank3,'visible','on');
    set(h.primary_blank4,'visible','off');
    set(h.secondary,'visible','off');
    set(h.secondary_blank,'visible','off');

% Executes when secondary button is pressed
elseif ax == 2;
    set(h.primary,'visible','off');
    set(h.primary_blank,'visible','off');
    set(h.primary_blank2,'visible','off');
    set(h.primary_blank3,'visible','off');
    set(h.primary_blank4,'visible','on');
    set(h.secondary,'visible','on');
    set(h.secondary_blank,'visible','on');

end
