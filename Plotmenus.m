function [handles,gui,varargout] = Plotmenus(sta,MAINgui,fig,ax)
% PLOTMENUS builds the variable list for each station listed in "sta" and
% opens a primary or secondary axis option
%__________________________________________________________________________
% USAGE: [handles,gui,varargout] = Plotmenus(sta,MAINgui,fig,varargin)
%
% INPUT:
%   sta = cell array of station names (i.e. {'2007North',...})
%   MAINgui = handle for main program window
%   fig = handle for figure that variable lists are being inserted
%   varargin = empty it defaults to primary axis window
%              1 - primary axis window
%              2 - seoncdary axis window
%
% OUTPUT:
%   handles  = gui handles for current variable list
%   gui      = uipanel handle for current variable list
%   varargout{1} = button = handle for tab (primary or secondary) for
%                           current list
%   varagout{2}  = POS = Position vector for variable list
%
% PROGRAM OUTLINE:
% 1 - ESTABLISH THE PRIMARY/SECONDARY PANEL
    % 1.1 - Build the variable menu items
    % 1.2 - Establish the window name
    % 1.3 - Setup the dialog window (the size is initial arbitrary)
% 2 - BUILD STRUCTURE FOR STORING IN PRIMARY/SECONDARY USER DATA
% 3 - BUILD VARIALBE MENUS
    % 3.1 - Seperate data for the current station
    % 3.2 - Set station panel geometry
    % 3.3 - Establish station panel
    % 3.4 - Initilize storage structure for each station panel
    % 3.5 - Construct unit-specific panels within each station panel
        % 3.5.1 - Intilize the two dimensions that change (bottom & height)
        % 3.5.2 - Loop through each array in the stations variables
        % 3.5.3 - Count the number of listboxes in the current menu
        % 3.5.4 - Establish the geometry of the current panel
        % 3.5.5 - Establish the geometry of the buttons
        % 3.5.6 - Establish the current unit panel
        % 3.5.7 - Estabish the buttons & listboxs within the current panel       
        % 3.5.8 - Loop through each unit panel and place buttons/listboxes
        % 3.5.9 - Update storage structure with latest unit panel (jj)
    % 3.6 - Update storage structure with latest station panel (j)
    % 3.7 - Store information regarding the main panel for resizing to
% 4 - UPDATE STORAGE INFORMATION FOR PRIMARY/SECONDARY PANEL
% 5 - RESIZE THE PANELS
    % 5.1 - Resets the main station panels to align at the top
    % 5.2 - Resize the main dialog and inserts a header row
% 6 - BUILD PRIMARY/SECONDARY TABS
    % 6.1 - Button positions
    % 6.2 - Get colors
    % 6.3 - Actual buttons
    % 6.4 - Lines to help form tabs
% 7 - COLLECT THE DATA FROM THE GUI AND OUTPUT
% SUBFUNCTION: listbox_userdata
% SUBFUNCTION: variablemenus
%__________________________________________________________________________

% 1 - ESTABLISH THE PRIMARY/SECONDARY PANEL
        h = guihandles(MAINgui);

    % 1.1 - Build the variable menu items
        n = length(sta);
        for i = 1:n; station(i) = variablemenus(sta{i},4,MAINgui); end

    % 1.2 - Establish the window name
        if ax == 2; 
            ax_name = 'Secondary Axis (right-side)'; ftag = 'secondary';
        else
            ax_name = 'Primary Axis (left-side)';    ftag = 'primary';
        end
    
    % 1.3 - Setup the dialog window (the size is initial arbitrary)
        gui = uipanel('parent',fig,'Units','centimeters',...
            'Position',[0.5,0.5,15,15],'BorderWidth',2,...
            'Tag',ftag,'BorderType','beveledin','UserData','');

% 2 - BUILD STRUCTURE FOR STORING IN PRIMARY/SECONDARY USER DATA
    Haxis.buttons    = [];  % All button/listbox handles within panel
    Haxis.unit_panel = [];  % All unit panels contained in axes
    Haxis.sta_panel  = [];  % All station handles contained in axes
    Haxis.sta_name   = {};  % Names of stations
  
% 3 - BUILD VARIALBE MENUS
%      j - Loops through each station
%     jj - Loop through each unit panel in jth station
%      m - Loop through buttons/listboxes in jjth unit panel

