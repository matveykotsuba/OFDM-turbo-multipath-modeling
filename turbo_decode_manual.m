function [bits, detail] = turbo_decode_manual(llr, numIterations)

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

prior1 = zeros(K, 1);
for iteration = 1:numIterations
    posterior1 = constituent_decode(sys1, par1, prior1);
    extrinsic1 = posterior1 - sys1(1:K) - prior1;
    prior2 = extrinsic1(p);
    posterior2 = constituent_decode(sys2, par2, prior2);
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

function posterior = constituent_decode(systematic, parity, prior)
K = numel(prior);
T = K + 3;
combined = systematic + [prior; zeros(3, 1)];
g00 = 0.5*(-combined - parity);
g01 = 0.5*(-combined + parity);
g10 = 0.5*( combined - parity);
g11 = 0.5*( combined + parity);
alpha = -inf(8, T+1);
alpha(1, 1) = 0;
for t = 1:T
    a1 = max(alpha(1, t) + g00(t), alpha(2, t) + g11(t));
    a2 = max(alpha(4, t) + g01(t), alpha(3, t) + g10(t));
    a3 = max(alpha(5, t) + g01(t), alpha(6, t) + g10(t));
    a4 = max(alpha(8, t) + g00(t), alpha(7, t) + g11(t));
    a5 = max(alpha(2, t) + g00(t), alpha(1, t) + g11(t));
    a6 = max(alpha(3, t) + g01(t), alpha(4, t) + g10(t));
    a7 = max(alpha(6, t) + g01(t), alpha(5, t) + g10(t));
    a8 = max(alpha(7, t) + g00(t), alpha(8, t) + g11(t));
    normValue = max(max(max(a1, a2), max(a3, a4)), max(max(a5, a6), max(a7, a8)));
    alpha(1, t+1) = a1 - normValue;
    alpha(2, t+1) = a2 - normValue;
    alpha(3, t+1) = a3 - normValue;
    alpha(4, t+1) = a4 - normValue;
    alpha(5, t+1) = a5 - normValue;
    alpha(6, t+1) = a6 - normValue;
    alpha(7, t+1) = a7 - normValue;
    alpha(8, t+1) = a8 - normValue;
end
b1 = 0;
b2 = -inf;
b3 = -inf;
b4 = -inf;
b5 = -inf;
b6 = -inf;
b7 = -inf;
b8 = -inf;
posterior = zeros(K, 1);
for t = T:-1:1
    z1 = g00(t) + b1;
    z2 = g00(t) + b5;
    z3 = g01(t) + b6;
    z4 = g01(t) + b2;
    z5 = g01(t) + b3;
    z6 = g01(t) + b7;
    z7 = g00(t) + b8;
    z8 = g00(t) + b4;
    z9 = g11(t) + b5;
    z10 = g11(t) + b1;
    z11 = g10(t) + b2;
    z12 = g10(t) + b6;
    z13 = g10(t) + b7;
    z14 = g10(t) + b3;
    z15 = g11(t) + b4;
    z16 = g11(t) + b8;
    if t <= K
        m1 = alpha(1, t) + z1;
        m2 = alpha(2, t) + z2;
        m3 = alpha(3, t) + z3;
        m4 = alpha(4, t) + z4;
        m5 = alpha(5, t) + z5;
        m6 = alpha(6, t) + z6;
        m7 = alpha(7, t) + z7;
        m8 = alpha(8, t) + z8;
        m9 = alpha(1, t) + z9;
        m10 = alpha(2, t) + z10;
        m11 = alpha(3, t) + z11;
        m12 = alpha(4, t) + z12;
        m13 = alpha(5, t) + z13;
        m14 = alpha(6, t) + z14;
        m15 = alpha(7, t) + z15;
        m16 = alpha(8, t) + z16;
        posterior(t) = max(max(max(m9, m10), max(m11, m12)), max(max(m13, m14), max(m15, m16))) - max(max(max(m1, m2), max(m3, m4)), max(max(m5, m6), max(m7, m8)));
    end
    b1 = max(z1, z9);
    b2 = max(z2, z10);
    b3 = max(z3, z11);
    b4 = max(z4, z12);
    b5 = max(z5, z13);
    b6 = max(z6, z14);
    b7 = max(z7, z15);
    b8 = max(z8, z16);
    normValue = max(max(max(b1, b2), max(b3, b4)), max(max(b5, b6), max(b7, b8)));
    b1 = b1 - normValue;
    b2 = b2 - normValue;
    b3 = b3 - normValue;
    b4 = b4 - normValue;
    b5 = b5 - normValue;
    b6 = b6 - normValue;
    b7 = b7 - normValue;
    b8 = b8 - normValue;
end
end
