function savePlot(fig, runDir, name)
    if ~ischar(name) || isempty(regexp(name,'^[A-Za-z0-9_-]+$','once'))
        error('course:FigureName','Invalid figure name.');
    end
    pngPath = fullfile(runDir,[name '.png']);
    figPath = fullfile(runDir,[name '.fig']);
    if exist(pngPath,'file') || exist(figPath,'file')
        error('course:FigureExists','Refusing to overwrite an existing figure.');
    end
    set(fig,'PaperPositionMode','auto','InvertHardcopy','off');
    print(fig,pngPath,'-dpng','-r300');
    saveas(fig,figPath);
end
