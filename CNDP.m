function result = CNDP(base, candidate, target, alpha)
% base: [容量, 停运率]；candidate: [容量, 停运率, 投资]。容量按 1 MW 离散。
base = double(base);
candidate = double(candidate);
target = double(target);
alpha = double(alpha);
total_clock = tic;
M = size(candidate, 1);
capacity = candidate(:, 1);
FOR = candidate(:, 2);
cost = candidate(:, 3);

%% 1. 现有系统容量分布
mu0 = 1;
for k = 1:size(base, 1)
    mu0 = convolve_unit(mu0, base(k, 1), base(k, 2));
end

%% 2. 逐台卷积，计算各配置的可靠性
ERC = zeros(2^M, 1);
LOLP = zeros(2^M, 1);
convolution_count = zeros(M, 1);
convolution_time = zeros(M, 1);
% 行号减 1 的第 i 个二进制位表示第 i 台机组是否安装。
visit(1, mu0, 1);

%% 3. 反向 Bellman 递推
% V{i} 为第 i 台起的最低后续投资，policy{i} 记录是否安装。
V = cell(M+1, 1);
policy = cell(M, 1);
V{M+1} = inf(2^M, 1);
V{M+1}(ERC >= target) = 0;
for i = M:-1:1
    n = 2^(i-1);
    skip = V{i+1}(1:n);
    install = cost(i) + V{i+1}(n+1:end);
    V{i} = min(skip, install);
    policy{i} = install < skip;
end

%% 4. 读取最优安装方案
selection = false(1, M);
path_value = NaN(M, 1);
mu = mu0;
node = 1;
if isfinite(V{1})
    for i = 1:M
        path_value(i) = V{i}(node);
        selection(i) = policy{i}(node);
        if selection(i)
            mu = convolve_unit(mu, capacity(i), FOR(i));
            node = node + 2^(i-1);
        end
    end
end

%% 5. 输出结果
result.feasible = isfinite(V{1});
result.cost = V{1};
result.selection = selection;
if result.feasible
    result.capacity = sum(base(:, 1)) + sum(capacity(selection));
    result.ERC = ERC(node);
    result.LOLP = LOLP(node);
    result.pmf = mu;
else
    result.capacity = NaN;
    result.ERC = NaN;
    result.LOLP = NaN;
    result.pmf = [];
end
result.V = V;
result.policy = policy;
result.path_value = path_value;
result.feasible_count = nnz(ERC >= target);
result.convolutions = sum(convolution_count);
stage = (1:M)';
result.stage = table(stage, convolution_count, cumsum(convolution_count), ...
    stage.*2.^(stage-1), convolution_time, cumsum(convolution_time), ...
    'VariableNames', {'Stage', 'Convolutions', 'CumulativeConvolutions', ...
    'IndependentConvolutions', 'ConvolutionTime', 'CumulativeConvolutionTime'});
result.time = toc(total_clock);

    function visit(i, p, row)
        if i > M
            [LOLP(row), ERC(row)] = reliability(p, target, alpha);
            return;
        end
        visit(i+1, p, row);
        clock = tic;
        next = convolve_unit(p, capacity(i), FOR(i));
        convolution_time(i) = convolution_time(i) + toc(clock);
        convolution_count(i) = convolution_count(i) + 1;
        visit(i+1, next, row+2^(i-1));
    end
end

function next = convolve_unit(p, capacity, FOR)
n = numel(p);
next = zeros(1, n+capacity);
next(1:n) = FOR*p;
next(capacity+(1:n)) = next(capacity+(1:n)) + (1-FOR)*p;
next = next(1:find(next > 0, 1, 'last'));
end

function [LOLP, ERC] = reliability(p, target, alpha)
% 第 k 项表示可用容量严格小于 k-1 MW 的概率。
left = [0, cumsum(p)]/sum(p);
left(end) = 1;
LOLP = left(min(ceil(target), numel(p))+1);
ERC = find(p > 0 & left(1:end-1) <= alpha, 1, 'last')-1;
end
