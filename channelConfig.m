function cfg = channelConfig(overrides)
    cfg=struct('type','tdl','profile','TDL-A','delaySpreadNs',380,'snrDb',20);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    if ~ischar(cfg.type)||~ismember(lower(cfg.type),{'awgn','tdl'}),error('project:Channel','type must be awgn or tdl.');end
    cfg.type=lower(cfg.type);
    if ~ischar(cfg.profile)||~ismember(upper(cfg.profile),{'TDL-A','TDL-B','TDL-C'}),error('project:Channel','Unknown TDL profile.');end
    cfg.profile=upper(cfg.profile);
    validateattributes(cfg.delaySpreadNs,{'numeric'},{'scalar','real','nonnegative','finite'});
    validateattributes(cfg.snrDb,{'numeric'},{'scalar','real','finite'});
end
