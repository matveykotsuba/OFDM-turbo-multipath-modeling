function [bits, detail] = turbo_decode_reference_manual(llr, numIterations)

if nargin < 2 || isempty(numIterations)
    numIterations = 4;
end
if ~(isnumeric(llr) && isreal(llr) && isvector(llr) && ...
        ~isempty(llr) && all(isfinite(llr(:))))
    error('turbo_decode_manual:InvalidLLR', ...
        'LLR must be a nonempty finite real numeric vector.');
end
if ~(isnumeric(numIterations) && isreal(numIterations) && ...
        isscalar(numIterations) && isfinite(numIterations) && ...
        numIterations >= 1 && numIterations == floor(numIterations))
    error('turbo_decode_manual:InvalidIterations', ...
        'The number of iterations must be a positive integer.');
end
if mod(numel(llr), 3) ~= 0 || numel(llr) <= 12
    error('turbo_decode_manual:InvalidLength', ...
        'LLR length must be 3*(K+4) for a supported LTE block length K.');
end
llr = double(llr(:));
K = numel(llr)/3 - 4;
p = qpp_indices_manual(K);
p = p(:);
d = reshape(llr, K+4, 3);

sys1 = [d(1:K, 1); d(K+1, 1); d(K+1, 3); d(K+2, 2)];
par1 = [d(1:K, 2); d(K+1, 2); d(K+2, 1); d(K+2, 3)];
sys2 = [d(p, 1);   d(K+3, 1); d(K+3, 3); d(K+4, 2)];
par2 = [d(1:K, 3); d(K+3, 2); d(K+4, 1); d(K+4, 3)];

persistent trellis;
if isempty(trellis)
    trellis = make_trellis();
end
prior1 = zeros(K, 1);
for iteration = 1:numIterations
    posterior1 = constituent_decode(sys1, par1, prior1, trellis);
    extrinsic1 = posterior1 - sys1(1:K) - prior1;
    prior2 = extrinsic1(p);
    posterior2 = constituent_decode(sys2, par2, prior2, trellis);
    extrinsic2 = posterior2 - sys2(1:K) - prior2;
    prior1(p) = extrinsic2;
end
posterior = zeros(K, 1);
posterior(p) = posterior2;
bits = double(posterior > 0);
if nargout > 1
    detail = struct('posterior_llr', posterior, ...
        'num_iterations', numIterations, 'algorithm', 'Max-Log-MAP');
end
end

function posterior = constituent_decode(systematic, parity, prior, tr)
K = numel(prior);
T = K + 3;
combined = systematic + [prior; zeros(3, 1)];
gamma = 0.5*(tr.input_sign * combined.' + tr.parity_sign * parity.');
alpha = -inf(8, T+1);
alpha(1, 1) = 0;
for t = 1:T
    scores = alpha(tr.source, t) + gamma(:, t);
    next = max(scores(tr.incoming(:, 1)), scores(tr.incoming(:, 2)));
    alpha(:, t+1) = next - max(next);
end

betaNext = -inf(8, 1);
betaNext(1) = 0;
posterior = zeros(K, 1);
for t = T:-1:1
    backwardScores = gamma(:, t) + betaNext(tr.destination);
    if t <= K
        scores = alpha(tr.source, t) + backwardScores;
        posterior(t) = max(scores(9:16)) - max(scores(1:8));
    end
    beta = max(backwardScores(1:8), backwardScores(9:16));
    betaNext = beta - max(beta);
end
end

function tr = make_trellis()
source = repmat((1:8).', 2, 1);
destination = zeros(16, 1);
inputSign = [-ones(8, 1); ones(8, 1)];
paritySign = zeros(16, 1);
for u = 0:1
    for state = 0:7
        s1 = bitget(state, 3);
        s2 = bitget(state, 2);
        s3 = bitget(state, 1);
        v = xor(u, xor(s2, s3));
        parity = xor(v, xor(s1, s3));
        branch = 8*u + state + 1;
        destination(branch) = 4*double(v) + 2*s1 + s2 + 1;
        paritySign(branch) = 2*double(parity) - 1;
    end
end
incoming = zeros(8, 2);
for stateIndex = 1:8
    incoming(stateIndex, :) = find(destination == stateIndex).';
end
tr = struct('source', source, 'destination', destination, ...
    'input_sign', inputSign, 'parity_sign', paritySign, 'incoming', incoming);
end
