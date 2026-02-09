function resampling_comparer(resultsFirst,resultsFirst100,resultsSecond,resultsSecond100, name1, name2)
% This function compares resampling results and plots them with various options.
% Input arguments:
%   - resultsFirst: resampling results for the first dataset
%   - resultsFirst100: 100% data for the first dataset
%   - resultsSecond: resampling results for the second dataset
%   - resultsSecond100: 100% data for the second dataset
%   - name1: name of the first dataset
%   - name2: name of the second dataset



%Prepare userData
userData = struct(...
    'resultsFirst',resultsFirst,...
    'resultsFirst100',resultsFirst100,...
    'resultsSecond',resultsSecond,...
    'resultsSecond100',resultsSecond100,...
    'type','Event spectrum',...
    'kmin',1e-17);


%Create Figure and Save Data
hFigResViewer=figure('Name',[name1,' and ', name2],'Units','normalized','Position',[.4 .4 .4 .5]);


%Create Axes
hAx=axes;


% Create text UI controls for displaying bleaching numbers
hTextBleachingNumFirst = uicontrol('Style', 'text', 'Units','normalized','HorizontalAlignment','left', 'Position', [0.02, .96, .6, .035]);
hTextBleachingNumSecond = uicontrol('Style', 'text', 'Units','normalized','HorizontalAlignment','left', 'Position', [0.02, .93, .6, .035]);

% Enable holding for overlaying multiple plot elements on the same axes
hold(hAx,'on')

% Create scatter plots for resampling data with different marker styles and colors
hResamplingFirst = scatter(hAx,NaN,NaN,'SizeData',20,'Marker','o','MarkerEdgeColor',[0.9290    0.6940    0.1250]);
hResamplingSecond = scatter(hAx,NaN,NaN,'SizeData',10,'Marker','x','MarkerEdgeColor',[0.3010    0.7450    0.9330]);

% Create stem plots for visualizing 100% data
h100FirstPlot = stem(hAx,NaN,NaN,'linewidth',1.5,'color','k','MarkerSize',2);
h100SecondPlot = stem(hAx,NaN,NaN,'linewidth',1.5,'color','r','MarkerSize',2);


%Context Menu
menuptr = uicontextmenu;
hAx.UIContextMenu=menuptr;

% Add menu items to the context menu with corresponding callbacks
uimenu(hAx.UIContextMenu,'Label','Event spectrum','Callback',@TypeChangedCB);
uimenu(hAx.UIContextMenu,'Label','State spectrum','Callback',@TypeChangedCB);
uimenu(hAx.UIContextMenu,'Label','Adjust plot style, axis limits and font size','Callback',@AdjustAxisLimitsDialog);

hLegend = legend(hAx, 'String', {'Resampling dataset 1', 'Resampling dataset 2', '100% dataset 1', '100% dataset 2'});
hLegend.Visible = 'off';


% Draw the plot
PlotSpec();

hold(hAx,'off')

