function buildsidebars(gui)
% BUILDSIDEBARS constructs panels that attach to the side of the main
% Program Control window that allow the user to plot thermocouple data and
% add daily logs and images
%__________________________________________________________________________
% USAGE: buildsidebars(gui)
% 
% INPUT: gui = Program Control handle
%
% OUTPUT: none
%
% PROGRAM OUTLINE:
% 1 - BUILD PANEL FOR THERMOCOUPLE PLOTTER
% 2 - BUILD PLANEL FOR ADDING DAILY LOGS AND IMAGES
% 3 - BUILD SEARCH SIDE BAR
% 4 - EDIT DATA SIDE BAR
% 5 - SHOW SIDEBARS IF TURNED ON IN PREFERENCES
% SUBFUNCTION: setpanel
% SUBFUNCTION: baddata_buttons
%__________________________________________________________________________

% 1 - BUILD PANEL FOR THERMOCOUPLE PLOTTER
    % 1.1 - Build Thermocouple plotter panel
        hp = setpanel('Thermocouple Plotter:','TCpanel',gui);
        h  = guihandles(gui);
        p = get(h.TCpanel,'Position');  % Position of panel
    
    % 1.2 - Build strings for inputing into dropdown menus
        wtxt = p(3) - 1.5;      % Width of text labels
        top  = p(4) - 0.9;      % Top of panel
        label  = {'Exposed:','Plot Interval (min):'};
        poptag = {'surface','interval'};
        pop{1} = {'0','1','2','3','4','5','6','7','8','9','10','11',...
            '12','13','14','15','16','17','18','19','20'};
        pop{2} = {'1','2','5','15','30','60','120','240'};
    
    % 1.3 - Build dropdown menus for thermocouple window
    for i = 1:length(label) 
        bot = top - (i)*0.6;
        uicontrol('Parent',hp,'Style','text','Units','Centimeters',...
            'String',label{i},'HorizontalAlignment','right',...
            'position',[0,bot,wtxt,0.5]);
        uicontrol('Parent',hp,'Style','popupmenu','Units','Centimeters',...
            'Tag',poptag{i},'String',pop{i},...
            'position',[wtxt+0.1,bot+0.15,1.2,0.5]);
    end
    
    % 1.4 - Add plot button 
        uicontrol('Parent',hp,'Style','pushbutton','Units','Centimeters',...
            'String','Plot TC Data','Tag','plotbutton',...
            'Position',[0.5,bot-1.4,p(3)-1,0.7],...
            'Callback',{'callback_plotTCdata'});
    
% 2 - BUILD PLANEL FOR ADDING DAILY LOGS AND IMAGES
    % 2.1 - Build Add DailyLog and Image panel
        hp = setpanel('Add Logs and Images:','INPUTpanel',gui);
        h = guihandles(gui);
        p = get(h.INPUTpanel,'Position');

    % 2.2 - Build drop down menus with day and month
    top = p(4) - 0.7;
        % 2.2.1 - Month and Day labels
        uicontrol('Parent',hp,'Style','text','Units','Centimeters',...
            'String','Month','Position',[0.1,top-0.6,p(3)/2-0.2,0.6]);
        uicontrol('Parent',hp,'Style','text','Units','Centimeters',...
            'String','Day','Position',...
            [p(3)/2,top-0.6,p(3)/2-0.22,0.6]);
        
        % 2.2.2 - Month and day drop down menus
        mo  = get(h.endmonth,'String');  % Month items from main panel
        dy  = get(h.endday,'String');    % Day items from main panel
        smo = get(h.endmonth,'Value');   % Selected month
        sdy = get(h.endday,'Value');     % Selcectd day
        
        uicontrol('Parent',hp,'Style','popupmenu','Units','Centimeters',...
            'String',mo,'Position',[0.2,top-1.0,p(3)/2-0.4,0.6],...
            'Value',smo,'tag','add_month');
        uicontrol('Parent',hp,'Style','popupmenu','Units','Centimeters',...
            'String',dy,'Position',[p(3)/2+0.05,top-1.0,p(3)/2-0.4,0.6],...
            'Value',sdy,'tag','add_day');
    
    % 2.3 - Build buttons for adding images and daily logs
        uicontrol('Parent',hp,'Style','pushbutton','Units','Centimeters',...
            'String','Add Daily Log','Tag','addlog',...
            'Position',[0.5,top-2,p(3)-1,0.7],...
            'Callback',{'callback_add','log'});
        uicontrol('Parent',hp,'Style','pushbutton','Units','Centimeters',...
            'String','Add Image(s)','Tag','addimage',...
            'Position',[0.5,top-2.9,p(3)-1,0.7],...
            'Callback',{'callback_add','images'});
 
