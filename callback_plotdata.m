function callback_plotdata(hObject,eventdata,varargin)
% CALLBACK_PLOTDATA plots the selected data.
%__________________________________________________________________________
% USAGE: callback_plotdata(hObject,eventdata,varargin)
%
% INPUT: hObject     - calling objects handle
%        eventdata   - not used, MATLAB required
%        varargin{1} - handle of Program Control, used when called from
%           variable menu
%
% PROGRAM OUTLINE:
% 1 - PREPARE TO PLOT DATA
% 2 - PLOT DATA
% 3 - ADD FIGURE HANDLE TO GUIDATA
%
% FUNCTIONS CALLED:
%   [X,Y,L,ylab] = get_data(h_axes);
%__________________________________________________________________________

try
% 1 - PREPARE TO PLOT DATA
    % 1.1 - Get guidata
        if ~isempty(varargin); hObject = varargin{1}; end
        GUI = guidata(hObject);

    % 1.2 - Clear open figures (if desired)
        S = GUI.settings.pref;
        if S.clear == 1;
            C = ishandle(GUI.weather); 
            if C ~= 0; close(C); end 
        end
    
    % 1.3 - Capture date/time from Program Control
        D = GUI.time;

    % 1.4 - Test that variable menu is open
    if isempty(GUI.varwindow) || ~ishandle(GUI.varwindow);
        errordlg('You must have a variable menu open.','ERROR');
        return;
    end

    % 1.5 - Determine the desired linesyle and markers
        [line1,line2,mark1,mark2] = line_settings(S);

    % 1.6 - Determine the figure units and size settings
        switch GUI.settings.pref.figunits
            case 1; figunit = 'Inches';
            case 2; figunit = 'Centimeters';
            case 3; figunit = 'Normalized';
        end

        wd = GUI.settings.pref.figwidth;
        ht = GUI.settings.pref.figheight;

% 2 - PLOT DATA
    % 2.1 - Extract data from menus
       [C1,L1,ylab,list1]  = get_data(GUI.primary);
       [C2,L2,y2lab,list2] = get_data(GUI.secondary);
       
    % 2.2 - Build date/time title
        str = cellstr(datestr(GUI.time,'mmm-dd-yy HH:MM'));
        T = [str{1},' to ',str{2}];

    % 2.3 - Primary axis only
    if ~isempty(C1) && isempty(C2)
            fig = XYscatter(C1,'Legend',L1,'ylabel',ylab,'xlabel','Time',...
                    'Xtrim',D,'LineStyle',line1,'Marker',mark1,...
                    'XDatetick','on','Xlimit','off','LineWidth',S.width,...
                    'Interpreter','tex','Units',figunit,'Size',[wd,ht],...
                    'menubar','figure','title',T);
            set(fig,'UserData',list1);

    % 2.4 - Primary and secondary axis
    elseif ~isempty(C1) && ~isempty(C2)
        [fig] = XYscatter(C1,'Legend',L1,'ylabel',ylab,...
            'xlabel','Time','secondary',C2,'Legend2',L2,...
            'y2label',y2lab,'Xtrim',D,'LineStyle',line1,'LineStyle2',...
            line2,'Marker',mark1,'Marker2',mark2,'XDatetick','on',...
            'Xlimit','off','LineWidth',S.width,'Interpreter','tex',...
            'menubar','figure','title',T,'LineWidth2',S.width);
        set(fig,'UserData',[list1,list2]);
        
    % 2.5 - If nothing is selected
    else
        disp('No data selected!'); return;
    end

% 3 - ADD FIGURE HANDLE TO GUIDATA
    GUI.weather = [GUI.weather,fig];
    guidata(hObject,GUI);

catch
    mes = ['Error developing weather plot (callback_plotdata.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNTION: line_settings
function [L1,L2,M1,M2] = line_settings(S)
% LINE_SETTINGS sets the correct line and marker symbols from preferences

linestyle = {'-','--',':','-.','none'};
marker    = {'none','+','o','*','.','x','s','d','^','v','>','<','p','h'};

L1 = linestyle{S.primline}; L2 = linestyle{S.secline};
M1 = marker{S.primmarker};  M2 = marker{S.secmarker};
