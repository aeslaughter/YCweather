function callback_sidebar(hObject,eventdata,gui)
% CALLBACK_SIDEBAR opens or closes sidebars (i.e. items from the Window
% menu) in the Program Control menu
%__________________________________________________________________________
% USAGE: left = callback_sidebar(hObject,eventdata,gui)
%
% INPUT: hObject   = calling objects handle
%        eventdata = not used (MATLAB required)
%        gui       = Program Control window handle
%
% PROGRAM OUTLINE:
% 1 - SET THE CHECKED STATUS OF THE SELECTED ITEM
% 2 - RESTORE PROGRAM CONTROL TO STATE WITH NO SIDEBARS
% 3 - LOOP THROUGH EACH MENU ITEM AND ADD TO SIDE BAR IF CHECKED
%__________________________________________________________________________

% 1 - SET THE CHECKED STATUS OF THE SELECTED ITEM
    if ishandle(hObject);
        chk = get(hObject,'Checked');

        if strcmpi(chk,'on'); 
            set(hObject,'Checked','off');
        else
            set(hObject,'Checked','on');
        end
    end

% 2 - RESTORE PROGRAM CONTROL TO STATE WITH NO SIDEBARS
    h   = guihandles(gui);
    GUI = guidata(gui);
    set(gui,'Units','Centimeters');
    Pnow  = get(gui,'Position');
    Pmain = GUI.sidebar.alloff;
    Pmain = [Pnow(1),Pnow(2),Pmain(3),Pmain(4)];
    
% 3 - LOOP THROUGH EACH MENU ITEM AND ADD TO SIDE BAR IF CHECKED
    % 3.1 - Intilize parameters
        items = get(h.window,'Children');   % Items in Panel file menu
        Ptot = Pmain(3);                    % Position for first sidebar
        Pd = get(h.datepanel,'Position');   % Size of date/time panel
        ht = Pd(2) + Pd(4) - Pd(1);         % Height of sidebar
        
    % 3.2 - Search for checked items    
    for i = 1:length(items);
        chk = get(items(i),'checked');              % Check status
        handle = h.(get(items(i),'UserData'));      % Handle of sidebar
        set(handle,'Visible','off');                % Turn sidebars off

        tag  = get(handle,'Tag');               % Tag of selected sidebar
        name = ['sidebar',tag(1:length(tag)-5)];% Tag of preference option
        GUI.settings.pref.(name) = 1;           % Set pref to off
    
        % If Checked items is found add this sidebar
        if strcmpi(chk,'on');   
            set(handle,'Units','Centimeters');  % Set units
            P = get(handle,'Position');         % Get current position
           
            P(1) = Ptot;                        % New Left Position
            P(4) = ht;                          % New height
            Ptot = Ptot + P(3) + Pd(1);         % Next sidebar's position

            set(handle,'Position',P);           % Reposition sidebar
            set(handle,'Visible','on');         % Make sidebar visible
            GUI.settings.pref.(name) = 2;       % Set pref to on
        end
    end
    
    % 3.3 - Reposition the main window and return GUI information
        Pmain(3) = Ptot;
        set(gui,'Position',Pmain);
        set(gui,'Units','Normalized');
        guidata(gui,GUI);
        
 
    