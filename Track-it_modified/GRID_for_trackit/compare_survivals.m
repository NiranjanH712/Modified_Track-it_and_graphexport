function []=compare_survivals(tlCurves, fitCurves)

%Create Figure and Save Data
hFigResViewer=figure;

%Create Axes
hAx=gca;


%Context Menu
menuptr = uicontextmenu;
hAx.UIContextMenu=menuptr;

uimenu(hAx.UIContextMenu,'Label','Adjust axis limits and font size','Callback',@AdjustAxisLimitsDialog);


%Draw
PlotSpec();

%%Plotting functions

    function PlotSpec(~,~)



    ylim(hAx,[10^-5 1])
    hold(hAx,'on')
    hAx.XScale='log';
    hAx.YScale='log';
    box(hAx,'on')
    legend(hAx,'toggle')
    xlabel(hAx,'time (s)')
    ylabel(hAx,'survival function')

    nTl = length(tlCurves);

    for tlIdx = 1:nTl
        %Plot
        plot(hAx,tlCurves{tlIdx}(:,1),tlCurves{tlIdx}(:,2),'k')
        plot(hAx,fitCurves{tlIdx}(:,1),fitCurves{tlIdx}(:,2),'r')
    end

    legend(hAx,'Data','Fit')
    end



%%Callbacks for the context menu


    function AdjustAxisLimitsDialog(~,~)

        % Create the main window
        hOptionsFig = figure(...
            'Name', 'Adjust Axis and Font Sizes',...
            'NumberTitle', 'off',...
            'MenuBar','None',...
            'Position', [100, 100, 500, 250],...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        % Get the current axis limits and font sizes
        currentXLim = xlim(hAx);
        currentYLim = ylim(hAx);
        currentAxisFontSize = get(hAx, 'FontSize');
        currentLabelFontSize = get(get(hAx, 'XLabel'), 'FontSize');

        % hLegend = legend(hAx)

        hLegend = findobj(hFigResViewer, 'Type', 'Legend');


        if ~isempty(hLegend) && strcmp(hLegend.Visible, 'on')
            boolLegendVisible = true;
        else
            boolLegendVisible = false;
        end

        % Create input fields for X-axis limits
        uicontrol('Style', 'text', 'String', 'X-Axis Min:', 'Position', [20, 200, 80, 20]);
        hXMinEdit = uicontrol('Style', 'edit', 'Position', [100, 200, 80, 20], 'String', num2str(currentXLim(1)));

        uicontrol('Style', 'text', 'String', 'X-Axis Max:', 'Position', [200, 200, 80, 20]);
        hXMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 200, 80, 20], 'String', num2str(currentXLim(2)));

        % Create input fields for Y-axis limits
        uicontrol('Style', 'text', 'String', 'Y-Axis Min:', 'Position', [20, 150, 80, 20]);
        hYMinEdit = uicontrol('Style', 'edit', 'Position', [100, 150, 80, 20], 'String', num2str(currentYLim(1)));

        uicontrol('Style', 'text', 'String', 'Y-Axis Max:', 'Position', [200, 150, 80, 20]);
        hYMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 150, 80, 20], 'String', num2str(currentYLim(2)));

        % Create input fields for font sizes
        uicontrol('Style', 'text', 'String', 'Axis Font Size:', 'Position', [20, 100, 100, 20]);
        hAxisFontSizeEdit = uicontrol('Style', 'edit', 'Position', [130, 100, 50, 20], 'String', num2str(currentAxisFontSize));

        uicontrol('Style', 'text', 'String', 'Label Font Size:', 'Position', [200, 100, 100, 20]);
        hLabelFontSizeEdit = uicontrol('Style', 'edit', 'Position', [310, 100, 50, 20], 'String', num2str(currentLabelFontSize));

        hCheckboxLegend = uicontrol('Style', 'checkbox', 'String', 'Show legend', 'Value', boolLegendVisible, 'Position', [30, 50, 100, 20]);

        % Create a button to confirm the input
        hButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [350, 20, 80, 30], 'Callback', @onOK);

        % Function called when the OK button is pressed
        function onOK(~, ~)

            % Get the entered axis limits and font sizes
            xMin = str2double(get(hXMinEdit, 'String'));
            xMax = str2double(get(hXMaxEdit, 'String'));
            yMin = str2double(get(hYMinEdit, 'String'));
            yMax = str2double(get(hYMaxEdit, 'String'));

            axisFontSize = str2double(get(hAxisFontSizeEdit, 'String'));
            labelFontSize = str2double(get(hLabelFontSizeEdit, 'String'));

            % Adjust the axis limits and font sizes
            xlim(hAx,[xMin, xMax]);
            ylim(hAx,[yMin, yMax]);
            set(hAx, 'FontSize', axisFontSize);
            set(get(hAx, 'XLabel'), 'FontSize', labelFontSize);
            set(get(hAx, 'YLabel'), 'FontSize', labelFontSize);

            % Get the current legend
            hLegend = legend(hAx);


            % Determine the number of entries in the legend
            numEntries = length(hLegend.String);

            % Show only the last two legend entries
            if numEntries > 2
                set(hLegend, 'String', hLegend.String(1:2));
            end

            if hCheckboxLegend.Value
                hLegend.Visible = 'on';
            else
                hLegend.Visible = 'off';
            end

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