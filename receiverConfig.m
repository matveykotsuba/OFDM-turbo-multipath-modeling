function cfg = receiverConfig(overrides)
    cfg=struct('equalizerEnabled',true);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    validateattributes(cfg.equalizerEnabled,{'logical','numeric'},{'scalar','real','finite','binary'});
    cfg.equalizerEnabled=logical(cfg.equalizerEnabled);
end