%%Plotting functions


    function PlotSpec()

        %Draw spectrum into source axes

        %Fetch data
        curResultsFirst=userData.resultsFirst;
        curResultFirst100=userData.resultsFirst100;
        curResultsSecond=userData.resultsSecond;
        curResultSecond100=userData.resultsSecond100;

        % Get the number of resamplings for both datasets
        nResamplingsFirst = numel(curResultsFirst);
        nResamplingsSecond = numel(curResultsSecond);

        % Set up the axes properties
        hAx.YLim=[0 1.1];
        hAx.XScale='log';
        xlabel(hAx,'Dissociation rate (1/s)')
        ylabel(hAx,'Fraction')

        %------ Perform transformation between state and event spectrum based on the type-----------
        switch userData.type

            case 'State spectrum'
                % Normalize the data for the first dataset
                for resamplingIdx=1:nResamplingsFirst
                    curResultsFirst(resamplingIdx).S=curResultsFirst(resamplingIdx).S./curResultsFirst(resamplingIdx).k;
                    curResultsFirst(resamplingIdx).S=curResultsFirst(resamplingIdx).S/sum(curResultsFirst(resamplingIdx).S);
                end
                curResultFirst100.S=curResultFirst100.S./curResultFirst100.k;
                curResultFirst100.S=curResultFirst100.S/sum(curResultFirst100.S);

                % Normalize the data for the second dataset
                for resamplingIdx=1:nResamplingsSecond
                    curResultsSecond(resamplingIdx).S=curResultsSecond(resamplingIdx).S./curResultsSecond(resamplingIdx).k;
                    curResultsSecond(resamplingIdx).S=curResultsSecond(resamplingIdx).S/sum(curResultsSecond(resamplingIdx).S);
                end
                curResultSecond100.S=curResultSecond100.S./curResultSecond100.k;
                curResultSecond100.S=curResultSecond100.S/sum(curResultSecond100.S);
        end


        %-----Plot 100% data of first and second dataset-----------------------------

        set(h100SecondPlot,'XData',curResultSecond100.k,'YData',curResultSecond100.S)
        set(h100FirstPlot,'XData',curResultFirst100.k,'YData',curResultFirst100.S)


        %--------Prepare resamplings for plotting-----------------

        % Prepare first resampling dataset for plotting
        kResamplingFirst = [];
        sResamplingFirst = [];

        for resamplingIdx=1:nResamplingsFirst
            tempS=curResultsFirst(resamplingIdx);
            tempk=curResultFirst100.k;
            tempk(tempS.S<1e-15)=[];
            tempS.S(tempS.S<1e-15)=[];
            kResamplingFirst = [kResamplingFirst tempk];
            sResamplingFirst = [sResamplingFirst tempS.S];
        end
        

        % Prepare second resampling dataset for plotting
        kResamplingSecond = [];
        sResamplingSecond = [];

        for resamplingIdx=1:nResamplingsSecond
            tempS=curResultsSecond(resamplingIdx);
            tempk=curResultSecond100.k;
            tempk(tempS.S<1e-15)=[];
            tempS.S(tempS.S<1e-15)=[];
            kResamplingSecond = [kResamplingSecond tempk];
            sResamplingSecond = [sResamplingSecond tempS.S];
        end


        % Plot resamplings of both dataset
        set(hResamplingFirst,'XData',kResamplingFirst,'YData',sResamplingFirst)
        set(hResamplingSecond,'XData',kResamplingSecond,'YData',sResamplingSecond)

        %----------Calculate and display average of bleaching numbers "a" of both datasets-----
        bleachingNumsFirst= [curResultsFirst(:).a1];
        hTextBleachingNumFirst.String=['Average bleaching number first dataset = ', num2str(mean(bleachingNumsFirst)) '+-' num2str(std(bleachingNumsFirst)), ' (', name1, ')'];
        bleachingNumsSecond= [curResultsSecond(:).a1];
        hTextBleachingNumSecond.String=['Average bleaching number second dataset = ', num2str(mean(bleachingNumsSecond)) '+-' num2str(std(bleachingNumsSecond)), ' (', name2, ')'];


    end


