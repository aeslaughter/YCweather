function callback_settime(hObject,~)
% CALLBACK_SETTIME executes when user changes the start/end times
%__________________________________________________________________________
% USAGE:callback_settime(hObject,eventdata)
%
% INPUT: hObject - Handle of calling function
%        eventdata - not used, MATLAB requied
%__________________________________________________________________________

try
% 1 - COLLECT INFORMATION FROM GUI
    h   = guihandles(hObject);      % Get Program control handles
    GUI = guidata(hObject);         % Get guidata

% 2 - EXTRACT MONTH,DAY,HR,MIN FROM GUI
    a = {'strt','end'}; b = {'year','month','day','hr','min'};

    for i = 1:length(a); for ii = 1:length(b);
        handle = h.([a{i},b{ii}]);
        str = get(handle,'String');
        if ischar(str); str = {str}; end
        t{i}{ii} = str{get(handle,'Value')};
    end,end

% 3 - CONVERT TO SERIAL FORMAT
    for i = 1:2;
        s = [t{i}{1},'-',t{i}{2},'-',t{i}{3},'-',t{i}{4},'-',t{i}{5}];
        time(i) = datenum(s,'yyyy-mmm-dd-HH-MM');
    end

% 4 - UPDATE GIUDATA
    GUI.time = time;        % Determine new time
    guidata(hObject,GUI);   % Set guidata
   
catch
    mes = ['Error updating selected date/time (callback_settime.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end