for j = 1:n  % Loops each station 
    % 3.1 - Seperate data for the current station
        user = get(h.(sta{j}),'UserData');
        S    = station(j);

    % 3.2 - Set station panel geometry
        spc_p1  = 0.2;       % Spacing between panel and edges
        h_p1    = 15;        % Initial height (arbitrary)
        w_p1    = 5;         % Initial wideth (arbitrary)
        bot_p1  = spc_p1;    % Bottom location
        left_p1 = (j-1)*(w_p1 + spc_p1) + spc_p1; % Left location

    % 3.3 - Establish station panel
        sta_panel = uipanel('parent',gui,'Title',...
                [user.group,': ',user.display]);
            set(sta_panel,'Units','Centimeters');
            set(sta_panel,'Position',[left_p1,bot_p1,w_p1,h_p1]);           
            set(sta_panel,'FontAngle','italic');
            set(sta_panel,'FontSize',8);
            set(sta_panel,'FontWeight','bold');
            set(sta_panel,'BorderType','beveledout','BorderWidth',3);
            set(sta_panel,'Tag',[ftag,'_',sta{j}]);

    % 3.4 - Initilize storage structure for each station panel
        Hsta.buttons    = [];   % All buttons in current station panel
        Hsta.unit_panel = [];   % All unit panels in current station
        Hsta.Time       = user.Time;  % Time data for current station
     
    % 3.5 - Construct unit-specific panels within each station panel
        % 3.5.1 - Intilize the two dimensions that change (bottom & height)
            bot = 0;    h_p2 = 0;      

        % 3.5.2 - Loop through each array in the stations variables, 
        % counting from top to allow for temperature units to be at the
        % top of the list of variables
        for jj = length(S.title):-1:1;
            var = S.label{jj};      % Variables labels for current panel  
            fname = S.field{jj};    % Fieldnames of current variables
            unit  = S.unit{jj};     % Units of current panel
            sz_panel = length(var); % Number of buttons to build
 
        % 3.5.3 - Count the number of listboxes in the current menu, if
        % any element of menu is an array this item should be a listbox 
        % to save space in the window.
            num_box = 0;
            for q = 1:sz_panel    
                if iscell(var{q}); num_box = num_box + 1; end
            end

        % 3.5.4 - Establish the geometry of the current panel
            spc = 0.1;              % Spacing between panels
            left = spc;             % Position left from main panel
            w_p2 = w_p1 - 4*spc;    % Width of current panel

        % 3.5.5 - Establish the geometry of the buttons to be contained
        % within each window
            spc_btn = 0.12;                 % Space between buttons
            n_btn = sz_panel;               % Number of buttons
            ht_btn = 0.35;                  % Hieght of a sigle button
            w_btn = w_p2 - 2*spc_btn;       % Width of a button
            ht_box = 3*(ht_btn + spc_btn);  % Height of listbox

            % 3.5.5.1 - Calculate the bottom location and current height:
            %   bot = Bottom of first button, height from previous panel
                bot = bot + h_p2 + spc;         

            % 3.5.5.2 - Calculates height of the current panel adjusting
            %   for the presence of listboxes and/or buttons
                if num_box > 0
                    h_p2 = (n_btn - num_box) * (ht_btn + spc_btn)...
                        + 4*spc_btn + num_box*ht_box + num_box*spc_btn;
                else
                    h_p2 = (n_btn)*(ht_btn + spc_btn) + 4*spc_btn;
                end

        % 3.5.6 - Establish the current unit panel
        head = S.title{jj};
        panel = uipanel('Parent',sta_panel,'Title',head);
            set(panel,'Units','Centimeters','FontAngle','italic');
            set(panel,'Position',[left,bot,w_p2,h_p2]);
            set(panel,'BorderType','line','HighlightColor',[.5,.5,.5]);
            set(panel,'Tag',[ftag,'_',sta{j},'_',num2str(jj)]);

        % 3.5.7 - Estabish the buttons & listboxs within the current panel       
            bot_btn = spc_btn;  % Location of the first button
            
            Hunit.buttons = [];   % All buttons in current unit panel
            Hunit.unit    = unit; % Units associated with current panel
            Hunit.value   = 0;    % Selected status of unit panel

        % 3.5.8 - Loop through each unit panel and place buttons/listboxes
        for m = 1:sz_panel   % Loops through all of the buttons
            mm = sz_panel - (m-1);

            % 3.5.8.1 - Case when a listbox is needed
            if iscell(var{mm})  
                btn = uicontrol('parent',panel,'style','listbox');
                    set(btn,'Units','Centimeters','String',var{mm});
                    set(btn,'Max',2,'Min',0,'Fontsize',8);
                    set(btn,'Position',[spc_btn,bot_btn,w_btn,ht_box]);
                    set(btn,'Callback',{'callback_click'});
  
                % 3.5.8.1.1 - Updates the bottom location for next button
                    bot_btn = bot_btn + spc_btn + ht_box;     

                % 3.5.8.1.2 - Set listbox userdata
                    UserData = listbox_userdata(user,fname{mm});
                    UserData.name = user.display;
                    UserData.axes = ftag;
                    UserData.value = 0;
                    UserData.listitem = 0;
                    tag = ['Listbox_',num2str(ax),'_',...
                        num2str(j),'_',num2str(jj)];               
                    set(btn,'Tag',tag,'UserData',UserData);    

            % 3.5.8.2 - Case when a button is needed    
            elseif ischar(var{mm})
                btn = uicontrol('parent',panel,'style','radiobutton');
                    set(btn,'Units','Centimeters','FontSize',8);
                    set(btn,'String',var{mm});
                    set(btn,'Position',[spc_btn,bot_btn,w_btn,ht_btn]); 
                    set(btn,'Callback',{'callback_click'});

                % 3.5.8.2.1 - Updates the bottom location for next button 
                    bot_btn = bot_btn + spc_btn + ht_btn;  

                % 3.5.8.2.2 - Set user data for button
                    UserData = user.variables.(fname{mm});
                    UserData.time = user.Time;
                    UserData.name = user.display;
                    UserData.axes = ftag;
                    UserData.value = 0;
                    tag = [fname{mm},num2str(j),'_',num2str(ax)];
                    set(btn,'Tag',tag,'UserData',UserData);     
     
            end % ENDS 3.5.8.1 and 3.5.8.2 the if-statement for creating
                % button/listbox items

            % 3.5.8.3 - Update structures with latest button/listbox (m)
                % 3.5.8.3.1 - Primary/secondary axis panel structure
                    Haxis.buttons = [Haxis.buttons,btn];  
                % 3.5.8.3.2 - Station panel structure
                    Hsta.buttons  = [Hsta.buttons,btn];
                % 3.5.8.3.3 - Unit panel structure
                    Hunit.buttons = [Hunit.buttons,btn]; 

        end % ENDS 3.5.8: m-indexed loop for each variable in a unit panel 

        % 3.5.9 - Update storage structure with latest unit panel (jj)
                % 3.5.9.1 - Primary/secondary axis panel structure
                    Haxis.unit_panel = [Haxis.unit_panel,panel]; 
                % 3.5.9.2 - Station panel structure
                    Hsta.unit_panel = [Hsta.unit_panel,panel]; 
                % 3.5.9.3 - Set unit panel information
                    set(panel,'UserData',Hunit);
                
    end % ENDS 3.5: jj-indexed loop for each unit panel in a station

    % 3.6 - Update storage structure with latest station panel (j)
        % 3.6.1 - Primary/secondary axis panel structure 
            Haxis.sta_panel  = [Haxis.sta_panel,sta_panel];
            Haxis.sta_name   = [Haxis.sta_name,sta{j}];
        % 3.6.2 - Set station panel information
            set(sta_panel,'UserData',Hsta); 

    % 3.7 - Store information regarding the main panel for resizing to
    % fit the actual number of buttons
        ht(j) = bot + h_p2 + 3*spc_p1;
        l_p1(j) = left_p1;
        p1_id(j) = sta_panel;

