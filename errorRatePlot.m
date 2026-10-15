function fig = errorRatePlot(results, metric, options)
    if nargin < 3 || isempty(options), options = struct(); end
    if ~any(strcmp(metric,{'BER','BLER'})), error('course:Metric','Expected BER or BLER.'); end
    defaults = struct('rows',1:size(results.(metric),1),'title',metric, ...
        'yLimits',[1e-6 1],'hideBelowLimit',false,'zeroDisplay','omit', ...
        'showConfidence',false);
    fields = fieldnames(options);
    for k = 1:numel(fields)
        if ~isfield(defaults,fields{k}), error('course:PlotOption','Unknown plot option %s.',fields{k}); end
        defaults.(fields{k}) = options.(fields{k});
    end
    opt = defaults;
    validateattributes(opt.rows,{'numeric'},{'integer','positive','vector','nonempty','<=',size(results.(metric),1)});
    validateattributes(opt.yLimits,{'numeric'},{'real','finite','positive','numel',2});
    validateattributes(opt.showConfidence,{'logical','numeric'},{'scalar','binary'});
    if opt.yLimits(1) >= opt.yLimits(2), error('course:PlotLimits','yLimits must increase.'); end
    if strcmp(opt.zeroDisplay,'halfCount')
        warning('course:ZeroDisplay','halfCount was removed: zero observations are not a measured positive rate.');
        opt.zeroDisplay = 'omit';
    end
    if ~any(strcmp(opt.zeroDisplay,{'omit','upperBound'})), error('course:PlotOption','Unknown zeroDisplay mode.'); end
    fig = figure('Color','w','Position',[100 100 960 650]);
    ax = axes('Parent',fig,'Position',[0.11 0.16 0.85 0.76]);
    hold(ax,'on'); grid(ax,'on'); box(ax,'on');
    set(ax,'YScale','log','FontSize',12,'LineWidth',1,'GridAlpha',0.2,'MinorGridAlpha',0.12);
    markers = {'o','s','d','^','v','x','p','h'};
    colors = lines(numel(opt.rows)); handles = gobjects(1,numel(opt.rows));
    boundShown = false; displayLabels = results.labels(opt.rows);
    for k = 1:numel(opt.rows)
        row = opt.rows(k);
        if isfield(results,'params') && numel(results.params)>=row && ~isempty(results.params{row})
            par = results.params{row};
            if isfield(par,'coding_enabled') && par.coding_enabled
                label = regexprep(displayLabels{k},', R = [^,]+','');
                displayLabels{k} = sprintf('%s; Rnom=%.3g, Reff=%.3g', ...
                    label,par.code_rate_nominal,par.actual_code_rate_cb);
            end
        end
    end
    for k = 1:numel(opt.rows)
        row = opt.rows(k);
        curve = results.(metric)(row,:);
        curve(curve <= 0) = NaN;
        if opt.showConfidence && isfield(results,[metric 'Lower95'])
            low = results.([metric 'Lower95'])(row,:);
            high = results.([metric 'Upper95'])(row,:);
            low = max(low,opt.yLimits(1)/10);
            errorbar(ax,results.snrDb,curve,max(0,curve-low),max(0,high-curve), ...
                'LineStyle','none','Color',colors(k,:),'HandleVisibility','off');
        end
        handles(k) = plot(ax,results.snrDb,curve,'LineStyle','-', ...
            'Marker',markers{mod(k-1,numel(markers))+1},'Color',colors(k,:), ...
            'LineWidth',1.7,'MarkerSize',5,'DisplayName',displayLabels{k});
        if strcmp(opt.zeroDisplay,'upperBound') && isfield(results,[metric 'ZeroUpper95'])
            upper = results.([metric 'ZeroUpper95'])(row,:);
            valid = results.(metric)(row,:) == 0 & isfinite(upper);
            plot(ax,results.snrDb(valid),upper(valid),'v','Color',colors(k,:), ...
                'LineStyle','none','HandleVisibility','off');
            boundShown = boundShown || any(valid);
        end
    end
    xlabel(ax,'SNR = E_s/N_0, dB'); ylabel(ax,metric); title(ax,opt.title,'Interpreter','none');
    legend(ax,handles,displayLabels,'Location','southwest');
    ylim(ax,opt.yLimits);
    if numel(results.snrDb)>1 && min(results.snrDb)<max(results.snrDb)
        xlim(ax,[min(results.snrDb) max(results.snrDb)]);
    end
    counts = results.totalPackets(opt.rows,:); counts = counts(isfinite(counts));
    if isempty(counts), countText = 'Incomplete run';
    elseif min(counts)==max(counts), countText = sprintf('N = %d independent blocks/point',min(counts));
    else, countText = sprintf('N = %d...%d independent blocks/point',min(counts),max(counts)); end
    if ~isempty(counts) && min(counts)<500, countText = ['PREVIEW: ' countText]; end
    values = results.(metric)(opt.rows,:);
    if any(values(:)==0)
        if boundShown, note = 'v: 95% upper bound (independent blocks), not measured rate';
        else, note = 'Zero-error points omitted; zero observed errors do not prove zero error probability'; end
    else, note = 'Measured Monte Carlo points; no curve smoothing'; end
    if opt.showConfidence, note = [note '; pointwise 95% intervals']; end
    annotation(fig,'textbox',[0.03 0.012 0.94 0.075], ...
        'String',{countText,note},'EdgeColor','none','HorizontalAlignment','center', ...
        'FontSize',9,'Interpreter','none');
end