% 3 - BUILD SEARCH SIDE BAR
    % 3.1 - Build Add DailyLog and Image panel
        hp = setpanel('Search:','SEARCHpanel',gui);
        h = guihandles(gui);
        p = get(h.SEARCHpanel,'Position');

    % 3.2 - Build search functionality
    top = p(4) - 0.1;
        % 3.2.1 - Search input and search button
        uicontrol('Parent',hp,'Style','edit','Units','Centimeters',...
            'Position',[0.1,top-1.1,p(3)-0.3,0.5],...
            'BackgroundColor','w','tag','search');
        uicontrol('Parent',hp,'Style','pushbutton','Units',...
            'Centimeters','Position',[0.8,top-1.8,p(3)-1.6,0.6],...
            'String','SEARCH','Callback',{'callback_search'});
        
        % 3.2.2 - Results listbox
        uicontrol('Parent',hp,'Style','text','Units',...
            'Centimeters','Position',[0.1,top-2.6,p(3)-0.3,0.6],...
            'String','Results:','HorizontalAlignment','left',...
            'tag','numres');
        uicontrol('Parent',hp,'Style','listbox','Units',...
            'Centimeters','Position',[0.1,p(2)+0.05,p(3)-0.3,top-2.6],...
            'tag','results');

% 4 - SHOW SIDEBARS IF TURNED ON IN PREFERENCES
    % 4.1 - Get sidebar information
        GUI = guidata(gui);
        pref = GUI.settings.pref;
        fields = fieldnames(pref);
        
    % 4.2 - Loop through each side bar and check if settings are "on"    
        for i = 1:length(fields);
            sz = length(fields{i});
            if sz > 7; 
                if strcmpi(fields{i}(1:7),'sidebar');
                    cname = fields{i}(8:sz);
                    val = pref.(fields{i});
                    if val == 2; chk = 'on'; else chk = 'off'; end
                    set(h.([cname,'check']),'Checked',chk);
        end,end,end
     
    % 4.3 - Turn on selected sidebars    
        callback_sidebar([],[],gui); 
    
%--------------------------------------------------------------------------
% SUBFUNCTION: setpanel
function hp = setpanel(name,tag,gui,varargin)
% SETPANEL builds a panel in the Program Control gui for usage for various
% options
%__________________________________________________________________________
% USAGE: hp = setpanel(name,tag,gui)
% 
% INPUT: name = title to appear in panel
%        tag  = gat of uipanel object
%        gui  = Program Control handle
%
% OUTPUT: hp = panel handle
%__________________________________________________________________________

% 1 - DETERMINE THE PROGRAM CONTROL WINDOW SIZE
    h = guihandles(gui);                
    set(gui,'Units','Centimeters');
    SideOff = get(gui,'Position');      % Program Control window size

    % Width of panel to insert
    if isempty(varargin); Width = 4.15;
    else                  Width = varargin{1};
    end

    Pd = get(h.datepanel,'Position');   % Size of date/time panel

% 2 - BUILD THE PANEL
    L = SideOff(3);             % Left dimension
    B = Pd(1);                  % Bottom dimension
    W = Width - Pd(1);          % Width
    H = Pd(2) + Pd(4) - Pd(1);  % Height
    hp = uipanel('Parent',gui,'Units','Centimeters','Title',name,...
        'Tag',tag,'Position',[L,B,W,H],'FontWeight',...
        'Bold','Visible','off');    
    
%--------------------------------------------------------------------------
% SUBFUNCTION: baddata_buttons
function baddata_buttons(hObject,eventdata,grp)
% baddata_buttons adujsts the checkbox settings so that only a single
% selections can be made for the grouping given in "set1" and "set2" below
%__________________________________________________________________________
% USAGE: baddata_buttons(hObject,eventdata,grp)
% 
% INPUT: hObject   = calling objects handle
%        eventdata = not used, MATLAB required
%        grp       = number representing what set the button is in
%__________________________________________________________________________

% 1 - Get gui information
    selected = get(hObject,'Value');
    h = guihandles(hObject);

% 2 - If the box is checked then loop through all other boxes in the set, 
%     turning them off
if selected == 1;
    set1 = {'exact','greater','less','threshold'};
    set2 = {'entire','only'};

    if grp == 1; S = set1; else S = set2; end
    
    for i = 1:length(S); set(h.(S{i}),'Value',0);end

    set(hObject,'Value',1)
end












