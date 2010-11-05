function callback_click(hObject,eventdata)
% CALLBACK_CLICK operates when the user selects a variable.
%__________________________________________________________________________
% USAGE: callback_click(hObject,eventdata)
%
% INPUT:
%   hObject   - handle of selected object
%   eventdata - not utilized, MATLAB required
%
% PROGRAM OUTLINE:
% 1 - SET BUTTON/LISTBOX USER DATA
% 2 - UPDATE SELECTION STATUS OF CURRENT PANEL
% 3 - SET VISIBILITY SETTINGS OF UNIT PANELS
%__________________________________________________________________________

try
% 1 - SET BUTTON/LISTBOX USER DATA
    user = get(hObject,'UserData');
    switch get(hObject,'Style');

    % 1.1 - Case when a listbox is selected
        case 'listbox'
            idx  = get(hObject,'Value') - 1; % Selection status

            if idx(1) == 0;       % Case when 'none' is selected
                user.data  = [];
                user.label = {};
                user.value = 0;
            else                    % Case when data is selected
                user.data  = user.alldata(:,idx);
                user.label = user.alllabel(idx);
                user.value = 1;
                user.listitem = idx + 1;
            end
   
    % 1.2 - Case when a radio button is selected
    case 'radiobutton'
        user.value = get(hObject,'Value');
    end

    % 1.3 - Update UserData
        set(hObject,'UserData',user);

% 2 - UPDATE SELECTION STATUS OF CURRENT PANEL
    % 2.1 - Get parent handle, parent user data, and buttons in panel
        parent = get(hObject,'Parent');
        parent_user = get(parent,'UserData');
        hp = parent_user.buttons;

    % 2.2 - Search all the buttons in this panel, turn the panels value to
    %       1 if something is selected, 0 if nothing is selected
        for i = 1:length(hp);
            u = get(hp(i),'UserData');
            if u.value == 1; parent_user.value = 1; break;
            else
                parent_user.value = 0;
        end,end
   
    % 2.3 - Update the parent unit user data
        set(parent,'UserData',parent_user);

% 3 - SET VISIBILITY SETTINGS OF UNIT PANELS
    % 3.1 - Get unit panel handles from current axes (primary/secondary)
        h  = guihandles(hObject);
        U  = get(h.(user.axes),'UserData');
        hp = U.unit_panel; 

    % 3.2 - Search all unit panels for a selected value
        unit = '';
        for i = 1:length(hp);
            u = get(hp(i),'UserData');
            if u.value == 1; unit = u.unit; break; end
        end

    % 3.3 - Check status of mixed units button
        c = get(h.override,'Checked');
        if strcmpi(c,'On'); unit = ''; end

    % 3.4 - Set panels with non-matching units to 'off' 
        if isempty(unit); 
            hp_all = get(hp,'children');
            for i = 1:length(hp_all);
                set(hp_all{i},'enable','on');
            end
        else
            for i = 1:length(hp);
                u = get(hp(i),'UserData');
                if ~strcmpi(u.unit,unit);
                    set(get(hp(i),'children'),'enable','off');
        end,end,end
catch
    mes = ['Error selecting variables (callback_click.m), ',...
                'see errorlog.txt'];
    errorlog(mes);
end
