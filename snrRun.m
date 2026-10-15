function results = snrRun(cfg)
    if nargin < 1, cfg = []; end
    cfg = config(cfg);
    mods = cfg.experiment.modulations;
    cases = repmat(struct('label','','cfg',cfg),1,numel(mods));
    for k = 1:numel(mods)
        cases(k).label = mods{k};
        cases(k).cfg.modulation = mods{k};
    end
    if strcmpi(cfg.channel.type,'awgn'), snr = cfg.experiment.snrAwgnDb;
    else, snr = cfg.experiment.snrTdlDb; end
    results = experimentRun(cfg,cases,snr);
    results.kind = 'snr';
end