end % ENDS 3: j-indexed loop for each station in a variable menu panel

% 4 - UPDATE STORAGE INFORMATION FOR PRIMARY/SECONDARY PANEL
    set(gui,'UserData',Haxis);

% 5 - RESIZE THE PANELS
    ht_max = max(ht);

    % 5.1 - Resets the main station panels to align at the top
        for i = 1:n
            bot_p1 = ht_max - ht(i) + 0.2;
            set(p1_id(i),'Position',[l_p1(i),bot_p1,w_p1,ht(i)]);
        end

    % 5.2 - Resize the main dialog and inserts a header row
        top = 0.2;
        w_gui = n*(w_p1 + spc_p1) + 2*spc_p1;
        h_gui = ht_max + top;

        % Adjust the width of seondary window to align adjacent to 
        % the primary window
        POS = [0.2,0.2,w_gui,h_gui + 0.3];
        set(gui,'Position',POS);

% 6 - BUILD PRIMARY/SECONDARY TABS
    % 6.1 - Button positions
        if ax == 2; 
            ax_name = 'Secondary (right)'; 
            tag = 'secondary';
            pos = [2.72,h_gui + 0.45,2.5,0.7];
            pos2 = [2.73,h_gui + 0.4,2.42,0.1];
            vis = 'off';
        else
            ax_name = 'Primary (left)';    
            tag = 'primary';
            pos = [0.22,h_gui + 0.45,2.5,0.7];
            pos2 = [0.27,h_gui + 0.4,2.4,0.1];
            vis = 'on';
        end

   % 6.2 - Get colors
        col = get(gui,'BackgroundColor');
        col = round(col*100)/100;
        col(3) = col(3) - 0.02;

   % 6.3 - Actual buttons
       button = uicontrol('parent',fig,'style','pushbutton',...
            'BackgroundColor',col,'Units','centimeters',...
            'callback',{@callback_press},'position',pos,...
            'UserData',ax,'String',ax_name,'tag',[tag,'button']);

   % 6.4 - Lines to help form tabs
        uicontrol('parent',fig,'style','text','BackgroundColor',col,...
            'units','centimeters','position',pos2,'Visible',vis,...
            'tag',[tag,'_blank']);   

        vert = [0.22,h_gui+0.45,0.05,0.7];
        h_pr = [0.22,h_gui+0.4+0.7,2.5,0.05];
        h_sc = [2.72,h_gui+0.4+0.7,2.5,0.05];

        shdw = get(gui,'ShadowColor');
        uicontrol('parent',fig,'style','text','BackgroundColor',shdw,...
            'units','centimeters','position',vert,'Visible',vis,...
            'tag',[tag,'_blank2']);  
        uicontrol('parent',fig,'style','text','BackgroundColor',shdw,...
            'units','centimeters','position',h_pr,'Visible',vis,...
            'tag',[tag,'_blank3']);  
        uicontrol('parent',fig,'style','text','BackgroundColor',shdw,...
            'units','centimeters','position',h_sc,'Visible',vis,...
            'tag',[tag,'_blank4']);             