%%Callbacks for the context menu

    function TypeChangedCB(source,~)
        %User changed between "event spectrum" and "state spectrum"

        %Save selection in the userData structure
        userData.type= source.Label;

        %Update plot
        PlotSpec()
    end


    function AdjustAxisLimitsDialog(~,~)

        % Create the main window
        hOptionsFig = figure(...
            'Name', 'Adjust plot sytle, axis and font Sizes',...
            'NumberTitle', 'off',...
            'MenuBar','None',...
            'Position', [100, 100, 500, 300],...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);


        %Create cell array containing the selectable marker styles
        allMarkerStyles = {'o', '+', '*', 'x', 'square', 'diamond', '^', 'v', '>', '<'};

        %Create cell array containing the selectable colors
        colorNames = {'blue', 'red', 'orange', 'purple', 'green', 'light blue', 'dark red'};

        % Create text and edit fields for X-axis limits
        uicontrol('Style', 'text', 'String', 'X-Axis Min:', 'Position', [20, 250, 80, 20]);
        hXMinEdit = uicontrol('Style', 'edit', 'Position', [100, 250, 80, 20],'Callback',@ValuesChangedCB);

        uicontrol('Style', 'text', 'String', 'X-Axis Max:', 'Position', [200, 250, 80, 20]);
        hXMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 250, 80, 20],'Callback',@ValuesChangedCB);

        % Create text and edit fields for Y-axis limits
        uicontrol('Style', 'text', 'String', 'Y-Axis Min:', 'Position', [20, 220, 80, 20]);
        hYMinEdit = uicontrol('Style', 'edit', 'Position', [100, 220, 80, 20],'Callback',@ValuesChangedCB);

        uicontrol('Style', 'text', 'String', 'Y-Axis Max:', 'Position', [200, 220, 80, 20]);
        hYMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 220, 80, 20],'Callback',@ValuesChangedCB);

        % Create text and edit field for font size
        uicontrol('Style', 'text', 'String', 'Axis Font Size:', 'Position', [20, 190, 100, 20]);
        hAxisFontSizeEdit = uicontrol('Style', 'edit', 'Position', [130, 190, 50, 20],'Callback',@ValuesChangedCB);

        % Create text and edit field for label font size
        uicontrol('Style', 'text', 'String', 'Label Font Size:', 'Position', [200, 190, 100, 20]);
        hLabelFontSizeEdit = uicontrol('Style', 'edit', 'Position', [310, 190, 50, 20],'Callback',@ValuesChangedCB);


        % Checkboxes for showing 100% Data
        hCheckBoxShow100First = uicontrol('Style', 'checkbox', 'String', 'Show 100%  first dataset', 'Position', [30, 160, 200, 20],'Callback',@ValuesChangedCB);
        hCheckBoxShow100Second = uicontrol('Style', 'checkbox', 'String', 'Show 100%  second dataset', 'Position', [30, 130, 200, 20],'Callback',@ValuesChangedCB);

        % Checkboxes for showing Resampling Data
        hCheckBoxShowResamplingFirst = uicontrol('Style', 'checkbox', 'String', 'Show resampling first dataset', 'Position', [230, 160, 200, 20],'Callback',@ValuesChangedCB);
        hCheckBoxShowResamplingSecond = uicontrol('Style', 'checkbox', 'String', 'Show resampling second dataset', 'Position', [230, 130, 200, 20],'Callback',@ValuesChangedCB);

        % Input fields for Markersize, Style and Color of first resampling
        uicontrol('Style', 'text', 'String', 'Marker size and style first resampling:', 'Position', [20, 90, 250, 20],'HorizontalAlignment','left');
        hEditMarkerSizeFirst = uicontrol('Style', 'edit','Position', [240, 90, 50, 20],'Callback',@ValuesChangedCB);
        hPopMarkerFirst = uicontrol('Style', 'popupmenu', 'String', allMarkerStyles, 'Position', [300, 90, 70, 20],'Callback',@ValuesChangedCB);
        hPopColorFirst = uicontrol('Style', 'popupmenu', 'String', colorNames, 'Position', [380, 90, 70, 20],'Callback',@ValuesChangedCB);

        % Input fields for Markersize, Style and Color of second resampling
        uicontrol('Style', 'text', 'String', 'Marker size and style second resampling:', 'Position', [20, 60, 250, 20],'HorizontalAlignment','left');
        hEditMarkerSizeSecond = uicontrol('Style', 'edit', 'Position', [240, 60, 50, 20],'Callback',@ValuesChangedCB);
        hPopMarkerSecond = uicontrol('Style', 'popupmenu', 'String', allMarkerStyles, 'Position', [300, 60, 70, 20],'Callback',@ValuesChangedCB);
        hPopColorSecond = uicontrol('Style', 'popupmenu', 'String', colorNames, 'Position', [380, 60, 70, 20],'Callback',@ValuesChangedCB);


        hCheckboxLegend = uicontrol('Style', 'checkbox', 'String', 'Show legend', 'Position', [20, 30, 100, 20],'Callback',@ValuesChangedCB);

        % Create a button to close the window
        uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [350, 20, 80, 30], 'Callback', @onOK);


        %----------Get current settings------------------------------------------------

        % Get the current axis limits
        currentXLim = xlim(hAx);
        currentYLim = ylim(hAx);

        % Get the current axis font size
        currentAxisFontSize = get(hAx, 'FontSize');

        % Get the current axis label font size
        currentLabelFontSize = get(get(hAx, 'XLabel'), 'FontSize');

        %Get the Marker size and color of both resampling pliots
        currentMarkerSizeFirst = hResamplingFirst.SizeData;
        currentMarkerSizeSecond = hResamplingSecond.SizeData;
        currentColorFirst = hResamplingFirst.MarkerEdgeColor;
        currentColorSecond = hResamplingSecond.MarkerEdgeColor;

        %Get current opacity of resampling plots (1 = visible, 0 = invisible)
        opacityFirstResampling = hResamplingFirst.MarkerEdgeAlpha;
        opacitySecondResampling = hResamplingSecond.MarkerEdgeAlpha == 1;

        %Get current line style of 100% data
        lineStyleFirst = h100FirstPlot.LineStyle;
        lineStyleSecond = h100SecondPlot.LineStyle;

        %Get legend visibility
        legendVisibility = strcmp(hLegend.Visible,'on');


        %---------Fill input fields with current settings-----------------------------

        %Axis limits
        hXMinEdit.String = num2str(currentXLim(1));
        hXMaxEdit.String = num2str(currentXLim(2));
        hYMinEdit.String = num2str(currentYLim(1));
        hYMaxEdit.String = num2str(currentYLim(2));

        %Axis and label font size
        hAxisFontSizeEdit.String = num2str(currentAxisFontSize);
        hLabelFontSizeEdit.String = num2str(currentLabelFontSize);

        %Marker sizes of resamplings
        hEditMarkerSizeFirst.String = currentMarkerSizeFirst;
        hEditMarkerSizeSecond.String = currentMarkerSizeSecond;

        %Visibility of resamplings
        if opacityFirstResampling == 1
            hCheckBoxShowResamplingFirst.Value = 1;
        else
            hCheckBoxShowResamplingFirst.Value = 0;
        end

        if opacitySecondResampling == 1
            hCheckBoxShowResamplingSecond.Value = 1;
        else
            hCheckBoxShowResamplingSecond.Value = 0;
        end


        %Visibility of 100% data
        if strcmp(lineStyleFirst, '-')
            hCheckBoxShow100First.Value = 1;
        elseif strcmp(lineStyleFirst, 'none')
            hCheckBoxShow100First.Value = 0;
        end

        if strcmp(lineStyleSecond, '-')
            hCheckBoxShow100Second.Value = 1;
        elseif strcmp(lineStyleSecond, 'none')
            hCheckBoxShow100Second.Value = 0;
        end


        %Marker style of resamplings
        firstMarkerStyleIdx = find(strcmp(allMarkerStyles, hResamplingFirst.Marker), 1);
        secondMarkerStyleIdx = find(strcmp(allMarkerStyles, hResamplingSecond.Marker), 1);

        if ~isempty(firstMarkerStyleIdx)
            set(hPopMarkerFirst, 'Value', firstMarkerStyleIdx);
        end

        if ~isempty(secondMarkerStyleIdx)
            set(hPopMarkerSecond, 'Value', secondMarkerStyleIdx);
        end


        %Color of resamplings

        %Find current color within the Matlab colors
        matlabColors = lines(7);
        firstColorIdx = find(ismember(matlabColors, currentColorFirst, 'rows'));
        secondColorIdx = find(ismember(matlabColors, currentColorSecond, 'rows'));

        if ~isempty(firstColorIdx)
            set(hPopColorFirst, 'Value', firstColorIdx);
        end

        if ~isempty(secondColorIdx)
            set(hPopColorSecond, 'Value', secondColorIdx);
        end


        %Visibility of the legend

        if legendVisibility
            hCheckboxLegend.Value = 1;
        else
            hCheckboxLegend.Value = 0;
        end


        function ValuesChangedCB(~,~)
            %User changed any input field

            % Get the entered axis limits
            xMin = str2double(get(hXMinEdit, 'String'));
            xMax = str2double(get(hXMaxEdit, 'String'));
            yMin = str2double(get(hYMinEdit, 'String'));
            yMax = str2double(get(hYMaxEdit, 'String'));

            %Set the axis limits
            xlim(hAx,[xMin, xMax]);
            ylim(hAx,[yMin, yMax]);

            %Get the entered axis and label font size
            axisFontSize = str2double(get(hAxisFontSizeEdit, 'String'));
            labelFontSize = str2double(get(hLabelFontSizeEdit, 'String'));

            %Set the axis and label font size
            set(hAx, 'FontSize', axisFontSize);
            set(get(hAx, 'XLabel'), 'FontSize', labelFontSize);
            set(get(hAx, 'YLabel'), 'FontSize', labelFontSize);


            %Set visibility of first resampling
            if hCheckBoxShowResamplingFirst.Value
                %Set opacity to 1 to make marker visible
                hResamplingFirst.MarkerEdgeAlpha = 1;
            else
                %Set opacity to 0 for fully transparent markers
                hResamplingFirst.MarkerEdgeAlpha = 0;
            end

            %Set visibility of second resampling
            if hCheckBoxShowResamplingSecond.Value
                %Set opacity to 1 to make marker visible
                hResamplingSecond.MarkerEdgeAlpha = 1;
            else
                %Set opacity to 0 for fully transparent markers
                hResamplingSecond.MarkerEdgeAlpha = 0;
            end

            %Set visibility of first 100% data
            if hCheckBoxShow100First.Value
                %Set linestyle and marker to anything other than 'none' to make it visible
                h100FirstPlot.LineStyle = '-';
                h100FirstPlot.Marker = 'o';
            else
                %Set linestyle and marker to 'none' to make the plot disappear
                h100FirstPlot.LineStyle = 'None';
                h100FirstPlot.Marker = 'None';
            end

            %Set visibility of first 100% data
            if hCheckBoxShow100Second.Value
                %Set linestyle and marker to anything other than 'none' to make it visible
                h100SecondPlot.LineStyle = '-';
                h100SecondPlot.Marker = 'o';
            else
                %Set linestyle and marker to 'none' to make the plot disappear
                h100SecondPlot.LineStyle = 'None';
                h100SecondPlot.Marker = 'None';
            end


            %Set marker size of resamplings
            hResamplingFirst.SizeData = str2double(hEditMarkerSizeFirst.String);
            hResamplingSecond.SizeData = str2double(hEditMarkerSizeSecond.String);

            %Set marker of resamplings
            hResamplingFirst.Marker = hPopMarkerFirst.String{hPopMarkerFirst.Value};
            hResamplingSecond.Marker = hPopMarkerSecond.String{hPopMarkerSecond.Value};

            %Set color of resampling
            hResamplingFirst.MarkerEdgeColor = matlabColors(hPopColorFirst.Value,:);
            hResamplingSecond.MarkerEdgeColor = matlabColors(hPopColorSecond.Value,:);

            if hCheckboxLegend.Value
                hLegend.Visible = 'on';
            else
                hLegend.Visible = 'off';
            end

        end


        % Function called when the OK button is pressed
        function onOK(~, ~)


            % Close the UI window
            close(hOptionsFig);

        end

        function CloseRequestCB(~,~)

            %Delete figure
            delete(hOptionsFig)
        end

        %User pressed esc key
        function KeyPressFcnCB(~,event)

            if strcmp(event.Key, 'escape')
                CloseRequestCB()
            end

        end


    end

end