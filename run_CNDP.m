%% 1. 选择算例
case_id = 'large';                       % 'small' 或 'large'

%% 2. 输入数据
% base: [容量/MW, 停运率]；candidate: [容量/MW, 停运率, 投资]。
% scenarios 每行为 [目标负荷/MW, LOLP限值]，可填写多个工况。
switch case_id
    case 'small'
        cost_unit = '百元';
        scenarios = [1400, 1e-3];
        base = [
              45, 0.018;
              55, 0.032;
              70, 0.045;
              85, 0.027;
              95, 0.055;
             110, 0.038;
             125, 0.062;
             140, 0.021;
             155, 0.047;
             170, 0.074;
        ];
        candidate = [
              50, 0.065, 164;
              50, 0.014, 209;
              75, 0.055, 259;
              75, 0.018, 309;
             105, 0.070, 334;
             105, 0.021, 427;
             130, 0.060, 437;
             130, 0.015, 542;
             165, 0.075, 510;
             165, 0.025, 658;
             195, 0.068, 627;
             195, 0.012, 824;
              80, 0.058, 272;
              80, 0.019, 328;
             115, 0.064, 378;
             115, 0.016, 477;
        ];
    case 'large'
        cost_unit = '千元';
        scenarios = [10000, 1e-3];
        area = [
              20, 0.100;
              20, 0.100;
              76, 0.020;
              76, 0.020;
              20, 0.100;
              20, 0.100;
              76, 0.020;
              76, 0.020;
             100, 0.040;
             100, 0.040;
             100, 0.040;
             197, 0.050;
             197, 0.050;
             197, 0.050;
              12, 0.020;
              12, 0.020;
              12, 0.020;
              12, 0.020;
              12, 0.020;
             155, 0.040;
             155, 0.040;
             400, 0.120;
             400, 0.120;
              50, 0.010;
              50, 0.010;
              50, 0.010;
              50, 0.010;
              50, 0.010;
              50, 0.010;
             155, 0.040;
             155, 0.040;
             350, 0.080;
        ];
        base = repmat(area, 3, 1);
        candidate = [
              50, 0.020,  45;
              75, 0.060,  52;
             100, 0.040,  82;
             125, 0.030, 111;
             150, 0.070,  99;
             175, 0.025, 158;
             200, 0.055, 143;
             225, 0.080, 139;
             250, 0.035, 217;
             275, 0.090, 168;
             300, 0.060, 207;
             350, 0.120, 194;
              80, 0.045,  65;
             160, 0.032, 142;
             240, 0.065, 165;
             320, 0.085, 198;
             180, 0.048, 139;
             210, 0.027, 181;
             260, 0.052, 191;
             340, 0.075, 217;
        ];
end

%% 3. 求解
results = cell(size(scenarios, 1), 1);
summary = zeros(size(scenarios, 1), 8);
selected = strings(size(scenarios, 1), 1);
for k = 1:size(scenarios, 1)
    target = scenarios(k, 1);
    alpha = scenarios(k, 2);
    fprintf('工况 %d：目标 %g MW，alpha = %g\n', k, target, alpha);
    result = CNDP(base, candidate, target, alpha);
    results{k} = result;
    summary(k, :) = [target, alpha, nnz(result.selection), result.capacity, ...
        result.cost, result.ERC, result.LOLP, result.time];
    selected(k) = strjoin(compose('C%02d', find(result.selection)), ', ');
end

%% 4. 查看结果
summary = array2table(summary, 'VariableNames', ...
    {'Load_MW', 'Alpha', 'Units', 'Capacity_MW', 'Cost', 'ERC_MW', 'LOLP', 'Time_s'});
summary.Selected = selected;
fprintf('\n投资单位：%s\n', cost_unit);
disp(summary);