% 7 - COLLECT THE DATA FROM THE GUI AND OUTPUT
    handles = guihandles(gui);
    varargout{1} = button;
    varargout{2} = POS;

%--------------------------------------------------------------------------
% SUBFUNCTION: listbox_userdata
function UserData = listbox_userdata(user,fname)
% LISTBOX_USERDATA builds data structure for listbox user data
UserData.time = user.Time;
UserData.data = []; % Storage for selected columns of .data
UserData.label = {};% Storage for selected labels
UserData.unit = user.variables.(fname{1}).unit;
for i = 1:length(fname);
    UserData.alldata(:,i) = user.variables.(fname{i}).data;
    UserData.alllabel{i}  = user.variables.(fname{i}).label;
end

%--------------------------------------------------------------------------
% SUBFUNCTION: variablemenus
function [OUTPUT] = variablemenus(sta,num,MAINgui)
% VARIABLEMENUS groups the weather station variables according to the units
% tag in the data struction of the desired station.
%__________________________________________________________________________
% USAGE: [OUTPUT] = variablemenus(sta,num,MAINgui)
% INPUT:
%   sta         = name of station to extract menu information
%   num         = the number of elements considered before using a listbox
%   MAINgui     = handle of program control window
%
% OUTPUT:
%   OUTPUT.label  = cell array of variable labels
%         .title  = cell array of panel titles
%         .field  = cell array of variable field names
%         .unit   = cell array of panel units
%
% NOTES:
%   - This function accounts for listbox entries by grouping similar items
%   into a cell array.  An example with 4 or more entries similar, consider
%   the following variable labels:
%       Wind Speed,  Air Temp., Snow Temp., and Thermcouple 1, 
%       Thermocouple 2, Thermocouple 3, ... , Thermocouple 10.
%
%   The data would look as follows,
%       OUTPUT.label{1} = {'Air Temp.','Snow Temp.',{1x10 cell}}
%       OUTPUT.label{2} = {'Wind Speed'};
%       OUTPUT.title    = {'Temperature (C)','WindSpeed (m/s)'}
%       OUTPUT.field{1} = {'AirTemp','SnowTemp',{'TC1',...,'TC10'}}
%       OUTPUT.field{2} = {'WindSpd'}
%       OUTPUT.unit     = {'C','m/s}
%
%       The {1x20} cell = {'Thermocouple 1', 'Thermocouple 2',...}
%
% PROGRAM OUTLINE:
% 1 - GETS THE WEATHER DATA FROM STATION BUTTON
% 2 - ORGANIZE THE VARIALBES BY UNITS
% 3 - LOOP THROUGH EACH GROUP, BUILDING OUTPUT STURCTURE
% 4 - SET OUTPUT STRUCTURE
%
% FUNCTIONS CALLED:
%   tag  = group_items(X.variables,unit,'unit');
%   heading{i} = getunit(unit{i}); 
%    [label{i},fields{i}] = build_listbox(label{i},field{i},num);
%__________________________________________________________________________  

% 1 - GETS THE WEATHER DATA FROM STATION BUTTON
    h  = guihandles(MAINgui);
    X  = get(h.(sta),'UserData');
    fn = fieldnames(X.variables);             % Names of each variable

% 2 - ORGANIZE THE VARIALBES BY UNITS
    % 2.1 - Seperate units from each variable
        for i = 1:length(fn); unit{i} = X.variables.(fn{i}).unit; end

    % 2.2 - Group according the units
        unit = unique(unit);   
        tag  = group_items(X.variables,unit,'unit');

% 3 - LOOP THROUGH EACH GROUP, BUILDING OUTPUT STURCTURE
for i = 1:length(tag);
    heading{i} = getunit(unit{i});                  % Panel headings
    
    cur = tag{i};                                   % Current variables
    for ii = 1:length(cur);
        label{i}{ii} = X.variables.(cur{ii}).label; % Variable label
        field{i}{ii} = cur{ii};                     % Variable fieldname
    end

    % Build list box arrays for repeating labels
    [label{i},field{i}] = build_listbox(label{i},field{i},num);
end
        
% 4 - SET OUTPUT STRUCTURE
    OUTPUT.label = label;
    OUTPUT.title = heading;
    OUTPUT.field = field;
    OUTPUT.unit  = unit;

%--------------------------------------------------------------------------
% SUBFUNCTION: build_listbox
function [out,Fout] = build_listbox(in,F,num)
% BUILD_LISTBOX takes simlarily named items from "in" and groups these
% names and the fieldnames in "F" into cell arrays for creating listbox
% items in the variable menus.
%__________________________________________________________________________
% USAGE: [out,Fout] = build_listbox(in,F,num)
%       
% INPUT: in = cell array of legend entries to group by first word
%        F  = associated structure fieldnames of these items
%        num = the number of matches requred before a listbox is made
%
% OUTPUT:
%   out = cell array of legend entries, if a list box is created these
%         items are given as a sub cell array
%   Fout = grouping of handle names
%__________________________________________________________________________

% 1 - SEPARATE THE FIRST WORD FROM LABLES
for i = 1:length(in);
    a = textscan(in{i},'%s',1); first{i} = a{1}{1};
end

% 2 - FIND UNIQUE ENTRIES
[a,b,c] = unique(first,'last');

% 3 - GROUP NON-UNIQUE ENTIRES 
for i = 1:length(b);
    eq = c == i;
    A{i} = in(eq);
    B{i} = F(eq);
end

% 4 - ONLY KEEP GROUPS LARGER THAN NUM
out = {}; Fout = {};
for i = 1:length(A);

    if length(A{i}) >= num
        out  = [out,A(i)];
        Fout = [Fout,B(i)];
    else
        for ii = 1:length(A{i});
            out  = [out,A{i}{ii}];
            Fout = [Fout,B{i}{ii}];
end,end,end

% 5 - SEARCH THROUGH DATA AND ADD 'none' TO CELL ARRAY DATA
for i = 1:length(out);
    if iscell(out{i}); out{i} = ['none',out{i}]; end
end
