function [cfg, codingOptions] = legacyExperimentConfig(codingOptions)
    if nargin < 1, codingOptions = []; end
    codingOptions = coding_config(codingOptions);
    cfg = config(struct('coding',struct('enabled',codingOptions.enabled,'backend',codingOptions.backend, ...
        'turboNumIter',codingOptions.turbo_num_iter)));
end
